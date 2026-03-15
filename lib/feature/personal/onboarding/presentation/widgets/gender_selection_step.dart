import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/gender.dart';

import '../providers/onboarding_notifier.dart';

class GenderSelectionStep extends HookConsumerWidget {
  const GenderSelectionStep({super.key});

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
          const SizedBox(height: 10),
          Text('你的性別', style: textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text('選擇一個選項', style: textTheme.bodyMedium),
          const SizedBox(height: 24),
          ...Gender.values.map(
            (final gender) => RadioListTile<Gender>(
              title: Text(gender.label),
              value: gender,
              // ignore: deprecated_member_use
              groupValue: onboardingState.gender,
              // ignore: deprecated_member_use
              onChanged: (final value) {
                if (value != null) notifier.setGender(value);
              },
            ),
          ),
        ],
      ),
    );
  }
}
