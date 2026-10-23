import { getAuthenticatedUserClient } from "../_shared/supabase.ts";
import { checkImageAnalysisRateLimit } from "../_shared/image-analysis.ts";
import { classifyCoreError } from "../_shared/errors.ts";
import { coreErrorResponse, json, jsonError } from "../_shared/http.ts";
import { analyzeFile } from "../_shared/vertex/analyze-file.ts";
import {
  buildPrompt,
  buildSchema,
  normalizeParsedSizes,
  validateRequest,
} from "./parse.ts";

// A 60 s recording, the app's cap, takes about 10 s; the app gives up at 30 s
// (`SizeVoiceParserImpl`), which leaves room to upload up to ~1.3 MB of base64.
const PARSE_DEADLINE_MS = 20_000;

Deno.serve(async (req) => {
  try {
    const { user, errorResponse } = await getAuthenticatedUserClient(req);
    if (errorResponse) return errorResponse;

    const body = await req.json().catch(() => null);
    const validation = validateRequest(body);
    if (!validation.ok) return validation.response;

    const limited = await checkImageAnalysisRateLimit(
      user!.id,
      "size_voice_parse",
    );
    if (limited) return limited;

    const raw = await analyzeFile({
      prompt: buildPrompt(validation.currentUnit),
      file: { mediaType: validation.mimeType, data: validation.base64 },
      schema: buildSchema(),
      deadlineMs: PARSE_DEADLINE_MS,
    });

    return json({ sizes: normalizeParsedSizes(raw) });
  } catch (err) {
    const core = classifyCoreError(err);
    if (core) return coreErrorResponse(core);
    console.error("parse-size-voice error", err);
    return jsonError("Internal error", "INTERNAL", 500);
  }
});
