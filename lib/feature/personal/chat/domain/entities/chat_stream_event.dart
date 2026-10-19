import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/chat_items.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/chat_message.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/content_block.dart';

part 'chat_stream_event.freezed.dart';

/// Search steps stream live ([ChatToolStarted]/[ChatToolFinished]) as progress
/// only; the run ends with exactly one terminal event — [ChatReplied], which
/// carries the turn's messages as the server recorded them, or [ChatFailed].
@freezed
sealed class ChatStreamEvent with _$ChatStreamEvent {
  const factory ChatStreamEvent.toolStarted(final ToolUseBlock block) =
      ChatToolStarted;
  const factory ChatStreamEvent.toolFinished(final ToolResultBlock block) =
      ChatToolFinished;
  const factory ChatStreamEvent.replied({
    required final List<ChatMessage> messages,
    required final ChatItems items,
  }) = ChatReplied;
  const factory ChatStreamEvent.failed(final Failure failure) = ChatFailed;
}
