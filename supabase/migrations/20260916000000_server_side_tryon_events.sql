-- `try_on` becomes a server-recorded event.
--
-- Until now the app enqueued a `try_on` event itself after a successful
-- try-on, alongside `view` and `purchase_click`. That made the client the
-- authority on a number stores are shown, and a bug or a hostile caller
-- holding the anon key could inflate any store's try-on count through
-- `log_analytics_events`. The try-on Edge Function already knows exactly which
-- products a finished job wore, so it records the event instead — through the
-- RPC below, on the service role, after the result is persisted.
--
-- `log_tryon_events` takes the user as a parameter because the LINE adapter
-- runs on the admin client, where `auth.uid()` is NULL. That is also why it is
-- service-role only: EXECUTE on it is the right to write try-ons for anyone,
-- against any store — the same shape as `increment_feature_usage`, and locked
-- down the same way (see 20260815000000: revoke from PUBLIC too, or the
-- schema's default privileges leave the same access reachable through it).
--
-- Products stay the authority on `store_id`, as in `log_analytics_events`
-- (20260819000000). An id that no longer names a product is dropped rather
-- than raised: the product was resolved as active when the job started, and a
-- deletion racing a generation is not worth failing a try-on the user was
-- already charged for. Ids are also counted once per job: the core accepts
-- the same product up to MAX_GARMENTS times (e.g. in different sizes), and one
-- generation is one try-on however many slots it filled.
--
-- `log_analytics_events` then stops accepting `try_on` at all. Now that the
-- client never legitimately sends one, any that arrives is noise or an
-- attempt to inflate a store's numbers, and it is filtered the way an unknown
-- event type already is: quietly, one row at a time, without discarding the
-- rest of the batch.

CREATE FUNCTION "public"."log_tryon_events"("p_user_id" "uuid", "p_product_ids" "uuid"[]) RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" = "public"
    AS $$
begin
  insert into analytics_events (product_id, store_id, event_type, user_id)
  select distinct
    p.id,
    p.store_id,
    'try_on'::analytics_event_type,
    p_user_id
  from unnest(p_product_ids) as ids(product_id)
  join products p on p.id = ids.product_id;
end;
$$;

REVOKE ALL ON FUNCTION "public"."log_tryon_events"("p_user_id" "uuid", "p_product_ids" "uuid"[])
  FROM PUBLIC, "anon", "authenticated";
GRANT EXECUTE ON FUNCTION "public"."log_tryon_events"("p_user_id" "uuid", "p_product_ids" "uuid"[])
  TO "service_role";

CREATE OR REPLACE FUNCTION "public"."log_analytics_events"("p_events" "jsonb") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" = "public"
    AS $$
begin
  insert into analytics_events (product_id, store_id, event_type, user_id)
  select
    p.id,
    p.store_id,
    (event->>'event_type')::analytics_event_type,
    auth.uid()
  from jsonb_array_elements(p_events) as event
  join products p
    on p.id = (event->>'product_id')::uuid
   and p.store_id = (event->>'store_id')::uuid
  where event->>'event_type' in ('view', 'purchase_click');
end;
$$;
