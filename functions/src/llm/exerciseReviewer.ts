// functions/src/llm/exerciseReviewer.ts
import OpenAI from "openai";

export type ReviewDecision = "approve" | "reject";

export type ExerciseGlobalDraft = {
  name: string;
  muscleGroup: string;
  description: string;
  instructions: string;
  imageUrl: string | null;
  videoUrl: string | null;
};

export type ExerciseReviewResult = {
  decision: ReviewDecision;
  reason: string;

  // dedupe
  isDuplicate: boolean;
  duplicateOfId: string | null;

  // si approve y no es duplicate
  globalDraft: ExerciseGlobalDraft | null;
};

export type CandidateCompact = {
  id: string;
  name: string;
  muscleGroup: string;
  description?: string;
};

const client = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

const OUTPUT_SCHEMA = {
  name: "exercise_review_result",
  schema: {
    type: "object",
    additionalProperties: false,
    properties: {
      decision: { type: "string", enum: ["approve", "reject"] },
      reason: { type: "string" },

      isDuplicate: { type: "boolean" },
      duplicateOfId: { type: ["string", "null"] },

      globalDraft: {
        type: ["object", "null"],
        additionalProperties: false,
        properties: {
          name: { type: "string" },
          muscleGroup: { type: "string" },
          description: { type: "string" },
          instructions: { type: "string" },
          imageUrl: { type: ["string", "null"] },
          videoUrl: { type: ["string", "null"] },
        },
        required: ["name", "muscleGroup", "description", "instructions", "imageUrl", "videoUrl"],
      },
    },
    required: ["decision", "reason", "isDuplicate", "duplicateOfId", "globalDraft"],
  },
};

function candidatesToText(candidates: CandidateCompact[]): string {
  if (!candidates.length) return "CANDIDATES: (none)\n";

  const lines = candidates.slice(0, 25).map((c) => {
    const desc = c.description ? ` | ${c.description}` : "";
    return `- ${c.id} | ${c.name} | ${c.muscleGroup}${desc}`;
  });

  return `CANDIDATES (posibles duplicados):\n${lines.join("\n")}\n`;
}

function buildPrompt(params: {
  custom: any;
  candidates: CandidateCompact[];
  activeMuscleGroupIds: string[];
}) {
  const { custom, candidates, activeMuscleGroupIds } = params;

  const name = String(custom?.name || "").trim();
  const muscleGroup = String(custom?.muscleGroup || "").trim();
  const notes = String(custom?.notes || custom?.instructions || "").trim();
  const description = String(custom?.description || "").trim();

  return `
Eres un revisor profesional de un catálogo global de ejercicios de gimnasio.

OBJETIVO:
1) Determinar si el ejercicio custom puede ser un ejercicio global.
2) Detectar si YA EXISTE en el catálogo global con otro nombre (dedupe).

REGLAS:
- Responde SOLO con JSON válido según el schema (sin texto extra).
- muscleGroup DEBE ser uno de estos ids activos:
  ${activeMuscleGroupIds.join(", ")}

DEDUPE:
- Si el ejercicio es esencialmente el mismo que uno de los CANDIDATES, entonces:
  - isDuplicate = true
  - duplicateOfId = el id del candidato
  - decision = "reject" (porque no se crea uno nuevo)
  - globalDraft = null
- Si NO es duplicate:
  - isDuplicate = false
  - duplicateOfId = null
  - si es buen global => decision "approve" y globalDraft completo
  - si no => decision "reject" y globalDraft null

CRITERIOS PARA APPROVE:
- Nombre claro y estandarizado (sin jerga rara).
- Grupo muscular coherente.
- Description corta (1-2 líneas), sin promesas médicas.
- Instructions seguras, paso a paso, mínimo 4 pasos, cada línea numerada "1. ...", en español.
- Si faltan datos críticos: REJECT con razón específica.

FORMATO DE INSTRUCTIONS:
Ejemplo:
"1. ...\n2. ...\n3. ...\n4. ..."

${candidatesToText(candidates)}

EJERCICIO CUSTOM:
- name: ${name}
- muscleGroup: ${muscleGroup}
- description: ${description}
- notes/instructions: ${notes}
- imageUrl: ${custom?.imageUrl ?? null}
- videoUrl: ${custom?.videoUrl ?? null}
`;
}

export async function reviewCustomExerciseWithLLM(params: {
  custom: any;
  candidates: CandidateCompact[];
  activeMuscleGroupIds: string[];
}): Promise<ExerciseReviewResult> {
  if (!process.env.OPENAI_API_KEY) {
    return {
      decision: "reject",
      reason: "OPENAI_API_KEY no está configurada.",
      isDuplicate: false,
      duplicateOfId: null,
      globalDraft: null,
    };
  }

  const prompt = buildPrompt(params);

  const resp = await client.responses.create({
    model: "gpt-5",
    input: prompt,
    response_format: {
      type: "json_schema",
      json_schema: OUTPUT_SCHEMA,
    } as any,
  } as any);

  const raw = resp.output_text;
  const parsed = JSON.parse(raw);

  return parsed as ExerciseReviewResult;
}
