import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/config/env.dart';
import 'package:tryzeon/core/data/utils/decode_function_response.dart';
import 'package:tryzeon/core/error/exceptions.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/personal/chat/data/dtos/chat_request.dart';
import 'package:tryzeon/feature/personal/chat/data/dtos/chat_stream_event_dto.dart';

class ChatRemoteDataSource {
  ChatRemoteDataSource(this._supabase, this._dio);

  final SupabaseClient _supabase;
  final Dio _dio;
  static const _chatFunction = 'chat';

  /// Rate-limit and other run failures arrive in-stream as an error event; a
  /// non-200 status is auth/bad-request only.
  Stream<ChatStreamEventDto> sendMessageStream(
    final ChatRequest request,
  ) async* {
    final url = '${Env.supabaseUrl}/functions/v1/$_chatFunction';
    final accessToken = _supabase.auth.currentSession?.accessToken ?? '';

    final response = await _dio.post<ResponseBody>(
      url,
      data: jsonEncode(request.toJson()),
      options: Options(
        responseType: ResponseType.stream,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'apikey': Env.supabaseAnonKey,
          'Content-Type': 'application/json',
        },
        validateStatus: (final _) => true,
      ),
    );

    if ((response.statusCode ?? 0) != 200) {
      throw ServerException('Chat request failed: ${response.statusCode}');
    }

    // ResponseBody.stream is Stream<Uint8List>; Uint8List implements List<int>
    // so .cast<List<int>>() is a sound covariant cast that satisfies utf8.decoder's
    // StreamTransformer<List<int>, String> input type.
    final lines = response.data!.stream
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter());
    await for (final line in lines) {
      if (line.trim().isEmpty) continue;
      yield _decodeLine(line);
    }
  }

  ChatStreamEventDto _decodeLine(final String line) {
    final Object? json;
    try {
      json = jsonDecode(line);
    } on FormatException catch (e, stackTrace) {
      AppLogger.warning('Malformed chat stream line', e, stackTrace);
      throw const ServerException();
    }
    return decodeFunctionResponse(json, ChatStreamEventDto.fromJson);
  }
}
