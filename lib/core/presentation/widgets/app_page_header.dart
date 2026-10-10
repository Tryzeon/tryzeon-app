import 'package:flutter/material.dart';
import 'package:tryzeon/core/theme/app_theme.dart';

class AppPageHeader extends StatelessWidget {
  const AppPageHeader({
    super.key,
    required this.title,
    this.titleTrailing,
    this.action,
  });

  final String title;
  final Widget? titleTrailing;
  final Widget? action;

  @override
  Widget build(final BuildContext context) {
    final titleTrailing = this.titleTrailing;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.smMd,
        AppSpacing.sm,
      ),
      child: SizedBox(
        height: kMinInteractiveDimension,
        child: Row(
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Flexible(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.headlineLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (titleTrailing != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    titleTrailing,
                  ],
                ],
              ),
            ),
            ?action,
          ],
        ),
      ),
    );
  }
}
