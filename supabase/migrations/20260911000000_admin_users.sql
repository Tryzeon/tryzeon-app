-- Allowlist for the team dashboard on tryzeon.com (KAN-50).
--
-- The dashboard reads every store's funnel, which no existing policy allows:
-- analytics_product_monthly_summary is readable only by the owning store and
-- link_events by nobody. The aggregation lives in the `brand-analytics` edge
-- function on the service role; this table is the one thing the database has
-- to know — who counts as Tryzeon staff. No policies, so anon/authenticated
-- can neither read nor write it; rows are inserted by hand in the SQL editor.

CREATE TABLE "public"."admin_users" (
  "user_id" "uuid" PRIMARY KEY REFERENCES "auth"."users"("id") ON DELETE CASCADE,
  "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

ALTER TABLE "public"."admin_users" ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE "public"."admin_users" FROM "anon", "authenticated";
