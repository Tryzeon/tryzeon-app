import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/preset_avatar.dart';
import 'package:tryzeon/feature/personal/profile/providers/personal_profile_providers.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/widgets/model_choice_picker.dart';

void main() {
  setUp(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(1170, 2532);
    view.devicePixelRatio = 3;
    addTearDown(view.reset);
  });

  Finder tileOf(final PresetAvatar preset) =>
      find.widgetWithText(ModelChoiceTile, preset.label);

  Future<void> pumpPicker(
    final WidgetTester tester, {
    required final Future<File> Function(PresetAvatar preset) presetFile,
    final ValueChanged<PresetAvatar>? onPresetSelected,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        retry: (final _, final _) => null,
        overrides: [
          presetAvatarFileProvider.overrideWith(
            (final ref, final preset) => presetFile(preset),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Center(
              child: ModelChoicePicker(
                presets: PresetAvatar.values,
                onPresetSelected: onPresetSelected ?? (final _) {},
                onUploadOwnPhoto: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('shows each preset photo once it is downloaded', (
    final tester,
  ) async {
    await pumpPicker(
      tester,
      presetFile: (final preset) async => File('${preset.name}.jpg'),
    );

    final images = tester
        .widgetList<Image>(find.byType(Image))
        .map((final image) => image.image);
    expect(
      images,
      containsAll([FileImage(File('female.jpg')), FileImage(File('male.jpg'))]),
    );
  });

  testWidgets('a preset whose photo failed to download can still be picked', (
    final tester,
  ) async {
    PresetAvatar? picked;
    await pumpPicker(
      tester,
      presetFile: (final _) async => throw const NetworkFailure(),
      onPresetSelected: (final preset) => picked = preset,
    );

    expect(find.byType(Image), findsNothing);

    await tester.tap(tileOf(PresetAvatar.female));
    expect(picked, PresetAvatar.female);
  });

  testWidgets('a preset still downloading can already be picked', (
    final tester,
  ) async {
    PresetAvatar? picked;
    await pumpPicker(
      tester,
      presetFile: (final _) => Completer<File>().future,
      onPresetSelected: (final preset) => picked = preset,
    );

    expect(find.byType(Image), findsNothing);

    await tester.tap(tileOf(PresetAvatar.male));
    expect(picked, PresetAvatar.male);
  });
}
