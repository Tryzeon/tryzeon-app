import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

// --- Configuration ---
const CONFIG = {
  SUPABASE_URL: Deno.env.get("SUPABASE_URL"),
  SUPABASE_SERVICE_ROLE_KEY: Deno.env.get("SUPABASE_SERVICE_ROLE_KEY"),
};

// --- Error Handling ---
class AppError extends Error {
  constructor(public message: string, public statusCode: number = 500) {
    super(message);
    this.name = "AppError";
  }
}

// --- Storage Cleanup Service ---
class StorageCleanupService {
  constructor(private supabase: any) {}

  async cleanupUserStorage(userId: string): Promise<void> {
    const buckets = ["user-avatars", "wardrobe-images", "store-logos", "product-images"];

    await Promise.all(
      buckets.map(async (bucket) => {
        try {
          const { data: files, error: listError } = await this.supabase.storage
            .from(bucket)
            .list(userId);

          if (listError || !files || files.length === 0) return;

          const filePaths = files.map((file: any) => `${userId}/${file.name}`);
          const { error: removeError } = await this.supabase.storage
            .from(bucket)
            .remove(filePaths);

          if (removeError) {
            console.warn(`Failed to delete files from ${bucket}/${userId}:`, removeError);
          }
        } catch (error) {
          console.warn(`Storage cleanup error in ${bucket}:`, error);
        }
      })
    );
  }
}

// --- Main Handler ---
Deno.serve(async (req) => {
  try {
    // 1. Authentication
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) throw new AppError("Missing Authorization header", 401);

    // Create user client for auth
    const userClient = createClient(
      CONFIG.SUPABASE_URL!,
      CONFIG.SUPABASE_SERVICE_ROLE_KEY!,
      { global: { headers: { Authorization: authHeader } } }
    );

    const { data: { user }, error: authError } = await userClient.auth.getUser();
    if (authError || !user) throw new AppError("Unauthorized", 401);

    // 2. Create admin client for database and storage operations
    const adminClient = createClient(
      CONFIG.SUPABASE_URL!,
      CONFIG.SUPABASE_SERVICE_ROLE_KEY!
    );

    // 3. Clean up user storage files
    const storageService = new StorageCleanupService(adminClient);
    await storageService.cleanupUserStorage(user.id);

    // 4. Delete auth user (triggers cascade delete for all DB records)
    const { error: deleteAuthError } = await adminClient.auth.admin.deleteUser(user.id);
    if (deleteAuthError) {
      console.error("Failed to delete auth user:", deleteAuthError);
      throw new AppError("Failed to delete authentication account", 500);
    }

    // 5. Success response
    return new Response(
      JSON.stringify({ message: "Account deleted successfully" }),
      { headers: { "Content-Type": "application/json" } }
    );

  } catch (err) {
    console.error(err);

    const status = err instanceof AppError ? err.statusCode : 500;
    const message = err instanceof AppError ? err.message : "Internal Server Error";

    return new Response(
      JSON.stringify({ message }),
      { status, headers: { "Content-Type": "application/json" } }
    );
  }
});
