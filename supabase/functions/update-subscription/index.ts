import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient, SupabaseClient } from "jsr:@supabase/supabase-js@2";

// --- Configuration ---
const CONFIG = {
  SUPABASE_URL: Deno.env.get("SUPABASE_URL")!,
  SUPABASE_SERVICE_ROLE_KEY: Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
};

const VALID_PLANS = ["free", "pro", "max"] as const;
type PlanType = (typeof VALID_PLANS)[number];

const PLAN_ORDER: Record<PlanType, number> = {
  free: 0,
  pro: 1,
  max: 2,
};

// --- Types ---
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

    // Parse and validate request body
    const body = (await req.json()) as UpdateSubscriptionRequest;
    const { targetPlan } = body;

    if (!targetPlan || !VALID_PLANS.includes(targetPlan as PlanType)) {
      throw new AppError(
        `Invalid target plan: ${targetPlan}. Must be one of: ${VALID_PLANS.join(", ")}`,
        400,
        );
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
    const currentPlan = currentRow.plan as PlanType;

    // Validate plan change
    if (currentPlan === targetPlan) {
      throw new AppError("Already on this plan", 400);
    }

    const direction =
      PLAN_ORDER[targetPlan as PlanType] > PLAN_ORDER[currentPlan]
        ? "upgrade"
        : "downgrade";

    // ★ Future payment integration point:
    // Insert payment verification logic here for upgrades
    // e.g., verify payment token, process charge, etc.

    const adminClient = createClient(
      CONFIG.SUPABASE_URL,
      CONFIG.SUPABASE_SERVICE_ROLE_KEY,
    );

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
        direction,
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