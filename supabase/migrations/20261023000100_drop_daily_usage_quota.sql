-- Retire the daily-usage quota model that 20261019000000_billing_cycle_quota
-- kept alive for older app builds.

SELECT cron.unschedule('cleanup-old-daily-usage')
WHERE EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'cleanup-old-daily-usage');

DROP FUNCTION public.cleanup_old_daily_usage();
DROP FUNCTION public.increment_feature_usage(uuid, text);
DROP FUNCTION public.decrement_feature_usage(uuid, text);

DROP TABLE public.user_daily_usage;

ALTER TABLE public.subscription_tiers
  DROP COLUMN tryon_limit,
  DROP COLUMN video_limit,
  DROP COLUMN chat_limit;
