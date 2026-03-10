import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { GoogleGenerativeAI } from "npm:@google/generative-ai";
import { createClient } from "jsr:@supabase/supabase-js@2";

class UserError extends Error {
  constructor(message: string, public statusCode: number = 400) {
    super(message);
    this.name = "UserError";
  }
}

Deno.serve(async (req) => {
  try {
    // 1. Auth: Verify JWT and get user
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) throw new UserError("Missing Authorization header", 401);

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

    // Create a client with the user's JWT
    const supabaseClient = createClient(
      supabaseUrl,
      supabaseKey,
      { global: { headers: { Authorization: authHeader } } },
    );

    const {
      data: { user },
      error: authError,
    } = await supabaseClient.auth.getUser();

    if (authError || !user) throw new UserError("Unauthorized", 401);

    // 2. Check and Increment Usage Quota via RPC
    const { data: isAllowed, error: rpcError } = await supabaseClient.rpc(
      "increment_feature_usage",
      { p_user_id: user.id, p_feature_name: "chat" }
    );

    if (rpcError) {
      console.error("RPC Error:", rpcError);
      throw new Error(`Failed to check usage limits: ${rpcError.message}`);
    }

    if (!isAllowed) {
      throw new UserError("Daily chat limit exceeded. Please upgrade your plan.", 429);
    }

    // 3. Process LLM Request
    const genAI = new GoogleGenerativeAI(Deno.env.get("GEMINI_API_KEY"));
    const LLM_Model = "gemini-2.5-flash";

    const { userRequirement } = await req.json();

    if (!userRequirement || userRequirement.trim() === "") {
      throw new UserError("請提供穿搭需求");
    }

    const prompt = `請根據以下穿搭需求，提供具體的服裝搭配建議，包括上衣、下身、鞋子和配件的推薦，簡短一點即可，但要分段說明。
  ${userRequirement}`;

    const model = genAI.getGenerativeModel({
      model: LLM_Model
    });

    const result = await model.generateContent(prompt);
    const text = result.response.text();

    return new Response(JSON.stringify({
      text
    }), {
      headers: {
        "Content-Type": "application/json"
      }
    });
  } catch (err) {
    let errorMessage = "Server Internal Error";
    let statusCode = 500;

    if (err instanceof UserError) {
      errorMessage = err.message;
      statusCode = err.statusCode;
    } else {
      console.error("Unexpected error:", err);
    }

    return new Response(JSON.stringify({
      message: errorMessage,
      code: statusCode === 429 ? "RATE_LIMIT_EXCEEDED" : "ERROR"
    }), {
      status: statusCode,
      headers: {
        "Content-Type": "application/json"
      }
    });
  }
});
