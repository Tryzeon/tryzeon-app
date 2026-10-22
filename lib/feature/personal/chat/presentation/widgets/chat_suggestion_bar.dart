import 'package:flutter/material.dart';
import 'package:tryzeon/core/theme/app_theme.dart';

class ChatSuggestionBar extends StatelessWidget {
  const ChatSuggestionBar({
    super.key,
    required this.suggestions,
    required this.onTap,
  });

  final List<String> suggestions;
  final ValueChanged<String> onTap;

  @override
  Widget build(final BuildContext context) => AnimatedSize(
    duration: AppDuration.standard,
    curve: AppCurves.standard,
    alignment: Alignment.bottomCenter,
    child: suggestions.isEmpty
        ? const SizedBox(width: double.infinity)
        : SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Row(
              spacing: AppSpacing.sm,
              children: [
                for (final suggestion in suggestions)
                  ActionChip(
                    label: Text(suggestion),
                    onPressed: () => onTap(suggestion),
                  ),
              ],
            ),
          ),
  );
}
