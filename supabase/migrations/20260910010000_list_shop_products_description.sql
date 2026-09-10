-- The shop grid hands its `ShopProduct` to the detail page as `initialProduct`
-- and the page then never refetches, so every column the detail page renders
-- must already be in this projection. `description` was added to the table and
-- to `get_shop_product` in 20260910000000 but not here, which left the app's
-- detail page blank for products opened from the grid.
--
-- Same signature, so CREATE OR REPLACE keeps the owner and grants.

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
      p.price,
      p.image_paths,
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

