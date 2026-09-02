import Anthropic from "@anthropic-ai/sdk";
import { env } from "@/lib/env";

const SQM_JSON = /\{[\s\S]*"sizeSqm"[\s\S]*\}/;

function parseSqmResponse(text: string): number | null {
  const match = text.match(SQM_JSON);
  if (!match) return null;
  try {
    const parsed = JSON.parse(match[0]) as { sizeSqm?: number | null };
    const v = parsed.sizeSqm;
    if (typeof v !== "number" || !Number.isFinite(v) || v <= 0 || v > 10000) return null;
    return Math.round(v * 100) / 100;
  } catch {
    return null;
  }
}

/** Try to read apartment size (sqm) from an Arnona bill image/PDF in storage. */
export async function extractSqmFromArnonaDoc(
  bytes: Buffer,
  contentType: string,
): Promise<{ sizeSqm: number | null; source: "llm" | "manual" }> {
  if (!process.env.ANTHROPIC_API_KEY || process.env.ANTHROPIC_API_KEY.startsWith("REPLACE")) {
    return { sizeSqm: null, source: "manual" };
  }

  const isImage = contentType.startsWith("image/");
  const isPdf = contentType === "application/pdf" || contentType.includes("pdf");

  if (!isImage && !isPdf) return { sizeSqm: null, source: "manual" };

  try {
    const client = new Anthropic({ apiKey: env.anthropicApiKey });
    const prompt =
      "This is an Israeli Arnona (municipal tax) bill or property tax document. " +
      'Extract the apartment size in square meters (שטח, מ"ר, sqm). ' +
      'Reply with ONLY JSON: {"sizeSqm": number or null}';

    const content: Anthropic.MessageCreateParams["messages"][0]["content"] = isImage
      ? [
          {
            type: "image",
            source: {
              type: "base64",
              media_type: contentType as "image/jpeg" | "image/png" | "image/gif" | "image/webp",
              data: bytes.toString("base64"),
            },
          },
          { type: "text", text: prompt },
        ]
      : [
          {
            type: "document",
            source: {
              type: "base64",
              media_type: "application/pdf",
              data: bytes.toString("base64"),
            },
          },
          { type: "text", text: prompt },
        ];

    const res = await client.messages.create({
      model: "claude-sonnet-4-5",
      max_tokens: 200,
      messages: [{ role: "user", content }],
    });

    const text = res.content.find((c) => c.type === "text")?.text ?? "";
    const sizeSqm = parseSqmResponse(text);
    return { sizeSqm, source: sizeSqm != null ? "llm" : "manual" };
  } catch (err) {
    console.error("arnona sqm extract failed", err);
    return { sizeSqm: null, source: "manual" };
  }
}
