// functions/src/utils/normalize.ts

export function normalizeText(input: string): string {
  return String(input || "")
    .toLowerCase()
    .trim()
    // quitar tildes/diacríticos
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/ñ/g, "n")
    .replace(/[^a-z0-9\s]+/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

export function slugifyId(input: string, maxLen = 40): string {
  return normalizeText(input)
    .replace(/\s+/g, "_")
    .replace(/^_+|_+$/g, "")
    .slice(0, maxLen);
}

export function buildNameTokens(input: string): string[] {
  const norm = normalizeText(input);
  if (!norm) return [];

  // tokens básicos
  const rawTokens = norm.split(" ").filter(Boolean);

  // filtra tokens muy cortos y “stopwords” simples
  const stop = new Set(["de", "del", "la", "el", "y", "con", "en", "a", "por", "para"]);
  const tokens = rawTokens
    .filter((t) => t.length >= 3)
    .filter((t) => !stop.has(t));

  // dedupe
  return Array.from(new Set(tokens)).slice(0, 12);
}
