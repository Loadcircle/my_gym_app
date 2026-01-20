// functions/src/index.ts
import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

import { reviewCustomExerciseWithLLM } from "../../llm/exerciseReviewer";
import { getActiveMuscleGroupIds, findExerciseCandidates } from "../../retrieval/exerciseCatalog";
import { validateReviewResult } from "../../utils/guardrails";
import { buildNameTokens, normalizeText, slugifyId } from "../../utils/normalize";
import { createInAppNotification } from "../../services/notifications";

admin.initializeApp();
const db = admin.firestore();

export const submitCustomExerciseForGlobal = functions.https.onCall(async (data, context) => {
  if (!context.auth?.uid) {
    throw new functions.https.HttpsError("unauthenticated", "Debes iniciar sesión.");
  }

  const uid = context.auth.uid;
  const customId = String(data?.customId || "").trim();
  if (!customId) {
    throw new functions.https.HttpsError("invalid-argument", "customId es requerido.");
  }

  const customRef = db.doc(`users/${uid}/customExercises/${customId}`);
  console.log("[submitCustomExerciseForGlobal] START", { uid, customId });

  const customSnap = await customRef.get();
  if (!customSnap.exists) {
    throw new functions.https.HttpsError("not-found", "El ejercicio custom no existe.");
  }

  const customData = customSnap.data() || {};
  const status = String(customData.proposalStatus || "none");

  // Solo una solicitud
  if (status !== "none") {
    console.log("[submitCustomExerciseForGlobal] ALREADY", { uid, customId, status });
    return { ok: true, alreadySubmitted: true, status };
  }

  // pasa a processing
  await customRef.update({
    proposalStatus: "processing",
    proposalSubmittedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // retrieval: muscle groups activos + candidates dedupe
  const activeMuscleGroupIds = await getActiveMuscleGroupIds(db);
  const candidates = await findExerciseCandidates(db, String(customData.name || ""), 20);

  // LLM
  const llmResult = await reviewCustomExerciseWithLLM({
    custom: customData,
    candidates: candidates.map((c) => ({
      id: c.id,
      name: c.name,
      muscleGroup: c.muscleGroup,
      description: c.description,
    })),
    activeMuscleGroupIds,
  });

  // guardrails
  const guard = validateReviewResult(llmResult, activeMuscleGroupIds);
  if (!guard.ok) {
    await customRef.update({
      proposalStatus: "rejected",
      proposalResolvedAt: admin.firestore.FieldValue.serverTimestamp(),
      proposalResult: { decision: "reject", reason: guard.reason },
    });

    await createInAppNotification({
      db,
      uid,
      type: "exercise_global_rejected",
      title: "Tu ejercicio fue rechazado",
      body: `Motivo: ${guard.reason}`,
      customId,
    });

    console.log("[submitCustomExerciseForGlobal] GUARDRAIL_REJECT", { uid, customId, reason: guard.reason });
    return { ok: true, decision: "reject", reason: guard.reason };
  }

  // guardrail extra: si el LLM dice duplicate, debe venir duplicateOfId
  if (llmResult.isDuplicate && !llmResult.duplicateOfId) {
    await customRef.update({
      proposalStatus: "rejected",
      proposalResolvedAt: admin.firestore.FieldValue.serverTimestamp(),
      proposalResult: {
        decision: "reject",
        reason: "LLM indicó duplicado pero no devolvió duplicateOfId.",
      },
    });

    await createInAppNotification({
      db,
      uid,
      type: "exercise_global_rejected",
      title: "Tu ejercicio fue rechazado",
      body: "No se pudo validar el ejercicio correctamente. Intenta más tarde.",
      customId,
    });

    console.log("[submitCustomExerciseForGlobal] DUPLICATE_INVALID", {
      uid,
      customId,
    });

    return { ok: true, decision: "reject", reason: "duplicateOfId faltante" };
  }


  // caso duplicate: no se crea global nuevo
  if (llmResult.isDuplicate && llmResult.duplicateOfId) {
    const existingGlobalId = llmResult.duplicateOfId;

    await customRef.update({
      proposalStatus: "published",
      proposalResolvedAt: admin.firestore.FieldValue.serverTimestamp(),
      proposalResult: { decision: "reject", reason: llmResult.reason, duplicateOfId: existingGlobalId },
      publishedGlobalId: existingGlobalId,
      isDuplicateOfGlobal: true,
    });

    await createInAppNotification({
      db,
      uid,
      type: "exercise_global_duplicate",
      title: "Ese ejercicio ya existe en el catálogo",
      body: `Ya existe una versión global. Puedes cambiarte al ejercicio global.`,
      customId,
      globalId: existingGlobalId,
    });

    console.log("[submitCustomExerciseForGlobal] DUPLICATE", { uid, customId, existingGlobalId });
    return { ok: true, decision: "duplicate", globalId: existingGlobalId };
  }

  // reject normal
  if (llmResult.decision === "reject") {
    await customRef.update({
      proposalStatus: "rejected",
      proposalResolvedAt: admin.firestore.FieldValue.serverTimestamp(),
      proposalResult: { decision: "reject", reason: llmResult.reason },
    });

    await createInAppNotification({
      db,
      uid,
      type: "exercise_global_rejected",
      title: "Tu ejercicio fue rechazado",
      body: `Motivo: ${llmResult.reason}`,
      customId,
    });

    console.log("[submitCustomExerciseForGlobal] REJECT", { uid, customId, reason: llmResult.reason });
    return { ok: true, decision: "reject", reason: llmResult.reason };
  }

  // approve: crear global
  const draft = llmResult.globalDraft!;
  const baseSlug = slugifyId(draft.name);
  const globalId = `${baseSlug}_${customId}`.slice(0, 60);

  const globalRef = db.doc(`exercises/${globalId}`);

  const nameNormalized = normalizeText(draft.name);
  const nameTokens = buildNameTokens(draft.name);

  await globalRef.set({
    // Core
    name: draft.name,
    muscleGroup: draft.muscleGroup,
    description: draft.description,
    instructions: draft.instructions,
    imageUrl: draft.imageUrl,
    videoUrl: draft.videoUrl,
    order: 9999,

    // Derivados para búsqueda/dedupe
    nameNormalized,
    nameTokens,

    // Auditoría
    autoCreated: true,
    sourceCustomId: customId,
    sourceUserId: uid,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  await customRef.update({
    proposalStatus: "published",
    proposalResolvedAt: admin.firestore.FieldValue.serverTimestamp(),
    proposalResult: { decision: "approve", globalId },
    publishedGlobalId: globalId,
    isDuplicateOfGlobal: false,
  });

  await createInAppNotification({
    db,
    uid,
    type: "exercise_global_approved",
    title: "Tu ejercicio fue publicado",
    body: `Ahora existe en el catálogo global como "${draft.name}"`,
    customId,
    globalId,
  });

  console.log("[submitCustomExerciseForGlobal] APPROVED", { uid, customId, globalId });
  return { ok: true, decision: "approve", globalId };
});