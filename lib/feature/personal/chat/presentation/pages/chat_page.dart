import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/presentation/dialogs/upgrade_dialog.dart';
import 'package:tryzeon/core/presentation/widgets/app_confirm_dialog.dart';
import 'package:tryzeon/core/presentation/widgets/app_keyboard_dismisser.dart';
import 'package:tryzeon/core/router/shells/personal_tab.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/personal/chat/presentation/state/chat_timeline.dart';
import 'package:tryzeon/feature/personal/chat/presentation/widgets/chat_header.dart';
import 'package:tryzeon/feature/personal/chat/presentation/widgets/chat_input_bar.dart';
import 'package:tryzeon/feature/personal/chat/presentation/widgets/chat_jump_to_latest_button.dart';
import 'package:tryzeon/feature/personal/chat/presentation/widgets/chat_timeline_list.dart';
import 'package:tryzeon/feature/personal/chat/providers/chat_event.dart';
import 'package:tryzeon/feature/personal/chat/providers/chat_notifier.dart';

class ChatPage extends HookConsumerWidget {
  const ChatPage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final entries = ref.watch(chatTimelineProvider);
    final isLoading = ref.watch(chatProvider.select((final s) => s.isLoading));
    final isPristine = ref.watch(
      chatProvider.select((final s) => s.isPristine),
    );
    final notifier = ref.watch(chatProvider.notifier);

    final controller = useTextEditingController();
    final scrollController = useScrollController();
    final showJump = useState(false);

    useEffect(() {
      void updateJumpVisibility() {
        showJump.value =
            scrollController.offset > ChatTimelineList.jumpThreshold;
      }

      scrollController.addListener(updateJumpVisibility);
      return () => scrollController.removeListener(updateJumpVisibility);
    }, [scrollController]);

    bool isNearLatest() =>
        !scrollController.hasClients ||
        scrollController.offset <= ChatTimelineList.jumpThreshold;

    void scrollToLatest({final Curve curve = AppCurves.enter}) {
      if (!scrollController.hasClients) return;
      scrollController.animateTo(0, duration: AppDuration.slow, curve: curve);
    }

    void scrollToLatestAfterLayout() {
      WidgetsBinding.instance.addPostFrameCallback(
        (final _) => scrollToLatest(),
      );
    }

    void showUpgrade() {
      UpgradeDialog.show(
        context,
        title: '對話次數已達上限',
        content: '今天的對話次數已達上限\n升級方案就能繼續聊呦！',
      );
    }

    ref.listen(chatTimelineProvider.select((final e) => e.length), (
      final previous,
      final next,
    ) {
      if (previous != null && next > previous && isNearLatest()) {
        scrollToLatestAfterLayout();
      }
    });

    ref.listen(chatProvider.select((final s) => s.isLoading), (
      final previous,
      final next,
    ) {
      if (previous == true && !next && isNearLatest()) {
        scrollToLatestAfterLayout();
      }
    });

    ref.listen(personalTabReselectSignalProvider, (final _, final next) {
      if (next?.tab != PersonalTab.chat) return;
      if (!scrollController.hasClients || scrollController.offset <= 0) return;
      scrollToLatest(curve: AppCurves.emphasized);
    });

    useEffect(() {
      final subscription = notifier.events.listen((final event) {
        if (!context.mounted) return;
        switch (event) {
          case ChatRateLimited():
            showUpgrade();
        }
      });
      return subscription.cancel;
    }, [notifier]);

    void sendMessage(final String text) {
      final trimmed = text.trim();
      if (trimmed.isEmpty || ref.read(chatProvider).isLoading) return;
      HapticFeedback.lightImpact();
      controller.clear();
      FocusScope.of(context).unfocus();
      notifier.sendMessage(trimmed);
      scrollToLatest();
    }

    Future<void> confirmReset() async {
      final result = await showAppOkCancelDialog(
        context: context,
        message: '要開始新的對話嗎？目前的內容會被清除',
        okLabel: '開始新對話',
        cancelLabel: '取消',
        isDestructiveAction: true,
      );
      if (result != OkCancelResult.ok) return;
      notifier.reset();
      controller.clear();
    }

    final mediaQuery = MediaQuery.of(context);
    final keyboardHeight = mediaQuery.viewInsets.bottom;
    final restingSpacing =
        mediaQuery.viewPadding.bottom +
        AppSpacing.bottomNavBarOverlap +
        AppSpacing.sm;
    final bottomSpacing = keyboardHeight > 0
        ? math.max(restingSpacing, keyboardHeight)
        : restingSpacing;

    return AppKeyboardDismisser(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              ChatHeader(canReset: !isPristine, onReset: confirmReset),
              Expanded(
                child: Stack(
                  children: [
                    ChatTimelineList(
                      entries: entries,
                      controller: scrollController,
                      onStarterTap: sendMessage,
                      onRetry: notifier.retry,
                      onUpgrade: showUpgrade,
                    ),
                    Positioned(
                      bottom: AppSpacing.sm,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: ChatJumpToLatestButton(
                          visible: showJump.value,
                          onTap: scrollToLatest,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ChatInputBar(
                controller: controller,
                isSending: isLoading,
                onSend: () => sendMessage(controller.text),
              ),
              SizedBox(height: bottomSpacing),
            ],
          ),
        ),
      ),
    );
  }
}
