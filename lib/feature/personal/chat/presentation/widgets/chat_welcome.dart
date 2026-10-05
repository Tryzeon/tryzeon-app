import 'package:flutter/material.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/core/theme/app_theme.dart';

class ChatWelcome extends StatelessWidget {
  const ChatWelcome({
    super.key,
    required this.showStarters,
    required this.minHeight,
    required this.onPromptTap,
  });

  final bool showStarters;
  final double minHeight;
  final ValueChanged<String> onPromptTap;

  static const List<String> _starters = [
    '上班約會穿搭',
    '週末休閒風',
    '幫我搭一件白襯衫',
    '參加婚禮要穿什麼',
  ];

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final intro = Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(
            AppConstants.logoMark,
            width: AppSpacing.xl,
            height: AppSpacing.xl,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('今天想怎麼穿？', style: textTheme.headlineLarge),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '告訴我場合、風格或想搭配的單品，我會從你的衣櫃和商店幫你配好整套。',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );

    return AnimatedSize(
      duration: AppDuration.slow,
      curve: AppCurves.emphasized,
      alignment: Alignment.topCenter,
      child: showStarters
          ? ConstrainedBox(
              constraints: BoxConstraints(minHeight: minHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    intro,
                    const SizedBox(height: AppSpacing.xl),
                    _StarterList(starters: _starters, onTap: onPromptTap),
                  ],
                ),
              ),
            )
          : intro,
    );
  }
}

class _StarterList extends StatelessWidget {
  const _StarterList({required this.starters, required this.onTap});

  final List<String> starters;
  final ValueChanged<String> onTap;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'TRY ASKING',
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        for (final starter in starters) ...[
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(starter, style: theme.textTheme.bodyLarge),
            trailing: Icon(
              Icons.arrow_forward_rounded,
              size: AppSpacing.md,
              color: colorScheme.onSurfaceVariant,
            ),
            onTap: () => onTap(starter),
          ),
          if (starter != starters.last) const Divider(),
        ],
      ],
    );
  }
}
