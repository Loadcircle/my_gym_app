// functions/src/utils/guardrails.ts
import { ExerciseReviewResult } from "../llm/exerciseReviewer";

export type GuardrailFail = { ok: false; reason: string };
export type GuardrailOk = { ok: true };

export function validateReviewResult(
  result: ExerciseReviewResult,
  activeMuscleGroupIds: string[]
): GuardrailOk | GuardrailFail {
  if (!result || (result.decision !== "approve" && result.decision !== "reject")) {
    return { ok: false, reason: "LLM: decision inválida." };
  }

  if (!result.reason || result.reason.trim().length < 3) {
    return { ok: false, reason: "LLM: reason vacío." };
  }

  if (result.decision === "reject") {
    return { ok: true };
  }

  const draft = result.globalDraft;
  if (!draft) return { ok: false, reason: "LLM: approve sin globalDraft." };

  const name = (draft.name || "").trim();
  if (name.length < 4 || name.length > 70) {
    return { ok: false, reason: "Guardrail: nombre fuera de rango." };
  }

  const mg = (draft.muscleGroup || "").trim();
  if (!mg || !activeMuscleGroupIds.includes(mg)) {
    return { ok: false, reason: "Guardrail: muscleGroup no permitido o inactivo." };
  }

  const instr = (draft.instructions || "").trim();
  const lines = instr.split("\n").map((l) => l.trim()).filter(Boolean);

  // mínimo 4 pasos y formato "1. ..."
  if (lines.length < 4) {
    return { ok: false, reason: "Guardrail: instructions debe tener mínimo 4 pasos." };
  }

  const bad = lines.some((l) => !/^\d+\.\s+/.test(l));
  if (bad) {
    return { ok: false, reason: "Guardrail: instructions debe estar numerado tipo '1. ...'." };
  }

  return { ok: true };
}