import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/common/clothing_style/entities/clothing_style.dart';

import '../providers/onboarding_notifier.dart';

class StylePreferenceStep extends HookConsumerWidget {
  const StylePreferenceStep({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final onboardingState = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.smMd),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.smMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('你喜歡的風格', style: textTheme.headlineMedium),
                const SizedBox(height: AppSpacing.sm),
                Text('可多選，也可以略過', style: textTheme.bodyMedium),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.mdLg,
              ),
              itemCount: ClothingStyle.values.length,
              itemBuilder: (final context, final index) {
                final style = ClothingStyle.values[index];
                final isSelected = onboardingState.stylePreferences.contains(style);

                return GestureDetector(
                  onTap: () => notifier.toggleStylePreference(style),
                  child: Column(
                    children: [
                      Expanded(
                        child: AnimatedContainer(
                          duration: AppDuration.standard,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isSelected
                                  ? colorScheme.primary
                                  : colorScheme.outline.withValues(
                                      alpha: AppOpacity.strong,
                                    ),
                              width: isSelected ? AppStroke.regular : AppStroke.thin,
                            ),
                            borderRadius: AppRadius.cardAll,
                          ),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: AppRadius.inputAll,
                                child: Image.asset(
                                  'assets/images/onboarding/${style.value}.webp',
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                  errorBuilder:
                                      (final context, final error, final stackTrace) {
                                        return Container(
                                          color: colorScheme.surfaceContainerHighest,
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.image_not_supported_outlined,
                                                color: colorScheme.outline,
                                                size: 32,
                                              ),
                                              const SizedBox(height: AppSpacing.xs),
                                              Text(
                                                style.value,
                                                style: textTheme.labelSmall,
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                ),
                              ),
                              if (isSelected)
                                Positioned(
                                  top: AppSpacing.sm,
                                  right: AppSpacing.sm,
                                  child: Container(
                                    padding: const EdgeInsets.all(AppSpacing.xs),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.check_rounded,
                                      color: colorScheme.onPrimary,
                                      size: 16,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        style.label,
                        style: textTheme.bodySmall?.copyWith(
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
