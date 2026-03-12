import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/age_range.dart';

import '../providers/onboarding_notifier.dart';

class AgeRangeStep extends HookConsumerWidget {
  const AgeRangeStep({super.key});

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
          Text('你的年齡範圍', style: textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text('請選擇一個區間', style: textTheme.bodyMedium),
          const SizedBox(height: 24),
          ...AgeRange.values.map(
            (final ageRange) => RadioListTile<AgeRange>(
              title: Text(ageRange.label),
              value: ageRange,
              // ignore: deprecated_member_use
              groupValue: onboardingState.ageRange,
              // ignore: deprecated_member_use
              onChanged: (final value) {
                if (value != null) {
                  notifier.setAgeRange(value);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
