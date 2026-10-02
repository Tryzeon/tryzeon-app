import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/gender.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/preset_avatar.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/user_profile.dart';
import 'package:tryzeon/feature/personal/profile/providers/personal_profile_providers.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/widgets/model_choice_picker.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/widgets/tryon_avatar_page.dart';

class _FakeUserProfileNotifier extends UserProfileNotifier {
  @override
  Future<UserProfile?> build() async => UserProfile(
    userId: 'u1',
    name: 'n',
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
    gender: Gender.female,
  );
}

class _FakeAvatarUploadNotifier extends AvatarUploadNotifier {
  _FakeAvatarUploadNotifier(this._uploading);

  final File? _uploading;

  @override
  File? build() => _uploading;
}

void main() {
  setUp(() {
    final view = TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(1170, 2532);
    view.devicePixelRatio = 3;
    addTearDown(view.reset);
  });

  Future<void> pumpPage(
    final WidgetTester tester, {
    final Future<File?> Function(Ref ref)? avatarFile,
    final File? uploading,
    final ValueChanged<PresetAvatar>? onPresetSelected,
    final VoidCallback? onUploadOwnPhoto,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileProvider.overrideWith(_FakeUserProfileNotifier.new),
          avatarFileProvider.overrideWith(avatarFile ?? (final ref) async => null),
          avatarUploadProvider.overrideWith(() => _FakeAvatarUploadNotifier(uploading)),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: TryonAvatarPage(
              onUploadOwnPhoto: onUploadOwnPhoto ?? () {},
              onPresetSelected: onPresetSelected ?? (final _) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('with no model, offers the matching preset beside an upload', (
    final tester,
  ) async {
    PresetAvatar? picked;
    var choseUpload = false;
    await pumpPage(
      tester,
      onPresetSelected: (final preset) => picked = preset,
      onUploadOwnPhoto: () => choseUpload = true,
    );

    expect(find.text('選擇你的試穿模特'), findsOneWidget);
    expect(find.text(PresetAvatar.male.label), findsNothing);

    await tester.tap(find.text(PresetAvatar.female.label));
    expect(picked, PresetAvatar.female);

    await tester.tap(find.text('上傳自己的照片'));
    expect(choseUpload, isTrue);
  });

  testWidgets('while the model is loading, shows progress instead of the choice', (
    final tester,
  ) async {
    await pumpPage(tester, avatarFile: (final ref) => Completer<File?>().future);

    expect(find.text('選擇你的試穿模特'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('a photo being uploaded shows right away, with progress over it', (
    final tester,
  ) async {
    await pumpPage(tester, uploading: File('preset_male.jpg'));

    final images = tester.widgetList<Image>(find.byType(Image));
    expect(
      images.map((final i) => i.image),
      contains(FileImage(File('preset_male.jpg'))),
    );
    expect(find.text('選擇你的試穿模特'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('preset cards grow with the screen', (final tester) async {
    await pumpPage(tester);

    final width = tester.getSize(find.byType(ModelChoiceTile).first).width;
    expect(width, greaterThan(140));
  });
}
