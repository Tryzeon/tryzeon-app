import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:tryzeon/core/theme/app_theme.dart';

class ChatInputBar extends HookWidget {
  const ChatInputBar({
    super.key,
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  static const double _buttonSize = AppSpacing.xl + AppSpacing.xs;
  static const double _inset = AppSpacing.xs;
  static const double _minHeight = _buttonSize + _inset * 2;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textStyle = theme.textTheme.bodyLarge;

    final focusNode = useFocusNode();
    final hasFocus = useListenableSelector(focusNode, () => focusNode.hasFocus);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: AnimatedContainer(
        duration: AppDuration.standard,
        curve: AppCurves.standard,
        constraints: const BoxConstraints(minHeight: _minHeight),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          _inset,
          _inset,
          _inset,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(_minHeight / 2),
          border: Border.all(
            color: hasFocus ? colorScheme.onSurface : colorScheme.outline,
            width: AppStroke.thin,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                minLines: 1,
                maxLines: 5,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.send,
                onSubmitted: (final _) => onSend(),
                style: textStyle,
                decoration: InputDecoration(
                  hintText: '想找什麼、想怎麼搭？告訴我',
                  hintStyle: textStyle?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  filled: false,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.sm,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            SizedBox.square(
              dimension: _buttonSize,
              child: _SendButton(
                controller: controller,
                isSending: isSending,
                onSend: onSend,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final style = IconButton.styleFrom(
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      disabledBackgroundColor: colorScheme.surfaceContainerHigh,
      disabledForegroundColor: colorScheme.onSurfaceVariant,
      shape: const CircleBorder(),
      padding: EdgeInsets.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      animationDuration: AppDuration.standard,
    );

    if (isSending) {
      return IconButton.filled(
        onPressed: null,
        style: style,
        icon: SizedBox.square(
          dimension: AppSpacing.md,
          child: CircularProgressIndicator(
            strokeWidth: AppStroke.regular,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return ListenableBuilder(
      listenable: controller,
      builder: (final context, final _) => IconButton.filled(
        onPressed: controller.text.trim().isNotEmpty ? onSend : null,
        style: style,
        tooltip: '送出',
        icon: const Icon(Icons.arrow_upward_rounded, size: AppSpacing.mdLg),
      ),
    );
  }
}
