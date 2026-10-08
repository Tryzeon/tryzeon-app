import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/feature/store/product/domain/services/audio_recorder_service.dart';
import 'package:tryzeon/feature/store/product/presentation/hooks/use_product_size_manager.dart';
import 'package:tryzeon/feature/store/product/presentation/hooks/use_size_voice_input.dart';
import 'package:tryzeon/feature/store/product/providers/store_product_providers.dart';

class _FakeRecorder implements AudioRecorderService {
  int cancelCount = 0;

  @override
  Future<RecorderStartResult> start() async => RecorderStartResult.started;

  @override
  Future<({Uint8List? bytes, String mimeType})> stop() async =>
      (bytes: null, mimeType: mimeType);

  @override
  Future<void> cancel() async => cancelCount++;

  @override
  String get mimeType => 'audio/mp4';
}

class _VoiceHost extends HookConsumerWidget {
  const _VoiceHost();

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final voice = useSizeVoiceInput(
      ref: ref,
      sizeManager: useProductSizeManager(),
    );
    return TextButton(onPressed: voice.toggle, child: Text(voice.status.name));
  }
}

Future<_FakeRecorder> _pumpHost(final WidgetTester tester) async {
  final recorder = _FakeRecorder();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [audioRecorderServiceProvider.overrideWithValue(recorder)],
      child: const MaterialApp(home: Scaffold(body: _VoiceHost())),
    ),
  );
  return recorder;
}

void main() {
  testWidgets('leaving mid-recording cancels the recorder', (
    final tester,
  ) async {
    final recorder = await _pumpHost(tester);

    await tester.tap(find.byType(TextButton));
    await tester.pump();
    expect(find.text(SizeVoiceStatus.recording.name), findsOneWidget);

    await tester.pumpWidget(const SizedBox());

    expect(recorder.cancelCount, 1);
  });

  testWidgets('leaving while idle leaves the recorder alone', (
    final tester,
  ) async {
    final recorder = await _pumpHost(tester);

    await tester.pumpWidget(const SizedBox());

    expect(recorder.cancelCount, 0);
  });
}
