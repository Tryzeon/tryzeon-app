import 'dart:math' as math;

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/extensions/failure_extension.dart';
import 'package:tryzeon/core/presentation/dialogs/upgrade_dialog.dart';
import 'package:tryzeon/core/presentation/widgets/top_notification.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/chat_message.dart';
import 'package:tryzeon/feature/personal/chat/presentation/constants/qa_config.dart';
import 'package:tryzeon/feature/personal/chat/presentation/widgets/chat_bubble.dart';
import 'package:tryzeon/feature/personal/chat/presentation/widgets/chat_header.dart';
import 'package:tryzeon/feature/personal/chat/presentation/widgets/chat_input_bar.dart';
import 'package:tryzeon/feature/personal/chat/presentation/widgets/chat_progress_bar.dart';
import 'package:tryzeon/feature/personal/chat/presentation/widgets/chat_quick_reply_row.dart';
import 'package:tryzeon/feature/personal/chat/presentation/widgets/chat_skeleton_bubble.dart';
import 'package:tryzeon/feature/personal/chat/providers/chat_providers.dart';
import 'package:typed_result/typed_result.dart';

// ChatPage widget
class ChatPage extends HookConsumerWidget {
  const ChatPage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final messages = useState<List<ChatMessage>>([]);
    final controller = useTextEditingController();
    final scrollController = useScrollController();
    final currentQuestionIndex = useState(0);
    final answers = useState<Map<String, String>>({});
    final isWaitingForAnswer = useState(true);
    final isLoadingRecommendation = useState(false);

    void scrollToBottom() {
      Future.delayed(AppDuration.slow, () {
        if (context.mounted && scrollController.hasClients) {
          scrollController.animateTo(
            scrollController.position.maxScrollExtent,
            duration: AppDuration.slow,
            curve: AppCurves.enter,
          );
        }
      });
    }

    Future<void> getLLMRecommendation() async {
      if (!context.mounted) return;

      isLoadingRecommendation.value = true;
      scrollToBottom();

      // 使用 Use Case 獲取 LLM 建議
      final getLLMRecommendation = ref.read(getLLMRecommendationUseCaseProvider);
      final result = await getLLMRecommendation(answers.value);

      if (!context.mounted) return;

      isLoadingRecommendation.value = false;

      if (result.isSuccess) {
        // Add LLM response
        messages.value = [
          ...messages.value,
          ChatMessage(text: result.get()!, isUser: false),
        ];
      } else {
        // Show error message
        final failure = result.getError()!;
        if (failure is RateLimitFailure) {
          UpgradeDialog.show(
            context,
            title: '顧問對話已達上限',
            content: '您的今日對話次數已達上限\n升級至更高方案以獲得更多次數！',
          );
        } else {
          TopNotification.show(
            context,
            message: failure.displayMessage(context),
            type: NotificationType.error,
          );
        }
      }

      scrollToBottom();
    }

    void showSummary() {
      isWaitingForAnswer.value = false;
      getLLMRecommendation();
    }

    void askNextQuestion() {
      if (currentQuestionIndex.value < QAConfig.questions.length) {
        final question = QAConfig.questions[currentQuestionIndex.value];
        messages.value = [
          ...messages.value,
          ChatMessage(text: question.text, isUser: false, questionId: question.id),
        ];
        isWaitingForAnswer.value = true;
        scrollToBottom();
      } else {
        showSummary();
      }
    }

    void handleAnswer(final String answer, final String questionId) {
      if (!isWaitingForAnswer.value) return;

      messages.value = [...messages.value, ChatMessage(text: answer, isUser: true)];
      answers.value = {...answers.value, questionId: answer};
      isWaitingForAnswer.value = false;
      currentQuestionIndex.value++;
      scrollToBottom();

      Future.delayed(AppDuration.quick, () {
        if (context.mounted) {
          askNextQuestion();
        }
      });
    }

    void sendMessage(final String text) {
      if (text.trim().isEmpty || !isWaitingForAnswer.value) return;

      final currentQuestion = currentQuestionIndex.value < QAConfig.questions.length
          ? QAConfig.questions[currentQuestionIndex.value]
          : null;

      if (currentQuestion != null) {
        handleAnswer(text, currentQuestion.id);
      }

      controller.clear();
    }

    void resetChat() {
      messages.value = [];
      currentQuestionIndex.value = 0;
      answers.value = {};
      isWaitingForAnswer.value = true;
      isLoadingRecommendation.value = false;

      messages.value = [const ChatMessage(text: '你好，今天想怎麼穿呢？', isUser: false)];
      askNextQuestion();
    }

    useEffect(() {
      messages.value = [const ChatMessage(text: '你好，今天想怎麼穿呢？', isUser: false)];
      askNextQuestion();
      return null;
    }, []);

    final mediaQuery = MediaQuery.of(context);
    final keyboardHeight = mediaQuery.viewInsets.bottom;
    final isKeyboardOpen = keyboardHeight > 0;
    final safeAreaBottom = mediaQuery.viewPadding.bottom;

    final currentQuestion = currentQuestionIndex.value < QAConfig.questions.length
        ? QAConfig.questions[currentQuestionIndex.value]
        : null;

    final List<String> currentReplies =
        (isWaitingForAnswer.value && currentQuestion != null)
        ? currentQuestion.quickReplies
        : [];

    final isIOS26 = PlatformInfo.isIOS26OrHigher();

    final bodyBottomOffset = isIOS26
        ? 0.0
        : PlatformInfo.isIOS
        ? 50.0 + safeAreaBottom
        : 80.0;

    final restingSpacing = isIOS26
        ? safeAreaBottom + 50.0 + AppSpacing.sm
        : AppSpacing.sm;

    final bottomSpacing = isKeyboardOpen
        ? math.max(restingSpacing, keyboardHeight - bodyBottomOffset)
        : restingSpacing;

    return Material(
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ChatHeader(
              onRefresh: () async {
                final result = await showOkCancelAlertDialog(
                  context: context,
                  message: '你確定要重設整個對話嗎？',
                  okLabel: '確定',
                  cancelLabel: '取消',
                  isDestructiveAction: true,
                );

                if (result == OkCancelResult.ok) {
                  resetChat();
                }
              },
            ),
            ChatProgressBar(
              currentQuestionIndex: currentQuestionIndex.value,
              totalQuestions: QAConfig.questions.length,
              isVisible:
                  isWaitingForAnswer.value &&
                  currentQuestionIndex.value < QAConfig.questions.length,
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount:
                      messages.value.length + (isLoadingRecommendation.value ? 1 : 0),
                  itemBuilder: (final context, final index) {
                    if (index == messages.value.length) {
                      return const ChatSkeletonBubble();
                    }
                    return ChatBubble(message: messages.value[index]);
                  },
                ),
              ),
            ),
            if (currentReplies.isNotEmpty)
              ChatQuickReplyRow(
                replies: currentReplies,
                onReply: (final reply) {
                  if (currentQuestion != null) {
                    handleAnswer(reply, currentQuestion.id);
                  }
                },
              ),
            ChatInputBar(
              controller: controller,
              isLoading: isLoadingRecommendation.value,
              onSend: () => sendMessage(controller.text),
            ),
            SizedBox(height: bottomSpacing),
          ],
        ),
      ),
    );
  }
}
