-- Reference rows that prod gained through the dashboard, so a fresh database
-- (local, staging) can sign users up and list categories. Values are prod's as
-- of 2026-10-21; on prod every statement below leaves the data unchanged.

INSERT INTO "public"."subscription_tiers" ("id", "wardrobe_limit", "tryon_limit", "chat_limit", "video_limit")
VALUES
  ('free', 20, 20, 20, 0),
  ('pro', 50, 50, 50, 5),
  ('max', 100, 100, 100, 10)
ON CONFLICT ("id") DO NOTHING;

INSERT INTO "public"."product_categories"
  ("id", "code", "name", "gender", "order", "default_garment_type", "image_male", "image_female")
VALUES
  ('4d20baff-e9af-4141-b895-6c2af1236d58', 'shirt_polo', '襯衫·POLO衫', 'unisex', 100, 'top', 'product-categories/shirt_m.webp', 'product-categories/shirt_f.webp'),
  ('a3c7159f-5e3c-4e06-9e67-92b7625848ab', 'vest', '背心·無袖上衣', 'unisex', 101, 'top', 'product-categories/vest_m.webp', 'product-categories/vest_f.webp'),
  ('d3d8835e-ee83-4f12-bde7-d97c7e91d5b1', 'knit_sweater', '針織·毛衣', 'unisex', 102, 'top', 'product-categories/sweater_m.webp', 'product-categories/sweater_f.webp'),
  ('648d8b10-20db-484b-b9b0-2324e6cbf05c', 'hoodie', '大學T·連帽T', 'unisex', 103, 'top', 'product-categories/Tshirt_withhat_m.webp', 'product-categories/Tshirt_withhat_f.webp'),
  ('2819bb31-5c19-4ec8-bf14-8b34fcdf7ba9', 'long_sleeve', '長袖', 'unisex', 104, 'top', 'product-categories/long_shirt_m.webp', 'product-categories/long_shirt_f.webp'),
  ('d6ce13f9-0694-47e8-81a1-6d95ceba9540', 'short_sleeve', '短袖', 'unisex', 105, 'top', 'product-categories/short_shirt_m.webp', 'product-categories/short_shirt_f.webp'),
  ('6def61ea-744e-454b-9aa1-15d6163d2ad0', 'skirt', '裙子', 'female', 110, 'skirt', NULL, 'product-categories/skirt_f.webp'),
  ('0705a794-04e1-427c-b3a2-07e705fe220c', 'trousers', '長褲', 'unisex', 111, 'pants', 'product-categories/trousers_m.webp', 'product-categories/trousers_f.webp'),
  ('a33db3b5-2caa-4f3d-8b61-1102b9ef8910', 'shorts', '短褲', 'unisex', 112, 'pants', 'product-categories/short_m.webp', 'product-categories/shorts_f.webp'),
  ('9c6960b8-81ff-45c3-8c88-4e729edafb14', 'jumpsuit', '連身褲', 'unisex', 113, 'one_piece', 'product-categories/trousers_m.webp', 'product-categories/trousers_f.webp'),
  ('217910ad-07e3-4901-ae83-d6ec0aeb697f', 'dress', '洋裝·連身裙', 'female', 120, 'one_piece', NULL, 'product-categories/skirt_suit_f.webp'),
  ('2c5304d5-1033-492d-9e8e-3ad73f297639', 'outerwear', '外套', 'unisex', 130, 'outerwear', 'product-categories/coat_m.webp', 'product-categories/coat_f.webp')
ON CONFLICT ("code") DO UPDATE SET
  "name" = EXCLUDED."name",
  "gender" = EXCLUDED."gender",
  "order" = EXCLUDED."order",
  "default_garment_type" = EXCLUDED."default_garment_type",
  "image_male" = EXCLUDED."image_male",
  "image_female" = EXCLUDED."image_female";
