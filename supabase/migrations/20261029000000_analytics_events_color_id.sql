-- log_analytics_events records the colour a `view` or `purchase_click` was
-- about, so a store can later tell which colour drove the click. The body
-- carries over from 20260916000000: only `view` and `purchase_click` are
-- accepted and products stay the authority on store_id. A colour id that does
-- not belong to that product is recorded as NULL instead of failing the batch,
-- the same rule log_tryon_events follows (20261027000000): a colour deleted
-- between rendering a card and tapping it must not discard the rest of the
-- queued events, and a client cannot attribute a click to another product's
-- colour. A malformed uuid still fails the call, as it does for product_id.
CREATE OR REPLACE FUNCTION "public"."log_analytics_events"("p_events" "jsonb") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" = "public"
    AS $$
begin
  insert into analytics_events (product_id, store_id, color_id, event_type, user_id)
  select
    p.id,
    p.store_id,
    c.id,
    (event->>'event_type')::analytics_event_type,
    auth.uid()
  from jsonb_array_elements(p_events) as event
  join products p
    on p.id = (event->>'product_id')::uuid
   and p.store_id = (event->>'store_id')::uuid
  left join product_colors c
    on c.id = (event->>'color_id')::uuid
   and c.product_id = p.id
  where event->>'event_type' in ('view', 'purchase_click');
end;
$$;
