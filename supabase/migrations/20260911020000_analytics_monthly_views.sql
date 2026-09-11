-- Analytics are aggregated on read, from the event tables, through views.
--
-- analytics_product_monthly_summary was a trigger-maintained rollup: every
-- event paid an UPSERT on the hot path, the month buckets were fixed at write
-- time in UTC, and the QR scans it never covered were counted separately at
-- read time. At this scale a GROUP BY over the raw events is milliseconds, so
-- the rollup only bought two ways of being wrong. The views below are the
-- single definition of every number the dashboards show; when the event tables
-- outgrow them, the upgrade is a MATERIALIZED VIEW behind the same name, not a
-- rewrite of the readers.
--
-- security_invoker: the views inherit the caller's RLS on the event tables, so
-- a store owner sees their own store through the same view an admin uses.
-- Months are bucketed in Asia/Taipei — the business day the team reasons in —
-- rather than the UTC the trigger used.
--
-- The product view keeps the dropped table's name and columns: installed app
-- versions read analytics_product_monthly_summary by name, and updates are
-- prompted, not forced, so the name is the contract those clients hold.

DROP TRIGGER "on_analytics_event_inserted" ON "public"."analytics_events";
DROP FUNCTION "public"."update_analytics_summary"();
DROP TABLE "public"."analytics_product_monthly_summary";

CREATE INDEX "idx_analytics_events_store_created"
  ON "public"."analytics_events" USING "btree" ("store_id", "created_at");

CREATE INDEX "idx_link_events_created"
  ON "public"."link_events" USING "btree" ("created_at");

CREATE POLICY "Store owners can read their own events"
  ON "public"."analytics_events" FOR SELECT
  TO "authenticated"
  USING ("store_id" IN (
    SELECT "id" FROM "public"."store_profiles" WHERE "owner_id" = (SELECT "auth"."uid"())
  ));

CREATE POLICY "Admins can read all events"
  ON "public"."analytics_events" FOR SELECT
  TO "authenticated"
  USING ((SELECT "public"."is_admin"()));

CREATE VIEW "public"."analytics_product_monthly_summary"
  WITH ("security_invoker" = true) AS
SELECT
  "store_id",
  "product_id",
  EXTRACT(YEAR FROM "created_at" AT TIME ZONE 'Asia/Taipei')::integer AS "year",
  EXTRACT(MONTH FROM "created_at" AT TIME ZONE 'Asia/Taipei')::integer AS "month",
  COUNT(*) FILTER (WHERE "event_type" = 'view')::integer AS "view_count",
  COUNT(*) FILTER (WHERE "event_type" = 'try_on')::integer AS "tryon_count",
  COUNT(*) FILTER (WHERE "event_type" = 'purchase_click')::integer AS "purchase_click_count"
FROM "public"."analytics_events"
GROUP BY 1, 2, 3, 4;

CREATE VIEW "public"."analytics_store_monthly_summary"
  WITH ("security_invoker" = true) AS
SELECT
  "store_id",
  EXTRACT(YEAR FROM "created_at" AT TIME ZONE 'Asia/Taipei')::integer AS "year",
  EXTRACT(MONTH FROM "created_at" AT TIME ZONE 'Asia/Taipei')::integer AS "month",
  COUNT(*) FILTER (WHERE "event_type" = 'view')::integer AS "view_count",
  COUNT(*) FILTER (WHERE "event_type" = 'try_on')::integer AS "tryon_count",
  COUNT(*) FILTER (WHERE "event_type" = 'purchase_click')::integer AS "purchase_click_count"
FROM "public"."analytics_events"
GROUP BY 1, 2, 3;

CREATE VIEW "public"."scan_store_monthly_summary"
  WITH ("security_invoker" = true) AS
SELECT
  "sl"."store_id",
  EXTRACT(YEAR FROM "le"."created_at" AT TIME ZONE 'Asia/Taipei')::integer AS "year",
  EXTRACT(MONTH FROM "le"."created_at" AT TIME ZONE 'Asia/Taipei')::integer AS "month",
  COUNT(*)::integer AS "scan_count"
FROM "public"."link_events" "le"
JOIN "public"."short_links" "sl" ON "sl"."code" = "le"."code"
GROUP BY 1, 2, 3;

REVOKE ALL ON "public"."analytics_product_monthly_summary", "public"."analytics_store_monthly_summary", "public"."scan_store_monthly_summary" FROM "anon";
GRANT SELECT ON "public"."analytics_product_monthly_summary", "public"."analytics_store_monthly_summary", "public"."scan_store_monthly_summary" TO "authenticated", "service_role";

COMMENT ON VIEW "public"."analytics_product_monthly_summary" IS
  'Per store, product and Taipei calendar month: view / try-on / purchase-click counts. Read by the app''s store dashboard and the team dashboard''s brand page.';
COMMENT ON VIEW "public"."analytics_store_monthly_summary" IS
  'Per store and Taipei calendar month: view / try-on / purchase-click counts. Read by the team dashboard''s overview.';
COMMENT ON VIEW "public"."scan_store_monthly_summary" IS
  'Per store and Taipei calendar month: QR / short-link opens.';
