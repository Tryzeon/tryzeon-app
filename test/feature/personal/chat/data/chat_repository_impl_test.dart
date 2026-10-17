import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/core/data/utils/decode_function_response.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/common/daily_usage/domain/entities/daily_usage.dart';
import 'package:tryzeon/feature/common/daily_usage/domain/failures/usage_limit_failure.dart';
import 'package:tryzeon/feature/personal/chat/data/datasources/chat_remote_data_source.dart';
import 'package:tryzeon/feature/personal/chat/data/dtos/chat_request.dart';
import 'package:tryzeon/feature/personal/chat/data/dtos/chat_stream_event_dto.dart';
import 'package:tryzeon/feature/personal/chat/data/repositories/chat_repository_impl.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/chat_items.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/chat_message.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/chat_stream_event.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/content_block.dart';

class _FakeChatRemoteDataSource implements ChatRemoteDataSource {
  _FakeChatRemoteDataSource(this.events);

  final List<Map<String, dynamic>> events;
  ChatRequest? sentRequest;

  @override
  Stream<ChatStreamEventDto> sendMessageStream(
    final ChatRequest request,
  ) async* {
    sentRequest = request;
    for (final event in events) {
      yield decodeFunctionResponse(event, ChatStreamEventDto.fromJson);
    }
  }
}

final _usageJson = {
  'user_id': 'u1',
  'usage_date': '2026-10-11',
  'tryon_count': 0,
  'chat_count': 10,
  'video_count': 0,
};

final _usage = DailyUsage(
  userId: 'u1',
  usageDate: DateTime(2026, 10, 11),
  tryonCount: 0,
  chatCount: 10,
  videoCount: 0,
);

final _wardrobeRow = {
  'id': 'w1',
  'image_path': 'u1/w1.jpg',
  'garment_type': 'top',
  'tags': ['casual'],
  'created_at': '2026-01-01T00:00:00Z',
  'updated_at': '2026-01-01T00:00:00Z',
};

void main() {
  Future<List<ChatStreamEvent>> run(
    final List<Map<String, dynamic>> events, {
    final List<ChatMessage> history = const [],
  }) => ChatRepositoryImpl(
    remoteDataSource: _FakeChatRemoteDataSource(events),
  ).sendMessageStream(history).toList();

  test('sends the transcript in its wire shape, items by id', () async {
    final dataSource = _FakeChatRemoteDataSource(const []);

    await ChatRepositoryImpl(remoteDataSource: dataSource).sendMessageStream([
      const ChatMessage(role: ChatRole.user, content: [TextBlock('想找外套')]),
      const ChatMessage(
        role: ChatRole.assistant,
        content: [
          ToolUseBlock(id: 't1', name: 'search', input: {'q': '外套'}),
        ],
      ),
      const ChatMessage(
        role: ChatRole.user,
        content: [
          ToolResultBlock(toolUseId: 't1', content: {'items': <Object>[]}),
        ],
      ),
      const ChatMessage(
        role: ChatRole.assistant,
        content: [
          ContentBlock.picks([
            ChatPick(ref: ItemRef.wardrobe('w1')),
            ChatPick(ref: ItemRef.product('p1'), highlight: '顯瘦'),
          ]),
        ],
      ),
    ]).drain<void>();

    expect(dataSource.sentRequest!.toJson(), {
      'messages': [
        {
          'role': 'user',
          'content': [
            {'type': 'text', 'text': '想找外套'},
          ],
        },
        {
          'role': 'assistant',
          'content': [
            {
              'type': 'tool_use',
              'id': 't1',
              'name': 'search',
              'input': {'q': '外套'},
            },
          ],
        },
        {
          'role': 'user',
          'content': [
            {
              'type': 'tool_result',
              'tool_use_id': 't1',
              'content': {'items': <Object>[]},
            },
          ],
        },
        {
          'role': 'assistant',
          'content': [
            {
              'type': 'picks',
              'picks': [
                {'type': 'wardrobe', 'id': 'w1'},
                {'type': 'product', 'id': 'p1', 'highlight': '顯瘦'},
              ],
            },
          ],
        },
      ],
    });
  });

  test('maps tool events and the final answer', () async {
    final events = await run([
      {
        'type': 'tool_use',
        'id': 't1',
        'name': 'search',
        'input': {'q': '外套'},
      },
      {
        'type': 'tool_result',
        'tool_use_id': 't1',
        'content': {'items': <Object>[]},
      },
      {
        'type': 'done',
        'messages': [
          {
            'role': 'assistant',
            'content': [
              {
                'type': 'tool_use',
                'id': 't1',
                'name': 'search',
                'input': {'q': '外套'},
              },
            ],
          },
          {
            'role': 'user',
            'content': [
              {
                'type': 'tool_result',
                'tool_use_id': 't1',
                'content': {'items': <Object>[]},
              },
            ],
          },
          {
            'role': 'assistant',
            'content': [
              {'type': 'text', 'text': '這件很適合'},
              {
                'type': 'picks',
                'picks': [
                  {'type': 'wardrobe', 'id': 'w1'},
                  {'type': 'hat', 'id': 'h1'},
                ],
              },
              {'type': 'sticker', 'id': 's1'},
            ],
          },
        ],
        'items': {
          'products': <String, Object>{},
          'wardrobe': {'w1': _wardrobeRow},
        },
        'usage': _usageJson,
      },
    ]);

    expect(events, hasLength(3));
    expect(
      events[0],
      const ChatStreamEvent.toolStarted(
        ToolUseBlock(id: 't1', name: 'search', input: {'q': '外套'}),
      ),
    );
    expect(
      events[1],
      const ChatStreamEvent.toolFinished(
        ToolResultBlock(toolUseId: 't1', content: {'items': <Object>[]}),
      ),
    );
    final replied = events[2] as ChatReplied;
    expect(replied.messages, const [
      ChatMessage(
        role: ChatRole.assistant,
        content: [
          ToolUseBlock(id: 't1', name: 'search', input: {'q': '外套'}),
        ],
      ),
      ChatMessage(
        role: ChatRole.user,
        content: [
          ToolResultBlock(toolUseId: 't1', content: {'items': <Object>[]}),
        ],
      ),
      ChatMessage(
        role: ChatRole.assistant,
        content: [
          TextBlock('這件很適合'),
          PicksBlock([ChatPick(ref: ItemRef.wardrobe('w1'))]),
        ],
      ),
    ]);
    expect(replied.items.products, isEmpty);
    expect(replied.items.wardrobe.keys, ['w1']);
    expect(replied.items.wardrobe['w1']!.imagePath, 'u1/w1.jpg');
    expect(replied.usage, _usage);
  });

  test('a malformed usage snapshot only drops the usage', () async {
    final events = await run([
      {
        'type': 'done',
        'messages': <Object>[],
        'items': {
          'products': <String, Object>{},
          'wardrobe': <String, Object>{},
        },
        'usage': {'user_id': 'u1'},
      },
    ]);

    expect(
      events.single,
      const ChatStreamEvent.replied(messages: [], items: ChatItems()),
    );
  });

  test('skips unknown event types', () async {
    final events = await run([
      {'type': 'heartbeat'},
    ]);

    expect(events, isEmpty);
  });

  test('a malformed event fails the run with ServerFailure', () async {
    final events = await run([
      {'type': 'tool_use', 'id': 't1'},
    ]);

    expect(events.single, const ChatStreamEvent.failed(ServerFailure()));
  });

  group('error events', () {
    test('SERVICE_BUSY maps to ServiceBusyFailure', () async {
      final events = await run([
        {'type': 'error', 'code': 'SERVICE_BUSY'},
      ]);

      expect(events.single, const ChatStreamEvent.failed(ServiceBusyFailure()));
    });

    test('VALIDATION_ERROR keeps the backend message', () async {
      final events = await run([
        {'type': 'error', 'code': 'VALIDATION_ERROR', 'message': '太長'},
      ]);

      expect(
        events.single,
        const ChatStreamEvent.failed(ValidationFailure('太長')),
      );
    });

    test('RATE_LIMIT_EXCEEDED carries the usage snapshot', () async {
      final events = await run([
        {'type': 'error', 'code': 'RATE_LIMIT_EXCEEDED', 'usage': _usageJson},
      ]);

      expect(
        events.single,
        ChatStreamEvent.failed(UsageLimitFailure(usage: _usage)),
      );
    });

    test('an unknown code maps to ServerFailure', () async {
      final events = await run([
        {'type': 'error', 'code': 'SOMETHING_ELSE'},
      ]);

      expect(events.single, const ChatStreamEvent.failed(ServerFailure()));
    });
  });

  test('sends an outfits block in its wire shape', () async {
    final dataSource = _FakeChatRemoteDataSource(const []);

    await ChatRepositoryImpl(remoteDataSource: dataSource).sendMessageStream([
      const ChatMessage(
        role: ChatRole.assistant,
        content: [
          ContentBlock.outfits([
            ChatOutfit(
              title: '週末休閒',
              reason: '白襯衫配深藍直筒',
              pieces: [ItemRef.product('p1'), ItemRef.wardrobe('w1')],
            ),
            ChatOutfit(
              title: '溫柔約會',
              pieces: [ItemRef.product('p2'), ItemRef.product('p3')],
            ),
          ]),
        ],
      ),
    ]).drain<void>();

    expect(dataSource.sentRequest!.toJson()['messages'], [
      {
        'role': 'assistant',
        'content': [
          {
            'type': 'outfits',
            'outfits': [
              {
                'title': '週末休閒',
                'reason': '白襯衫配深藍直筒',
                'pieces': [
                  {'type': 'product', 'id': 'p1'},
                  {'type': 'wardrobe', 'id': 'w1'},
                ],
              },
              {
                'title': '溫柔約會',
                'pieces': [
                  {'type': 'product', 'id': 'p2'},
                  {'type': 'product', 'id': 'p3'},
                ],
              },
            ],
          },
        ],
      },
    ]);
  });

  test('decodes outfits, dropping one that holds an unknown item', () async {
    final events = await run([
      {
        'type': 'done',
        'messages': [
          {
            'role': 'assistant',
            'content': [
              {
                'type': 'outfits',
                'outfits': [
                  {
                    'title': '週末休閒',
                    'pieces': [
                      {'type': 'product', 'id': 'p1'},
                      {'type': 'wardrobe', 'id': 'w1'},
                    ],
                  },
                  {
                    'title': '帽子',
                    'pieces': [
                      {'type': 'product', 'id': 'p1'},
                      {'type': 'hat', 'id': 'h1'},
                    ],
                  },
                ],
              },
            ],
          },
        ],
        'items': {
          'products': <String, Object>{},
          'wardrobe': <String, Object>{},
        },
        'usage': _usageJson,
      },
    ]);

    final replied = events.single as ChatReplied;
    expect(replied.messages.single.content, const [
      ContentBlock.outfits([
        ChatOutfit(
          title: '週末休閒',
          pieces: [ItemRef.product('p1'), ItemRef.wardrobe('w1')],
        ),
      ]),
    ]);
  });

  test('decodes the highlight of an item, and its absence', () async {
    final events = await run([
      {
        'type': 'done',
        'messages': [
          {
            'role': 'assistant',
            'content': [
              {
                'type': 'picks',
                'picks': [
                  {'type': 'product', 'id': 'p1', 'highlight': '麻料透氣'},
                  {'type': 'wardrobe', 'id': 'w1'},
                ],
              },
            ],
          },
        ],
        'items': {
          'products': <String, Object>{},
          'wardrobe': <String, Object>{},
        },
        'usage': _usageJson,
      },
    ]);

    final replied = events.single as ChatReplied;
    expect(replied.messages.single.content, const [
      ContentBlock.picks([
        ChatPick(ref: ItemRef.product('p1'), highlight: '麻料透氣'),
        ChatPick(ref: ItemRef.wardrobe('w1')),
      ]),
    ]);
  });

  test('drops blank highlight, blank reason and blank-title outfits', () async {
    final events = await run([
      {
        'type': 'done',
        'messages': [
          {
            'role': 'assistant',
            'content': [
              {
                'type': 'picks',
                'picks': [
                  {'type': 'product', 'id': 'p1', 'highlight': '  '},
                ],
              },
              {
                'type': 'outfits',
                'outfits': [
                  {
                    'title': '週末休閒',
                    'reason': '  ',
                    'pieces': [
                      {'type': 'product', 'id': 'p1'},
                    ],
                  },
                  {
                    'title': '  ',
                    'reason': '空標題',
                    'pieces': [
                      {'type': 'product', 'id': 'p1'},
                    ],
                  },
                ],
              },
            ],
          },
        ],
        'items': {
          'products': <String, Object>{},
          'wardrobe': <String, Object>{},
        },
        'usage': _usageJson,
      },
    ]);

    final replied = events.single as ChatReplied;
    expect(replied.messages.single.content, const [
      ContentBlock.picks([ChatPick(ref: ItemRef.product('p1'))]),
      ContentBlock.outfits([
        ChatOutfit(title: '週末休閒', pieces: [ItemRef.product('p1')]),
      ]),
    ]);
  });
}
