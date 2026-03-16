// current model: gemini-2.5-flash
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { GoogleGenerativeAI } from "npm:@google/generative-ai";
import { CONFIG, getAuthenticatedUserClient, getAdminClient } from "../_shared/supabase.ts";
import { QuotaManager } from "../_shared/quota.ts";

Deno.serve(async (req) => {
  let quotaManager: QuotaManager | undefined;

  try {
    // Auth: Verify JWT and get user securely
    const { userClient, user, errorResponse } = await getAuthenticatedUserClient(req);
    if (errorResponse) return errorResponse;
    
    const adminClient = getAdminClient();

    // Check and Increment Usage Quota via RPC
    quotaManager = new QuotaManager(adminClient, user!.id, "chat");

    const canProceed = await quotaManager.incrementQuota();
    if (!canProceed) {
      return new Response(
        JSON.stringify({ error: "Rate limit exceeded", code: "RATE_LIMIT_EXCEEDED" }),
        { status: 429, headers: { "Content-Type": "application/json" } }
      );
    }

    // Validate Request Body
    const bodyText = await req.text();
    if (!bodyText) {
      return new Response(
        JSON.stringify({ error: "Empty request body", code: "BAD_REQUEST" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }
    const { userRequirement } = JSON.parse(bodyText);

    if (!userRequirement || userRequirement.trim() === "") {
      return new Response(
        JSON.stringify({ error: "Missing required fields", code: "VALIDATION_ERROR" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    // Process LLM Request
    const genAI = new GoogleGenerativeAI(CONFIG.GEMINI_API_KEY);
    const model = genAI.getGenerativeModel({ model: CONFIG.GEMINI_CHAT_MODEL });

    const prompt = `請根據以下穿搭需求，提供具體的服裝搭配建議，包括上衣、下身、鞋子和配件的推薦，簡短一點即可，但要分段說明。\n${userRequirement}`;

    const result = await model.generateContent(prompt);
    const text = result.response.text();

    // Return Success Response
    return new Response(JSON.stringify({ text }), {
      headers: { "Content-Type": "application/json" }
    });

  } catch (err) {
    console.error("Unexpected error:", err);
    
    await quotaManager?.rollbackQuota();

    return new Response(
      JSON.stringify({ error: "Internal server error", code: "INTERNAL_ERROR" }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});
