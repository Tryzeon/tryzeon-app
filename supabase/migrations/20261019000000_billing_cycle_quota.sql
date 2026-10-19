-- Billing-cycle quota. Paid tiers get a monthly window that follows the store's
-- current billing period (synced by revenuecat-webhook), so usage resets on the
-- renewal date; free stays a daily window.
-- The old tryon_limit/video_limit/chat_limit columns, user_daily_usage and the
-- increment/decrement_feature_usage RPCs stay until the follow-up migration so
-- older app builds keep working.

CREATE TYPE public.usage_feature AS ENUM ('tryon_image', 'tryon_video');
CREATE TYPE public.quota_period AS ENUM ('day', 'month');

CREATE TABLE public.feature_usage (
  user_id uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  feature public.usage_feature NOT NULL,
  period public.quota_period NOT NULL,
  window_start timestamptz NOT NULL,
  window_end timestamptz NOT NULL,
  used int NOT NULL DEFAULT 0 CHECK (used >= 0),
  PRIMARY KEY (user_id, feature, period, window_start),
  CHECK (window_end > window_start)
);

CREATE INDEX feature_usage_window_end_idx ON public.feature_usage (window_end);

ALTER TABLE public.feature_usage ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE public.feature_usage FROM anon, authenticated;

ALTER TABLE public.subscription_tiers
  ADD COLUMN tryon_image_quota int,
  ADD COLUMN tryon_video_quota int;

UPDATE public.subscription_tiers SET tryon_image_quota = 10, tryon_video_quota = 0 WHERE id = 'free';
UPDATE public.subscription_tiers SET tryon_image_quota = 250, tryon_video_quota = 3 WHERE id = 'pro';
UPDATE public.subscription_tiers SET tryon_image_quota = 600, tryon_video_quota = 10 WHERE id = 'max';

ALTER TABLE public.subscription_tiers
  ALTER COLUMN tryon_image_quota SET NOT NULL,
  ALTER COLUMN tryon_video_quota SET NOT NULL;

-- A paid row with no period end is a non-expiring entitlement (lifetime or a
-- dashboard grant).
ALTER TABLE public.subscriptions
  ADD COLUMN current_period_start timestamptz,
  ADD COLUMN current_period_end timestamptz;

UPDATE public.subscriptions SET current_period_start = now() WHERE tier <> 'free';

ALTER TABLE public.subscriptions
  ADD CONSTRAINT subscriptions_period_start_matches_tier
    CHECK ((tier = 'free') = (current_period_start IS NULL)),
  ADD CONSTRAINT subscriptions_free_has_no_period_end
    CHECK (tier <> 'free' OR current_period_end IS NULL);

CREATE FUNCTION public.quota_months_elapsed(p_from timestamptz, p_to timestamptz)
    RETURNS int
    LANGUAGE plpgsql IMMUTABLE
    SET search_path = ''
    SET TimeZone = 'UTC'
    AS $$
DECLARE
  v_k int;
BEGIN
  v_k := (extract(year FROM p_to) - extract(year FROM p_from))::int * 12
       + (extract(month FROM p_to) - extract(month FROM p_from))::int;
  IF p_from + make_interval(months => v_k) > p_to THEN
    v_k := v_k - 1;
  END IF;
  RETURN GREATEST(v_k, 0);
END;
$$;

-- period is part of the key so a free day row and a paid month row that start
-- at the same instant never share a counter.
--
-- A store period longer than a month (annual plan, long promotional grant) is
-- split into monthly windows anchored on its start, the last one ending at the
-- period end. The window count is the period length rounded to whole months,
-- so a monthly period whose store end differs from start + 1 month by a day or
-- so stays one window instead of gaining a sliver window with a fresh quota.
--
-- A period that has already ended (late renewal webhook, billing grace) rolls
-- forward from its end, not its start, so the key equals the period start the
-- renewal then writes and the window's usage is not split. Months are always
-- added to that base, never to the previous window start, so a month-end base
-- clamped in February does not drift earlier afterwards.
CREATE FUNCTION public.quota_window(
  p_period_start timestamptz,
  p_period_end timestamptz,
  p_now timestamptz,
  OUT window_start timestamptz,
  OUT resets_at timestamptz,
  OUT period public.quota_period
) RETURNS record
    LANGUAGE plpgsql IMMUTABLE
    SET search_path = ''
    SET TimeZone = 'UTC'
    AS $$
DECLARE
  v_today date;
  v_base timestamptz;
  v_windows int;
  v_k int;
BEGIN
  IF p_period_start IS NULL THEN
    v_today := (p_now AT TIME ZONE 'Asia/Taipei')::date;
    window_start := v_today::timestamp AT TIME ZONE 'Asia/Taipei';
    resets_at := (v_today + 1)::timestamp AT TIME ZONE 'Asia/Taipei';
    period := 'day';
    RETURN;
  END IF;

  period := 'month';
  IF p_period_end > p_now THEN
    v_windows := public.quota_months_elapsed(p_period_start, p_period_end);
    IF p_period_end - (p_period_start + make_interval(months => v_windows))
       > (p_period_start + make_interval(months => v_windows + 1)) - p_period_end THEN
      v_windows := v_windows + 1;
    END IF;
    v_windows := GREATEST(v_windows, 1);
    v_k := LEAST(public.quota_months_elapsed(p_period_start, p_now), v_windows - 1);
    window_start := p_period_start + make_interval(months => v_k);
    resets_at := CASE
      WHEN v_k = v_windows - 1 THEN p_period_end
      ELSE p_period_start + make_interval(months => v_k + 1)
    END;
    RETURN;
  END IF;

  v_base := COALESCE(p_period_end, p_period_start);
  v_k := public.quota_months_elapsed(v_base, p_now);
  window_start := v_base + make_interval(months => v_k);
  resets_at := v_base + make_interval(months => v_k + 1);
END;
$$;

CREATE FUNCTION public.quota_snapshot(p_user_id uuid) RETURNS jsonb
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path = ''
    AS $$
DECLARE
  v_tier text;
  v_period_start timestamptz;
  v_period_end timestamptz;
  v_tryon_image_quota int;
  v_tryon_video_quota int;
  v_window_start timestamptz;
  v_resets_at timestamptz;
  v_period public.quota_period;
  v_tryon_image_used int;
  v_tryon_video_used int;
BEGIN
  SELECT s.tier, s.current_period_start, s.current_period_end
    INTO v_tier, v_period_start, v_period_end
    FROM public.subscriptions s
   WHERE s.user_id = p_user_id;
  v_tier := COALESCE(v_tier, 'free');

  SELECT t.tryon_image_quota, t.tryon_video_quota INTO v_tryon_image_quota, v_tryon_video_quota
    FROM public.subscription_tiers t
   WHERE t.id = v_tier;

  SELECT w.window_start, w.resets_at, w.period INTO v_window_start, v_resets_at, v_period
    FROM public.quota_window(v_period_start, v_period_end, now()) w;

  SELECT COALESCE(sum(u.used) FILTER (WHERE u.feature = 'tryon_image'), 0)::int,
         COALESCE(sum(u.used) FILTER (WHERE u.feature = 'tryon_video'), 0)::int
    INTO v_tryon_image_used, v_tryon_video_used
    FROM public.feature_usage u
   WHERE u.user_id = p_user_id
     AND u.period = v_period
     AND u.window_start = v_window_start;

  RETURN jsonb_build_object(
    'tier', v_tier,
    'period', v_period,
    'resetsAt', v_resets_at,
    'tryonImage', jsonb_build_object('used', v_tryon_image_used, 'quota', v_tryon_image_quota),
    'tryonVideo', jsonb_build_object('used', v_tryon_video_used, 'quota', v_tryon_video_quota)
  );
END;
$$;

CREATE FUNCTION public.consume_quota(p_user_id uuid, p_feature public.usage_feature)
    RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path = ''
    AS $$
DECLARE
  v_tier text;
  v_period_start timestamptz;
  v_period_end timestamptz;
  v_quota int;
  v_window_start timestamptz;
  v_resets_at timestamptz;
  v_period public.quota_period;
  v_allowed boolean := false;
BEGIN
  SELECT s.tier, s.current_period_start, s.current_period_end
    INTO v_tier, v_period_start, v_period_end
    FROM public.subscriptions s
   WHERE s.user_id = p_user_id;
  v_tier := COALESCE(v_tier, 'free');

  SELECT CASE p_feature
           WHEN 'tryon_image' THEN t.tryon_image_quota
           WHEN 'tryon_video' THEN t.tryon_video_quota
         END INTO v_quota
    FROM public.subscription_tiers t
   WHERE t.id = v_tier;

  SELECT w.window_start, w.resets_at, w.period INTO v_window_start, v_resets_at, v_period
    FROM public.quota_window(v_period_start, v_period_end, now()) w;

  IF v_quota IS NOT NULL AND v_quota > 0 THEN
    INSERT INTO public.feature_usage AS u (user_id, feature, period, window_start, window_end, used)
    VALUES (p_user_id, p_feature, v_period, v_window_start, v_resets_at, 1)
    ON CONFLICT (user_id, feature, period, window_start)
    DO UPDATE SET used = u.used + 1
      WHERE u.used < v_quota;
    v_allowed := FOUND;
  END IF;

  RETURN jsonb_build_object(
    'allowed', v_allowed,
    'windowStart', v_window_start,
    'period', v_period,
    'quota', CASE WHEN v_allowed THEN NULL ELSE public.quota_snapshot(p_user_id) END
  );
END;
$$;

CREATE FUNCTION public.release_quota(
  p_user_id uuid,
  p_feature public.usage_feature,
  p_period public.quota_period,
  p_window_start timestamptz
) RETURNS void
    LANGUAGE sql SECURITY DEFINER
    SET search_path = ''
    AS $$
  UPDATE public.feature_usage
     SET used = used - 1
   WHERE user_id = p_user_id
     AND feature = p_feature
     AND period = p_period
     AND window_start = p_window_start
     AND used > 0;
$$;

CREATE FUNCTION public.get_quota_snapshot() RETURNS jsonb
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path = ''
    AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RETURN NULL;
  END IF;
  RETURN public.quota_snapshot(auth.uid());
END;
$$;

REVOKE ALL ON FUNCTION public.quota_months_elapsed(timestamptz, timestamptz) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.quota_window(timestamptz, timestamptz, timestamptz) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.quota_snapshot(uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.consume_quota(uuid, public.usage_feature) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.release_quota(uuid, public.usage_feature, public.quota_period, timestamptz) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.get_quota_snapshot() FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.consume_quota(uuid, public.usage_feature) TO service_role;
GRANT EXECUTE ON FUNCTION public.release_quota(uuid, public.usage_feature, public.quota_period, timestamptz) TO service_role;
GRANT EXECUTE ON FUNCTION public.get_quota_snapshot() TO authenticated;

DELETE FROM public.user_daily_usage;

SELECT cron.unschedule('cleanup-old-feature-usage')
WHERE EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'cleanup-old-feature-usage');

SELECT cron.schedule(
  'cleanup-old-feature-usage',
  '0 3 * * *',
  $$ DELETE FROM public.feature_usage WHERE window_end < now() - interval '30 days' $$
);
