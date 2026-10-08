-- link_events.user_id has had no writer since record_link_open was dropped in
-- 20260811000000: the short-links edge function, the table's only writer, records
-- anonymous QR opens, and the insert policy from 20260816000000 pins the column
-- to NULL. Nothing reads it either, so the column and its auth.users FK go.
--
-- The insert policy is its only dependent object and must be dropped before the
-- column. With user_id gone it has nothing left to guard, so it is recreated
-- unconditional; the reasoning in 20260816000000 for not restricting
-- source / platform / channel still holds.

drop policy if exists "Anyone can record a link open" on public.link_events;

alter table public.link_events drop column if exists user_id;

create policy "Anyone can record a link open"
  on public.link_events for insert
  with check (true);
