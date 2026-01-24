/**
 * Script para poblar imageUrl, videoUrl y storagePath en Firestore
 * basado en el DOC ID del ejercicio.
 *
 * Reglas:
 * - Por defecto actualiza TODOS los docs de la colección "exercises"
 * - Solo llena campos que estén vacíos (null/undefined/"")
 * - Si recibe un parámetro (JSON array de IDs), SOLO actualiza esos docIDs
 *
 * Logs:
 * - UPDATED: docId + campos actualizados
 * - SKIPPED: docId (ya estaba lleno)
 * - NOT FOUND: docId (si usas filtro)
 *
 * Uso:
 *   node fill_exercise_media_fields.js
 *   node fill_exercise_media_fields.js '["cable_crunch_machine","bench_press"]'
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
const BATCH_LIMIT = 450; // max 500 ops/batch, usamos margen

function isBlank(value) {
  return value === null || value === undefined || (typeof value === "string" && value.trim() === "");
}

function buildPaths(docId) {
  const base = `exercises/${docId}`;
  return {
    storagePath: base,
    imageUrl: `${base}/${docId}.jpg`,
    videoUrl: `${base}/${docId}.mp4`,
  };
}

function parseIdsArg(argv) {
  const raw = argv[2];
  if (!raw) return null;

  let parsed;
  try {
    parsed = JSON.parse(raw);
  } catch {
    throw new Error(`El argumento debe ser un JSON array válido. Ej: '["id1","id2"]'. Recibido: ${raw}`);
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

  // Si hay filtro: getAll por refs (no da NOT FOUND acá, eso lo manejamos aparte)
  if (idsFilter !== null) {
    const refs = idsFilter.map((id) => col.doc(id));
    const snaps = await db.getAll(...refs);
    return snaps; // devolvemos TODOS (exists o no) para log NOT FOUND
  }

  // Si no hay filtro: full scan
  const snapshot = await col.get();
  return snapshot.docs;
}

function logUpdated(docId, updatePayload) {
  const fields = Object.keys(updatePayload);
  console.log(`✅ UPDATED  ${docId}  ->  [${fields.join(", ")}]`);
}

function logSkipped(docId) {
  console.log(`⏭️  SKIPPED  ${docId}  (already filled)`);
}

function logNotFound(docId) {
  console.log(`⚠️  NOT FOUND  ${docId}`);
}

async function main() {
  console.log("Starting fill_exercise_media_fields...\n");
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

    // En modo filtro: item puede ser DocumentSnapshot exists=false
    if (idsFilter !== null && item.exists === false) {
      notFoundDocs++;
      logNotFound(item.id);
      continue;
    }

    // En modo full scan: item es docSnap normal
    const docSnap = item;
    const docId = docSnap.id;
    const data = docSnap.data() || {};

    const { storagePath, imageUrl, videoUrl } = buildPaths(docId);

    const updatePayload = {};
    if (isBlank(data.storagePath)) updatePayload.storagePath = storagePath;
    if (isBlank(data.imageUrl)) updatePayload.imageUrl = imageUrl;
    if (isBlank(data.videoUrl)) updatePayload.videoUrl = videoUrl;

    if (Object.keys(updatePayload).length === 0) {
      skippedDocs++;
      logSkipped(docId);
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
