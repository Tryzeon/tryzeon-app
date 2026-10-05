import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/chat/data/chat_wire.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/chat_stream_event.dart';

void main() {
  group('parseStreamLine error events', () {
    test('SERVICE_BUSY maps to ServiceBusyFailure', () {
      expect(
        parseStreamLine(jsonEncode({'type': 'error', 'code': 'SERVICE_BUSY'})),
        const ChatStreamEvent.failed(ServiceBusyFailure()),
      );
    });

    test('VALIDATION_ERROR keeps the backend message', () {
      expect(
        parseStreamLine(
          jsonEncode({
            'type': 'error',
            'code': 'VALIDATION_ERROR',
            'message': '太長',
          }),
        ),
        const ChatStreamEvent.failed(ValidationFailure('太長')),
      );
    });

    test('RATE_LIMIT_EXCEEDED carries the usage payload', () {
      final usage = {'used': 10, 'limit': 10};
      expect(
        parseStreamLine(
          jsonEncode({
            'type': 'error',
            'code': 'RATE_LIMIT_EXCEEDED',
            'usage': usage,
          }),
        ),
        ChatStreamEvent.failed(RateLimitFailure(usagePayload: usage)),
      );
    });

    test('an unknown code maps to ServerFailure', () {
      expect(
        parseStreamLine(
          jsonEncode({'type': 'error', 'code': 'SOMETHING_ELSE'}),
        ),
        const ChatStreamEvent.failed(ServerFailure()),
      );
    });
  });
}
