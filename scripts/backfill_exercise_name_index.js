/**
 * Script para poblar nameNormalized y nameTokens en Firestore
 * basado en el campo "name" del ejercicio global.
 *
 * Reglas:
 * - Por defecto actualiza TODOS los docs de la colección "exercises"
 * - Solo llena campos que estén vacíos (null/undefined/"" o array vacío)
 * - Si recibe un parámetro (JSON array de IDs), SOLO actualiza esos docIDs
 *
 * Logs:
 * - UPDATED: docId + campos actualizados
 * - SKIPPED: docId (ya estaba lleno / o no se puede generar)
 * - NOT FOUND: docId (si usas filtro)
 *
 * Uso:
 *   node backfill_exercise_name_index.js
 *   node backfill_exercise_name_index.js '["cable_crunch_machine","bench_press"]'
 */

const admin = require("firebase-admin");

const path = require("path");

const env = process.env.ENV || "dev"; // dev por defecto

const keyPath = path.join(__dirname, `serviceAccountKey.${env}.json`);
const serviceAccount = require(keyPath);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

const COLLECTION = "exercises";
const BATCH_LIMIT = 450; // max 500 ops/batch, margen seguro

function isBlank(value) {
  return value === null || value === undefined || (typeof value === "string" && value.trim() === "");
}

function isBlankArray(value) {
  return value === null || value === undefined || !Array.isArray(value) || value.length === 0;
}

/**
 * Normaliza texto:
 * - minusculas
 * - sin tildes/diacriticos
 * - ñ -> n
 * - solo letras/numeros/espacios
 * - espacios colapsados
 */
function normalizeText(input) {
  return String(input || "")
    .toLowerCase()
    .trim()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/ñ/g, "n")
    .replace(/[^a-z0-9\s]+/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

/**
 * Tokens a partir de nameNormalized:
 * - split por espacios
 * - filtra tokens < 3
 * - remueve stopwords simples
 * - dedupe
 * - max 12
 */
function buildNameTokens(name) {
  const norm = normalizeText(name);
  if (!norm) return [];

  const stop = new Set(["de", "del", "la", "el", "y", "con", "en", "a", "por", "para"]);
  const rawTokens = norm.split(" ").filter(Boolean);

  const tokens = rawTokens
    .filter((t) => t.length >= 3)
    .filter((t) => !stop.has(t));

  // dedupe manteniendo orden
  const seen = new Set();
  const unique = [];
  for (const t of tokens) {
    if (!seen.has(t)) {
      seen.add(t);
      unique.push(t);
    }
    if (unique.length >= 12) break;
  }

  return unique;
}

function parseIdsArg(argv) {
  const raw = argv[2];
  if (!raw) return null;

  let parsed;
  try {
    parsed = JSON.parse(raw);
  } catch {
    throw new Error(
      `El argumento debe ser un JSON array válido. Ej: '["id1","id2"]'. Recibido: ${raw}`
    );
  }

  if (!Array.isArray(parsed)) {
    throw new Error(`El argumento debe ser un ARRAY JSON. Tipo recibido: ${typeof parsed}`);
  }

  return parsed
    .map((x) => (typeof x === "string" ? x.trim() : ""))
    .filter((x) => x.length > 0);
}

async function fetchTargets(idsFilter) {
  const col = db.collection(COLLECTION);

  if (idsFilter !== null) {
    const refs = idsFilter.map((id) => col.doc(id));
    const snaps = await db.getAll(...refs);
    return snaps; // incluye exists=false
  }

  const snapshot = await col.get();
  return snapshot.docs;
}

function logUpdated(docId, updatePayload) {
  const fields = Object.keys(updatePayload);
  console.log(`✅ UPDATED  ${docId}  ->  [${fields.join(", ")}]`);
}

function logSkipped(docId, reason) {
  const extra = reason ? ` (${reason})` : "";
  console.log(`⏭️  SKIPPED  ${docId}${extra}`);
}

function logNotFound(docId) {
  console.log(`⚠️  NOT FOUND  ${docId}`);
}

async function main() {
  console.log("Starting backfill_exercise_name_index...\n");
  console.log("Project ID:", serviceAccount.project_id);
  console.log("Collection:", COLLECTION);

  const idsFilter = parseIdsArg(process.argv);
  if (idsFilter !== null) {
    console.log("IDs filter provided:", idsFilter);
  } else {
    console.log("No IDs filter provided -> will scan ALL exercises.");
  }
  console.log("");

  const docsOrSnaps = await fetchTargets(idsFilter);

  if (docsOrSnaps.length === 0) {
    console.log("No documents found to process.");
    process.exit(0);
  }

  let batch = db.batch();
  let opsInBatch = 0;

  let processed = 0;
  let updatedDocs = 0;
  let skippedDocs = 0;
  let notFoundDocs = 0;

  const updatedIds = [];

  for (const item of docsOrSnaps) {
    processed++;

    // Modo filtro: puede venir exists=false
    if (idsFilter !== null && item.exists === false) {
      notFoundDocs++;
      logNotFound(item.id);
      continue;
    }

    const docSnap = item;
    const docId = docSnap.id;
    const data = docSnap.data() || {};

    const name = String(data.name || "").trim();
    if (!name) {
      skippedDocs++;
      logSkipped(docId, "no name");
      continue;
    }

    const updatePayload = {};

    // Solo llenamos si está vacío (igual que tu script)
    if (isBlank(data.nameNormalized)) {
      updatePayload.nameNormalized = normalizeText(name);
    }

    if (isBlankArray(data.nameTokens)) {
      updatePayload.nameTokens = buildNameTokens(name);
    }

    // Si no hay nada que actualizar
    if (Object.keys(updatePayload).length === 0) {
      skippedDocs++;
      logSkipped(docId, "already filled");
      continue;
    }

    // Validación mínima: no guardes tokens vacíos si no hay nada útil
    if ("nameTokens" in updatePayload && updatePayload.nameTokens.length === 0) {
      // si solo queríamos nameTokens y quedó vacío, no actualizamos ese campo
      delete updatePayload.nameTokens;
    }

    if (Object.keys(updatePayload).length === 0) {
      skippedDocs++;
      logSkipped(docId, "tokens empty");
      continue;
    }

    batch.update(docSnap.ref, updatePayload);
    opsInBatch++;
    updatedDocs++;
    updatedIds.push(docId);

    logUpdated(docId, updatePayload);

    if (opsInBatch >= BATCH_LIMIT) {
      console.log(`\n📦 Committing batch (${opsInBatch} ops)...\n`);
      await batch.commit();
      batch = db.batch();
      opsInBatch = 0;
    }
  }

  if (opsInBatch > 0) {
    console.log(`\n📦 Committing final batch (${opsInBatch} ops)...\n`);
    await batch.commit();
  }

  console.log("\n====================");
  console.log("✅ DONE");
  console.log("====================\n");

  console.log("Summary:");
  console.log("  Processed docs:", processed);
  console.log("  Updated docs:", updatedDocs);
  console.log("  Skipped docs:", skippedDocs);
  if (idsFilter !== null) console.log("  Not found docs:", notFoundDocs);

  if (updatedIds.length > 0) {
    console.log("\nUpdated docIDs:");
    updatedIds.forEach((id) => console.log("  -", id));
  } else {
    console.log("\nNo docs were updated (everything already filled).");
  }

  process.exit(0);
}

main().catch((err) => {
  console.error("Error:", err);
  process.exit(1);
});
