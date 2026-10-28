-- Product images move from `products.image_paths` into `product_colors`, one
-- row per colour of the same garment.
--
-- A product's images used to be a single array, so a store selling one shirt in
-- three colours had to list it three times: three cards in the shop, three
-- entries in chat search, three try-on targets that differ only in colour.
-- Colour is a variant of the garment, not a separate garment, so it gets its own
-- child table. Everything else (price, sizes, purchase link) stays on the
-- product and is shared by its colours.
--
-- The image-path CHECK from 20261026000000 moves with the paths. A CHECK cannot
-- look up another table, so each colour row carries its product's `store_id`,
-- and the composite foreign key `(product_id, store_id) -> products (id,
-- store_id)` guarantees that copy matches the product. With both ids on the row,
-- `product_image_paths_owned` is reused unchanged instead of becoming a
-- table-reading trigger. The key needs `products (id, store_id)` to be unique;
-- `id` alone already is, so the new constraint only exists to be referenced.
-- The key has no ON UPDATE CASCADE: the stored paths embed the store id, so a
-- cascaded store_id would still fail the path-ownership CHECK, and moving a
-- product to another store needs its paths rewritten anyway.
--
-- Every colour holds at least one image, so the product's cover is simply the
-- first image of its first colour in `position, created_at, id` order. The RPCs
-- return colours in that order and clients that embed `product_colors` request
-- it, so no reader re-implements the rule.
--
-- Backfill gives every existing product exactly one unnamed colour holding its
-- current images. Colour words in existing product names are not parsed out:
-- they sit at no fixed place in the name, so a pattern would mislabel or truncate
-- many of them, and a single colour shows no name anyway. Stores name it when
-- they add a second colour. Existing paths already passed the owner check
-- against the same store and product ids, so they pass the new one too.

ALTER TABLE "public"."products"
  ADD CONSTRAINT "products_id_store_id_key" UNIQUE ("id", "store_id");

CREATE TABLE "public"."product_colors" (
  "id" "uuid" PRIMARY KEY DEFAULT "gen_random_uuid"(),
  "product_id" "uuid" NOT NULL,
  "store_id" "uuid" NOT NULL,
  "name" "text",
  "image_paths" "text"[] NOT NULL,
  "position" smallint NOT NULL,
  "created_at" timestamp with time zone NOT NULL DEFAULT "now"(),
  "updated_at" timestamp with time zone NOT NULL DEFAULT "now"(),
  FOREIGN KEY ("product_id", "store_id")
    REFERENCES "public"."products" ("id", "store_id") ON DELETE CASCADE,
  CONSTRAINT "product_colors_name_check"
    CHECK (
      "name" IS NULL
      OR ("name" = btrim("name") AND char_length("name") BETWEEN 1 AND 20)
    ),
  CONSTRAINT "product_colors_image_paths_check" CHECK (cardinality("image_paths") >= 1),
  CONSTRAINT "product_colors_position_check" CHECK ("position" >= 0),
  CONSTRAINT "product_colors_image_paths_owner_check"
    CHECK ("public"."product_image_paths_owned"("image_paths", "store_id", "product_id"))
);

CREATE INDEX "idx_product_colors_product_id"
  ON "public"."product_colors" USING "btree" ("product_id", "position");

CREATE UNIQUE INDEX "uq_product_colors_product_name"
  ON "public"."product_colors" USING "btree" ("product_id", "name")
  WHERE "name" IS NOT NULL;

CREATE TRIGGER "trg_product_colors_updated_at"
  BEFORE UPDATE ON "public"."product_colors"
  FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();

-- Visibility follows the product exactly as product_sizes does since
-- 20261026000100: shoppers see colours of listed products, and an owner still
-- reads the colours of their own archived products back after a write.
ALTER TABLE "public"."product_colors" ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Colors are visible with their product"
  ON "public"."product_colors" FOR SELECT
  USING (
    EXISTS (
      SELECT 1
      FROM "public"."products" "p"
      WHERE "p"."id" = "product_colors"."product_id"
    )
  );

-- Writes are keyed on the row's own store_id; the composite foreign key already
-- ties it to the product, so no products lookup is needed here.
CREATE POLICY "Stores can insert colors for their products"
  ON "public"."product_colors" FOR INSERT
  WITH CHECK (
    "store_id" IN (
      SELECT "store_profiles"."id"
      FROM "public"."store_profiles"
      WHERE "store_profiles"."owner_id" = "auth"."uid"()
    )
  );

CREATE POLICY "Stores can update colors for their products"
  ON "public"."product_colors" FOR UPDATE
  USING (
    "store_id" IN (
      SELECT "store_profiles"."id"
      FROM "public"."store_profiles"
      WHERE "store_profiles"."owner_id" = "auth"."uid"()
    )
  )
  WITH CHECK (
    "store_id" IN (
      SELECT "store_profiles"."id"
      FROM "public"."store_profiles"
      WHERE "store_profiles"."owner_id" = "auth"."uid"()
    )
  );

CREATE POLICY "Stores can delete colors for their products"
  ON "public"."product_colors" FOR DELETE
  USING (
    "store_id" IN (
      SELECT "store_profiles"."id"
      FROM "public"."store_profiles"
      WHERE "store_profiles"."owner_id" = "auth"."uid"()
    )
  );

REVOKE ALL ON "public"."product_colors" FROM "anon", "authenticated";
GRANT SELECT ON "public"."product_colors" TO "anon", "authenticated";
GRANT INSERT, UPDATE, DELETE ON "public"."product_colors" TO "authenticated";

INSERT INTO "public"."product_colors"
  ("product_id", "store_id", "image_paths", "position", "created_at", "updated_at")
SELECT
  "id",
  "store_id",
  "image_paths",
  0,
  "created_at",
  "updated_at"
FROM "public"."products";

-- Same signatures as before, so CREATE OR REPLACE keeps owners and grants.
-- Both projections swap image_paths for the product's colours in cover order.
CREATE OR REPLACE FUNCTION "public"."get_shop_product"("p_id" "uuid")
RETURNS "jsonb"
LANGUAGE "sql" STABLE
AS $$
  SELECT to_jsonb(t) FROM (
    SELECT
      p.id,
      p.name,
      p.garment_type,
      p.price,
      COALESCE(
        (
          SELECT jsonb_agg(to_jsonb(c) ORDER BY c.position, c.created_at, c.id)
          FROM product_colors c
          WHERE c.product_id = p.id
        ),
        '[]'::jsonb
      ) AS product_colors,
      p.purchase_link,
      p.description,
      p.material,
      p.elasticity,
      p.fit,
      p.thickness,
      jsonb_build_object('name', s.name) AS store_profiles
    FROM products p
    JOIN store_profiles s ON s.id = p.store_id
    WHERE p.id = p_id
      AND p.status = 'active'
  ) t;
$$;

-- list_shop_products: full body copied from 20260912000200; only the image
-- projection changes.
CREATE OR REPLACE FUNCTION "public"."list_shop_products"(
  "p_store_id" "uuid" DEFAULT NULL::"uuid",
  "p_search_query" "text" DEFAULT NULL::"text",
  "p_category_ids" "text"[] DEFAULT NULL::"text"[],
  "p_min_price" integer DEFAULT NULL::integer,
  "p_max_price" integer DEFAULT NULL::integer,
  "p_channels" "public"."store_channel"[] DEFAULT NULL::"public"."store_channel"[],
  "p_gender" "public"."product_gender" DEFAULT NULL::"public"."product_gender",
  "p_materials" "text"[] DEFAULT NULL::"text"[],
  "p_elasticities" "public"."product_elasticity"[] DEFAULT NULL::"public"."product_elasticity"[],
  "p_fits" "public"."product_fit"[] DEFAULT NULL::"public"."product_fit"[],
  "p_thicknesses" "public"."product_thickness"[] DEFAULT NULL::"public"."product_thickness"[],
  "p_styles" "text"[] DEFAULT NULL::"text"[],
  "p_seasons" "public"."product_season"[] DEFAULT NULL::"public"."product_season"[],
  "p_sort_column" "text" DEFAULT 'created_at'::"text",
  "p_sort_ascending" boolean DEFAULT false,
  "p_user_lat" double precision DEFAULT NULL::double precision,
  "p_user_lng" double precision DEFAULT NULL::double precision,
  "p_limit" integer DEFAULT NULL::integer,
  "p_offset" integer DEFAULT 0
) RETURNS SETOF "jsonb"
    LANGUAGE "sql" STABLE
    AS $$
  SELECT to_jsonb(t) FROM (
    SELECT
      p.id,
      p.store_id,
      p.name,
      p.category_id,
      p.garment_type,
      p.price,
      COALESCE(
        (
          SELECT jsonb_agg(to_jsonb(c) ORDER BY c.position, c.created_at, c.id)
          FROM product_colors c
          WHERE c.product_id = p.id
        ),
        '[]'::jsonb
      ) AS product_colors,
      p.created_at,
      p.updated_at,
      p.purchase_link,
      p.description,
      p.material,
      p.elasticity,
      p.fit,
      p.thickness,
      p.styles,
      p.seasons,
      p.gender,
      COALESCE(
        (
          SELECT jsonb_agg(v)
          FROM product_sizes v
          WHERE v.product_id = p.id
        ),
        '[]'::jsonb
      ) AS product_sizes,
      jsonb_build_object(
        'id',             s.id,
        'name',           s.name,
        'address',        s.address,
        'logo_path',      s.logo_path,
        'channels',       s.channels,
        'order_contacts', COALESCE(s.order_contacts, '[]'::jsonb)
      ) AS store_profiles
    FROM products p
    JOIN store_profiles s ON s.id = p.store_id
    WHERE
      p.status = 'active'
      AND (p_store_id IS NULL OR p.store_id = p_store_id)
      AND (p_category_ids IS NULL OR p.category_id = ANY((p_category_ids)::uuid[]))
      AND (p_min_price IS NULL OR p.price >= p_min_price)
      AND (p_max_price IS NULL OR p.price <= p_max_price)
      AND (p_channels  IS NULL OR s.channels && p_channels)
      AND (p_gender IS NULL OR p.gender = p_gender OR p.gender = 'unisex')
      AND (
        p_materials IS NULL
        OR EXISTS (
            SELECT 1 FROM unnest(p_materials) AS m
            WHERE p.material ILIKE '%' || m || '%'
        )
      )
      AND (p_elasticities IS NULL OR p.elasticity = ANY(p_elasticities))
      AND (p_fits IS NULL OR p.fit = ANY(p_fits))
      AND (p_thicknesses IS NULL OR p.thickness = ANY(p_thicknesses))
      AND (p_styles IS NULL OR p.styles && p_styles)
      AND (p_seasons IS NULL OR p.seasons && p_seasons)
      AND (
        p_search_query IS NULL
        OR s.name ILIKE '%' || p_search_query || '%'
        OR COALESCE(
            (
                SELECT bool_and(p.name ILIKE '%' || token || '%')
                FROM unnest(string_to_array(trim(p_search_query), ' ')) AS token
                WHERE token <> ''
            ),
            false
        )
      )
    ORDER BY
      CASE
        WHEN p_sort_column = 'proximity'
             AND p_user_lat IS NOT NULL AND p_user_lng IS NOT NULL
             AND s.latitude IS NOT NULL AND s.longitude IS NOT NULL
        THEN 2 * 6371000 * asin(
               sqrt(
                 power(sin(radians(s.latitude - p_user_lat) / 2), 2)
                 + cos(radians(p_user_lat)) * cos(radians(s.latitude))
                   * power(sin(radians(s.longitude - p_user_lng) / 2), 2)
               )
             )
      END ASC NULLS LAST,
      CASE WHEN p_sort_column = 'price' AND     p_sort_ascending THEN p.price END ASC  NULLS LAST,
      CASE WHEN p_sort_column = 'price' AND NOT p_sort_ascending THEN p.price END DESC NULLS LAST,
      p.created_at DESC,
      p.id DESC
    LIMIT p_limit OFFSET p_offset
  ) t;
$$;

ALTER TABLE "public"."products" DROP CONSTRAINT "products_image_paths_owner_check";
ALTER TABLE "public"."products" DROP COLUMN "image_paths";

-- Which colour was tried on cannot be reconstructed later, so it is recorded
-- from now on even though no report reads it yet. No foreign key, for the same
-- reason product_id has none (20260818000000): events outlive what they count.
ALTER TABLE "public"."analytics_events" ADD COLUMN "color_id" "uuid";

-- log_tryon_events now takes the colour each garment was worn in. Everything
-- else carries over from 20260916000000: products stay the authority on
-- store_id, an unknown product is dropped rather than raised, and one job is
-- one try-on per product however many slots it filled. A colour id that does
-- not belong to that product is recorded as NULL instead of failing the event;
-- a malformed uuid still fails the call.
DROP FUNCTION "public"."log_tryon_events"("uuid", "uuid"[]);

CREATE FUNCTION "public"."log_tryon_events"("p_user_id" "uuid", "p_worn" "jsonb") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" = "public"
    AS $$
begin
  insert into analytics_events (product_id, store_id, color_id, event_type, user_id)
  select distinct on (p.id)
    p.id,
    p.store_id,
    c.id,
    'try_on'::analytics_event_type,
    p_user_id
  from jsonb_array_elements(p_worn) as w
  join products p on p.id = (w->>'product_id')::uuid
  left join product_colors c
    on c.id = (w->>'color_id')::uuid
   and c.product_id = p.id
  order by p.id, c.id nulls last;
end;
$$;

REVOKE ALL ON FUNCTION "public"."log_tryon_events"("p_user_id" "uuid", "p_worn" "jsonb")
  FROM PUBLIC, "anon", "authenticated";
GRANT EXECUTE ON FUNCTION "public"."log_tryon_events"("p_user_id" "uuid", "p_worn" "jsonb")
  TO "service_role";
