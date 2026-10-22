import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tryzeon/feature/personal/chat/presentation/state/chat_timeline.dart';
import 'package:tryzeon/feature/personal/chat/providers/chat_notifier.dart';

part 'chat_suggestions.g.dart';

@riverpod
List<String> chatSuggestions(final Ref ref) {
  final state = ref.watch(chatProvider);
  if (state.isLoading || state.suggestions.isEmpty) return const [];
  final latest = ref.watch(chatTimelineProvider).last;
  return latest is ChatAssistantEntry &&
          !latest.segments.any((final s) => s is ChatEmptyAnswerSegment)
      ? state.suggestions
      : const [];
}
