-- The wardrobe limit is enforced only here; the app no longer pre-checks it.
-- A dedicated SQLSTATE lets the app tell "wardrobe full" apart from every
-- other CHECK failure (`check_violation` is shared by all of them) and offer
-- the upgrade dialog. Keep 'TZ001' in sync with mapExceptionToFailure.

CREATE OR REPLACE FUNCTION public.check_wardrobe_limit() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$DECLARE
  current_count INTEGER;
  var_wardrobe_limit INTEGER;
BEGIN
  -- 1. Read the wardrobe_limit of the user's tier (defaults to the 'free' tier
  --    when there is no subscription row)
  SELECT wardrobe_limit INTO var_wardrobe_limit
  FROM public.subscription_tiers
  WHERE id = COALESCE(
    (SELECT tier FROM public.subscriptions WHERE user_id = NEW.user_id LIMIT 1),
    'free'
  );

  -- 2. Count the items currently in the wardrobe
  SELECT COUNT(*) INTO current_count
  FROM public.wardrobe_items
  WHERE user_id = NEW.user_id;

  -- 3. Check whether the limit is exceeded
  IF current_count >= var_wardrobe_limit THEN
    RAISE EXCEPTION 'Wardrobe limit exceeded' USING ERRCODE = 'TZ001';
  END IF;

  RETURN NEW;
END;$$;
