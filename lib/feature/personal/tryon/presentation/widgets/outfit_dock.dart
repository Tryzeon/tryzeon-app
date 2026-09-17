import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/core/router/app_routes.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/actions/outfit_actions.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/state/outfit_tray_controller.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/widgets/outfit_slot.dart';

class OutfitDock extends HookConsumerWidget {
  const OutfitDock({super.key, required this.isVisible});

  static const double reservedHeight = 112;
  static const Duration _capMessageDuration = Duration(seconds: 2);

  final bool isVisible;

  static bool isHostedAt(final String location) =>
      location.startsWith(AppRoutes.personalShop) ||
      location.startsWith(AppRoutes.personalWardrobe);

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final tray = ref.watch(outfitTrayProvider);
    final notifier = ref.read(outfitTrayProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    final shake = useAnimationController(duration: AppDuration.slow);
    final capShownAt = useState<DateTime?>(null);

    ref.listen(outfitTrayProvider.select((final s) => s.rejectedCount), (
      final prev,
      final next,
    ) {
      if (prev == null || next <= prev) return;
      HapticFeedback.heavyImpact();
      if (!reduceMotion) shake.forward(from: 0);
      capShownAt.value = DateTime.now();
    });

    useEffect(() {
      if (capShownAt.value == null) return null;
      final timer = Timer(_capMessageDuration, () => capShownAt.value = null);
      return timer.cancel;
    }, [capShownAt.value]);

    final shown = isVisible && tray.isOpen;

    final message = capShownAt.value != null
        ? '已滿 ${AppConstants.maxTryonGarments} 件，先移除一件'
        : tray.pieces.isEmpty
        ? '點選衣物加入搭配，最多 ${AppConstants.maxTryonGarments} 件'
        : null;

    void launch() =>
        triggerOutfitTryon(context, ref, tray.pieces, beforeLaunch: notifier.launch);

    final slots = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < AppConstants.maxTryonGarments; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.sm),
          OutfitSlot(
            index: i,
            piece: i < tray.pieces.length ? tray.pieces[i] : null,
            kind: i < tray.pieces.length
                ? OutfitSlotKind.filled
                : i == tray.pieces.length
                ? OutfitSlotKind.next
                : OutfitSlotKind.later,
            onRemove: notifier.remove,
          ),
        ],
      ],
    );

    final dock = Material(
      key: const Key('outfit-dock'),
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.cardAll,
        side: BorderSide(color: colorScheme.outline, width: AppStroke.thin),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.smMd,
          vertical: AppSpacing.sm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedSize(
              duration: AppDuration.standard,
              curve: AppCurves.standard,
              alignment: Alignment.topLeft,
              child: message == null
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: Text(
                        message,
                        key: const Key('outfit-dock-message'),
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
            ),
            Row(
              children: [
                slots,
                const Spacer(),
                IconButton(
                  key: const Key('outfit-dock-clear'),
                  tooltip: '清除搭配',
                  icon: const Icon(Icons.close_rounded),
                  onPressed: notifier.close,
                ),
                FilledButton.icon(
                  key: const Key('outfit-dock-launch'),
                  onPressed: tray.pieces.isEmpty ? null : launch,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('試穿'),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    return AnimatedSwitcher(
      duration: reduceMotion ? Duration.zero : AppDuration.standard,
      switchInCurve: AppCurves.enter,
      switchOutCurve: AppCurves.exit,
      transitionBuilder: (final child, final animation) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.15),
          end: Offset.zero,
        ).animate(animation),
        child: FadeTransition(opacity: animation, child: child),
      ),
      child: !shown
          ? const SizedBox.shrink()
          : AnimatedBuilder(
              animation: shake,
              builder: (final _, final child) => Transform.translate(
                offset: Offset(
                  math.sin(shake.value * math.pi * 3 * 2) * AppSpacing.xs,
                  0,
                ),
                child: child,
              ),
              child: dock,
            ),
    );
  }
}
