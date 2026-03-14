import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

// --- Configuration ---
const CONFIG = {
  SUPABASE_URL: Deno.env.get("SUPABASE_URL")!,
  SUPABASE_SERVICE_ROLE_KEY: Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
};

// --- Types ---
interface PlanInfo {
  id: string;
  is_active: boolean;
}

interface UpdateSubscriptionRequest {
  targetPlan: string;
}

interface SubscriptionRow {
  user_id: string;
  plan: string;
}

// --- Error Handling ---
class AppError extends Error {
  constructor(
    public message: string,
    public statusCode: number = 500,
  ) {
    super(message);
    this.name = "AppError";
  }
}

// --- Main Handler ---
Deno.serve(async (req) => {
  try {
    // Auth: Verify JWT
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) throw new AppError("Missing Authorization header", 401);

    const userClient = createClient(
      CONFIG.SUPABASE_URL,
      CONFIG.SUPABASE_SERVICE_ROLE_KEY,
      { global: { headers: { Authorization: authHeader } } },
    );

    const {
      data: { user },
      error: authError,
    } = await userClient.auth.getUser();
    if (authError || !user) throw new AppError("Unauthorized", 401);

    const adminClient = createClient(
      CONFIG.SUPABASE_URL,
      CONFIG.SUPABASE_SERVICE_ROLE_KEY,
    );

    // Parse and validate request body
    const body = (await req.json()) as UpdateSubscriptionRequest;
    const { targetPlan } = body;

    if (!targetPlan) {
      throw new AppError("Target plan is required", 400);
    }

    // Validate target plan exists and is active
    const { data: targetPlanInfo, error: planError } = await adminClient
      .from("subscription_plans")
      .select("id, is_active")
      .eq("id", targetPlan)
      .single();

    if (planError || !targetPlanInfo) {
      throw new AppError(`Invalid target plan: ${targetPlan}`, 400);
    }

    const targetInfo = targetPlanInfo as PlanInfo;

    if (!targetInfo.is_active) {
      throw new AppError("This plan is not currently available.", 400);
    }

    // Hardcoded restriction: Prevent upgrading to max plan
    if (targetPlan === "max") {
      throw new AppError("Upgrading to max plan is not allowed", 403);
    }

    // Get current subscription
    const { data: currentSub, error: fetchError } = await userClient
      .from("subscriptions")
      .select("user_id, plan")
      .eq("user_id", user.id)
      .single();

    if (fetchError || !currentSub) {
      throw new AppError("Subscription not found", 404);
    }

    const currentRow = currentSub as SubscriptionRow;
    const currentPlan = currentRow.plan;

    // Validate plan change
    if (currentPlan === targetPlan) {
      throw new AppError("Already on this plan", 400);
    }

    // ★ Future payment integration point:
    // Insert payment verification logic here
    // e.g., verify payment token, process charge, etc.

    // Update subscription
    const { error: updateError } = await adminClient
      .from("subscriptions")
      .update({ plan: targetPlan })
      .eq("user_id", user.id);

    if (updateError) {
      throw new AppError(
        `Failed to update subscription: ${updateError.message}`,
        500,
      );
    }

    // Return result
    return new Response(
      JSON.stringify({
        user_id: user.id,
        plan: targetPlan,
        previous_plan: currentPlan,
      }),
      { headers: { "Content-Type": "application/json" } },
    );
  } catch (err) {
    console.error(err);
    const status = err instanceof AppError ? err.statusCode : 500;
    const message =
      err instanceof AppError ? err.message : "Internal Server Error";
    return new Response(JSON.stringify({ message }), {
      status,
      headers: { "Content-Type": "application/json" },
    });
  }
});