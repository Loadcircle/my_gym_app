// functions/src/retrieval/exerciseCatalog.ts
import * as admin from "firebase-admin";
import { buildNameTokens } from "../utils/normalize";

export type MuscleGroup = {
  id: string;        // doc id, ej: "arms"
  name?: string;     // "Brazos"
  nameEn?: string;   // "Arms"
  isActive?: boolean;
};

export type ExerciseCandidate = {
  id: string; // docID
  name: string;
  muscleGroup: string;
  description?: string;
  nameNormalized?: string;
  nameTokens?: string[];
};

export async function getActiveMuscleGroupIds(db: admin.firestore.Firestore): Promise<string[]> {
  const snap = await db.collection("muscle_groups").where("isActive", "==", true).get();
  return snap.docs.map((d) => d.id);
}

/**
 * Trae candidatos similares para dedupe sin saturar tokens.
 * Requiere que en /exercises exista (idealmente) nameTokens: string[]
 * (Los nuevos globales ya lo tendrán; los antiguos puedes backfillear luego)
 */
export async function findExerciseCandidates(
  db: admin.firestore.Firestore,
  customName: string,
  limit = 20
): Promise<ExerciseCandidate[]> {
  const tokens = buildNameTokens(customName).slice(0, 10); // Firestore array-contains-any max 10

  if (tokens.length === 0) return [];

  const q = db
    .collection("exercises")
    .where("nameTokens", "array-contains-any", tokens)
    .limit(limit);

  const snap = await q.get();

  // Si no hay resultados, igual devolvemos vacío (LLM decide sin candidatos)
  return snap.docs.map((d) => {
    const data = d.data() || {};
    return {
      id: d.id,
      name: String(data.name || ""),
      muscleGroup: String(data.muscleGroup || ""),
      description: data.description ? String(data.description) : undefined,
      nameNormalized: data.nameNormalized ? String(data.nameNormalized) : undefined,
      nameTokens: Array.isArray(data.nameTokens) ? data.nameTokens.map(String) : undefined,
    };
  }).filter((c) => c.name && c.muscleGroup);
}
