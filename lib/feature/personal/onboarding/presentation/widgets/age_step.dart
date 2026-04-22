import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../providers/onboarding_notifier.dart';

class AgeStep extends HookConsumerWidget {
  const AgeStep({super.key});

  static const _minAge = 4;
  static const _maxAge = 100;
  static const _defaultAge = 25;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final notifier = ref.read(onboardingProvider.notifier);

    final controller = useFixedExtentScrollController(initialItem: _defaultAge - _minAge);

    useEffect(() {
      Future.microtask(() => notifier.setAge(_defaultAge));
      return null;
    }, const []);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Text('你的年齡', style: textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text('請選擇你的年齡', style: textTheme.bodyMedium),
          const SizedBox(height: 32),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 300,
                  child: CupertinoPicker(
                    scrollController: controller,
                    itemExtent: 48,
                    onSelectedItemChanged: (final index) {
                      notifier.setAge(_minAge + index);
                    },
                    selectionOverlay: CupertinoPickerDefaultSelectionOverlay(
                      background: colorScheme.primaryContainer.withValues(alpha: 0.3),
                    ),
                    children: List.generate(
                      _maxAge - _minAge + 1,
                      (final i) => Center(
                        child: Text('${_minAge + i}', style: textTheme.headlineSmall),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('歲', style: textTheme.titleLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
