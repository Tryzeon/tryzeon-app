import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/style_preference.dart';

import '../providers/onboarding_notifier.dart';

class StylePreferenceStep extends HookConsumerWidget {
  const StylePreferenceStep({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final onboardingState = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text('你喜歡的風格', style: textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text('可多選，也可以略過', style: textTheme.bodyMedium),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: StylePreference.values.map((final style) {
              final isSelected = onboardingState.stylePreferences.contains(style);
              return FilterChip(
                label: Text(style.label),
                selected: isSelected,
                onSelected: (final _) => notifier.toggleStylePreference(style),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
