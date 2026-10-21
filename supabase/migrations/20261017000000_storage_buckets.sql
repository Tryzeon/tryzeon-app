-- Both buckets were created in the dashboard before the schema lived in
-- migrations. Declaring them here lets a fresh database (local, staging) build
-- them; on prod they already exist, so this is a no-op there.
insert into storage.buckets (id, name, public)
values
  ('user-avatars', 'user-avatars', false),
  ('wardrobe-images', 'wardrobe-images', false)
on conflict (id) do nothing;
