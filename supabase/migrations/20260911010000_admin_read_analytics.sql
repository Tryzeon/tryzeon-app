-- Let Tryzeon staff read cross-store analytics through RLS (KAN-50).
--
-- The team dashboard on tryzeon.com reads the per-store funnel and QR scans for
-- every store. Rather than route that through a function on the service role,
-- the read is granted where every other read is decided: a SELECT policy per
-- table, keyed on membership in admin_users. The site then queries PostgREST
-- with the signed-in user's own session and the anon key.
--
-- is_admin() is SECURITY DEFINER because admin_users is deliberately not
-- readable by authenticated, and a policy expression runs with the caller's
-- privileges. Policies call it as `(select is_admin())` so the planner
-- evaluates it once per statement instead of once per row.
--
-- link_events was "writable, not readable" (20260816000000) because counts were
-- computed with the service role; that reader is gone, so staff now read it.

CREATE OR REPLACE FUNCTION "public"."is_admin"() RETURNS boolean
LANGUAGE "sql" STABLE SECURITY DEFINER
SET "search_path" = "public"
AS $$
  SELECT EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid());
$$;

REVOKE ALL ON FUNCTION "public"."is_admin"() FROM PUBLIC, "anon";
GRANT EXECUTE ON FUNCTION "public"."is_admin"() TO "authenticated", "service_role";

COMMENT ON FUNCTION "public"."is_admin"() IS
  'True when the caller is listed in admin_users. Used by the staff-read policies and by the dashboard to decide what to render.';

CREATE POLICY "Admins can read all product analytics"
  ON "public"."analytics_product_monthly_summary" FOR SELECT
  TO "authenticated"
  USING ((SELECT "public"."is_admin"()));

CREATE POLICY "Admins can read all short links"
  ON "public"."short_links" FOR SELECT
  TO "authenticated"
  USING ((SELECT "public"."is_admin"()));

CREATE POLICY "Admins can read link opens"
  ON "public"."link_events" FOR SELECT
  TO "authenticated"
  USING ((SELECT "public"."is_admin"()));
