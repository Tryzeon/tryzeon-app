import 'package:tryzeon/core/data/errors/api_error_code.dart';
import 'package:tryzeon/core/data/errors/map_exception_to_failure.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/personal/chat/data/datasources/chat_remote_data_source.dart';
import 'package:tryzeon/feature/personal/chat/data/dtos/chat_items_dto.dart';
import 'package:tryzeon/feature/personal/chat/data/dtos/chat_message_dto.dart';
import 'package:tryzeon/feature/personal/chat/data/dtos/chat_request.dart';
import 'package:tryzeon/feature/personal/chat/data/dtos/chat_stream_event_dto.dart';
import 'package:tryzeon/feature/personal/chat/data/mappers/chat_mappr.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/chat_items.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/chat_message.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/chat_stream_event.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/content_block.dart';
import 'package:tryzeon/feature/personal/chat/domain/failures/chat_rate_limited_failure.dart';
import 'package:tryzeon/feature/personal/chat/domain/repositories/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl({required final ChatRemoteDataSource remoteDataSource})
    : _remoteDataSource = remoteDataSource;
  final ChatRemoteDataSource _remoteDataSource;

  static const _mappr = ChatMappr();

  @override
  Stream<ChatStreamEvent> sendMessageStream(
    final List<ChatMessage> history,
  ) async* {
    final request = ChatRequest(
      messages: [
        for (final message in history)
          _mappr.convert<ChatMessage, ChatMessageDto>(message),
      ],
    );
    try {
      await for (final dto in _remoteDataSource.sendMessageStream(request)) {
        final event = _toEvent(dto);
        if (event != null) yield event;
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to stream chat message', e, stackTrace);
      yield ChatStreamEvent.failed(mapExceptionToFailure(e));
    }
  }

  ChatStreamEvent? _toEvent(final ChatStreamEventDto dto) => switch (dto) {
    ChatToolUseEventDto() => ChatStreamEvent.toolStarted(
      _mappr.convert<ChatToolUseEventDto, ToolUseBlock>(dto),
    ),
    ChatToolResultEventDto() => ChatStreamEvent.toolFinished(
      _mappr.convert<ChatToolResultEventDto, ToolResultBlock>(dto),
    ),
    ChatDoneEventDto(:final messages, :final items) => ChatStreamEvent.replied(
      messages: [
        for (final message in messages)
          _mappr.convert<ChatMessageDto, ChatMessage>(message),
      ],
      items: _mappr.convert<ChatItemsDto, ChatItems>(items),
    ),
    ChatErrorEventDto(:final code, :final message) => ChatStreamEvent.failed(
      switch (code) {
        ApiErrorCode.rateLimitExceeded => const ChatRateLimitedFailure(),
        ApiErrorCode.serviceBusy => const ServiceBusyFailure(),
        ApiErrorCode.validation => ValidationFailure(message),
        _ => const ServerFailure(),
      },
    ),
    ChatUnknownEventDto() => null,
  };
}
