import 'package:tryzeon/core/error/api_error_code.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/common/daily_usage/data/mappers/daily_usage_payload.dart';
import 'package:tryzeon/feature/personal/chat/data/datasources/chat_remote_data_source.dart';
import 'package:tryzeon/feature/personal/chat/data/dtos/chat_answer_dto.dart';
import 'package:tryzeon/feature/personal/chat/data/dtos/chat_message_dto.dart';
import 'package:tryzeon/feature/personal/chat/data/dtos/chat_request.dart';
import 'package:tryzeon/feature/personal/chat/data/dtos/chat_stream_event_dto.dart';
import 'package:tryzeon/feature/personal/chat/data/mappers/chat_mappr.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/chat_message.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/chat_stream_event.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/content_block.dart';
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
    ChatDoneEventDto(:final message, :final usage) => ChatStreamEvent.replied(
      answer: _mappr.convert<ChatAnswerDto, ChatMessage>(message),
      usage: tryParseDailyUsagePayload(usage),
    ),
    ChatErrorEventDto(:final code, :final message, :final usage) =>
      ChatStreamEvent.failed(switch (code) {
        ApiErrorCode.rateLimitExceeded => RateLimitFailure(
          usage: tryParseDailyUsagePayload(usage),
        ),
        ApiErrorCode.serviceBusy => const ServiceBusyFailure(),
        ApiErrorCode.validation => ValidationFailure(message),
        _ => const ServerFailure(),
      }),
    ChatUnknownEventDto() => null,
  };
}
