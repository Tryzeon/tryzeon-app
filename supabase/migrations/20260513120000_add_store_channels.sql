-- 1. Add channels column to store_profiles
ALTER TABLE store_profiles
  ADD COLUMN channels text[] NOT NULL DEFAULT ARRAY['physical', 'online']
    CHECK (
      channels <@ ARRAY['physical', 'online']
      AND array_length(channels, 1) >= 1
    );

-- 2. GIN index for && overlaps queries
CREATE INDEX store_profiles_channels_idx
  ON store_profiles USING gin (channels);

-- 3. RPC that consolidates the shop product listing query
CREATE OR REPLACE FUNCTION get_shop_products(
  p_store_id        uuid    DEFAULT NULL,
  p_search_query    text    DEFAULT NULL,
  p_category_ids    text[]  DEFAULT NULL,
  p_min_price       int     DEFAULT NULL,
  p_max_price       int     DEFAULT NULL,
  p_channels        text[]  DEFAULT NULL,
  p_sort_column     text    DEFAULT 'created_at',
  p_sort_ascending  boolean DEFAULT false
)
RETURNS SETOF jsonb
LANGUAGE sql STABLE
SECURITY INVOKER
AS $$
  SELECT to_jsonb(t) FROM (
    SELECT
      p.id,
      p.store_id,
      p.name,
      p.category_ids,
      p.price,
      p.image_paths,
      p.created_at,
      p.updated_at,
      p.purchase_link,
      p.material,
      p.elasticity,
      p.fit,
      p.thickness,
      p.styles,
      p.seasons,
      COALESCE(
        (
          SELECT jsonb_agg(v)
          FROM product_variants v
          WHERE v.product_id = p.id
        ),
        '[]'::jsonb
      ) AS product_variants,
      jsonb_build_object(
        'id',         s.id,
        'name',       s.name,
        'address',    s.address,
        'logo_path',  s.logo_path,
        'channels',   s.channels
      ) AS store_profiles
    FROM products p
    JOIN store_profiles s ON s.id = p.store_id
    WHERE
      (p_store_id IS NULL OR p.store_id = p_store_id)
      AND (p_category_ids IS NULL OR p.category_ids && p_category_ids)
      AND (p_min_price IS NULL OR p.price >= p_min_price)
      AND (p_max_price IS NULL OR p.price <= p_max_price)
      AND (p_channels  IS NULL OR s.channels && p_channels)
      AND (
        p_search_query IS NULL
        OR p.name ILIKE '%' || p_search_query || '%'
        OR s.name ILIKE '%' || p_search_query || '%'
      )
    ORDER BY
      CASE WHEN p_sort_column = 'price'      AND     p_sort_ascending THEN p.price       END ASC  NULLS LAST,
      CASE WHEN p_sort_column = 'price'      AND NOT p_sort_ascending THEN p.price       END DESC NULLS LAST,
      CASE WHEN p_sort_column = 'created_at'                          THEN p.created_at  END DESC NULLS LAST
  ) t;
$$;

GRANT EXECUTE ON FUNCTION get_shop_products(uuid, text, text[], int, int, text[], text, boolean)
  TO anon, authenticated;
