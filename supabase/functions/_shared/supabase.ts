import { createClient, SupabaseClient, User } from "jsr:@supabase/supabase-js@2";

export const CONFIG = {
    SUPABASE_URL: Deno.env.get("SUPABASE_URL")!,
    SUPABASE_SERVICE_ROLE_KEY: Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    GEMINI_API_KEY: Deno.env.get("GEMINI_API_KEY")!,
    GEMINI_CHAT_MODEL: Deno.env.get("GEMINI_CHAT_MODEL"),
    TRYON_MODEL: Deno.env.get("TRYON_MODEL"),
    VIDEO_MODEL: Deno.env.get("VIDEO_MODEL"),
}

/**
 * Validates the Authorization header and returns an authenticated `SupabaseClient` instance and the user.
 * Returns a Response object if validation fails, enabling direct early returns over throwing AppErrors.
 */
export const getAuthenticatedUserClient = async (
    req: Request
): Promise<{ userClient: SupabaseClient | null; user: User | null; errorResponse: Response | null }> => {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
        return {
            userClient: null,
            user: null,
            errorResponse: new Response(
                JSON.stringify({ error: "Unauthorized", code: "UNAUTHORIZED" }),
                { status: 401, headers: { "Content-Type": "application/json" } }
            ),
        };
    }

    const userClient = createClient(
        CONFIG.SUPABASE_URL,
        CONFIG.SUPABASE_SERVICE_ROLE_KEY,
        { global: { headers: { Authorization: authHeader } } }
    );

    const {
        data: { user },
        error: authError,
    } = await userClient.auth.getUser();

    if (authError || !user) {
        return {
            userClient: null,
            user: null,
            errorResponse: new Response(
                JSON.stringify({ error: "Unauthorized", code: "UNAUTHORIZED" }),
                { status: 401, headers: { "Content-Type": "application/json" } }
            ),
        };
    }

    return { userClient, user, errorResponse: null };
};

/**
 * Creates and returns an admin-level (Service Role) Supabaseclient. 
 * Use with caution to bypass Row Level Security.
 */
export const getAdminClient = (): SupabaseClient => {
    return createClient(CONFIG.SUPABASE_URL, CONFIG.SUPABASE_SERVICE_ROLE_KEY);
};
