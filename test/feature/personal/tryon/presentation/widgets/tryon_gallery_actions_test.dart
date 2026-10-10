import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:toastification/toastification.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/auth/providers/auth_providers.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/personal/subscription/domain/entities/subscription_capabilities.dart';
import 'package:tryzeon/feature/personal/subscription/providers/subscription_capabilities_provider.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/outfit_piece.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_mode.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_result.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_subject.dart';
import 'package:tryzeon/feature/personal/tryon/domain/repositories/tryon_report_repository.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/state/tryon_gallery_provider.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/widgets/tryon_gallery_actions.dart';
import 'package:tryzeon/feature/personal/tryon/providers/tryon_providers.dart';
import 'package:typed_result/typed_result.dart';

import '../../../../../support/sheet_test_host.dart';

class _FakeReportRepository implements TryonReportRepository {
  _FakeReportRepository({this.failure});

  final Failure? failure;
  final reported = <String>[];

  @override
  Future<Result<void, Failure>> report(final String tryonId) async {
    reported.add(tryonId);
    if (failure case final failure?) return Err(failure);
    return const Ok(null);
  }
}

void main() {
  const piece = OutfitPiece.wardrobe(
    wardrobeItemId: 'w1',
    imagePath: 'w1.jpg',
    garmentType: GarmentType.top,
  );

  TryonSubject subjectFor(final TryonMode mode) =>
      TryonSubject.generate(pieces: const [piece], mode: mode);

  late _FakeReportRepository repository;
  late ProviderContainer container;

  TryonGalleryNotifier gallery() =>
      container.read(tryonGalleryProvider.notifier);

  void setUpContainer({final Failure? failure}) {
    repository = _FakeReportRepository(failure: failure);
    container = ProviderContainer(
      overrides: [
        isAuthenticatedProvider.overrideWithValue(true),
        subscriptionCapabilitiesProvider.overrideWith(
          (final ref) => Future.value(
            const SubscriptionCapabilities(
              wardrobeLimit: 10,
              dailyTryonLimit: 10,
              dailyChatLimit: 10,
              dailyVideoLimit: 0,
            ),
          ),
        ),
        tryonReportRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
  }

  void addFinished(final String id, {final TryonMode mode = TryonMode.image}) {
    gallery()
      ..addPending(id: id, subject: subjectFor(mode))
      ..complete(
        TryonResult(
          id: id,
          mode: mode,
          imageUrl: mode == TryonMode.image ? 'https://img/$id.png' : null,
          videoUrl: mode == TryonMode.video ? 'https://vid/$id.mp4' : null,
        ),
      );
  }

  Future<void> pumpActions(final WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(body: TryonGalleryActions(onReplaceAvatar: () {})),
        ),
      ),
    );
    await settle(tester);
  }

  Future<void> openMenu(final WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.more_vert_rounded));
    await settle(tester);
  }

  Future<void> tapReport(final WidgetTester tester) async {
    await openMenu(tester);
    await tester.tap(find.text('檢舉此內容'));
    await settle(tester);
  }

  Future<void> confirmReport(final WidgetTester tester) async {
    await tapReport(tester);
    await tester.tap(find.text('檢舉'));
    await settle(tester);
  }

  testWidgets('a finished image try-on can be reported', (final tester) async {
    setUpContainer();
    addFinished('a');
    await pumpActions(tester);
    await openMenu(tester);

    expect(find.text('檢舉此內容'), findsOneWidget);
  });

  testWidgets('a finished video try-on can be reported', (final tester) async {
    setUpContainer();
    addFinished('a', mode: TryonMode.video);
    await pumpActions(tester);
    await openMenu(tester);

    expect(find.text('檢舉此內容'), findsOneWidget);
  });

  testWidgets('a try-on still generating cannot be reported', (
    final tester,
  ) async {
    setUpContainer();
    gallery().addPending(id: 'a', subject: subjectFor(TryonMode.image));
    await pumpActions(tester);
    await openMenu(tester);

    expect(find.text('檢舉此內容'), findsNothing);
  });

  testWidgets('confirming reports the try-on in view and drops only it', (
    final tester,
  ) async {
    setUpContainer();
    addFinished('a');
    addFinished('b');
    await pumpActions(tester);

    await confirmReport(tester);

    expect(repository.reported, ['b']);
    expect(
      container.read(tryonGalleryProvider).entries.map((final e) => e.id),
      ['a'],
    );
    expect(find.text('已收到此檢舉，謝謝您！'), findsOneWidget);
  });

  testWidgets('reporting the try-on used as the avatar clears the avatar', (
    final tester,
  ) async {
    setUpContainer();
    addFinished('a');
    gallery().toggleAvatarForCurrent();
    await pumpActions(tester);

    await confirmReport(tester);

    final state = container.read(tryonGalleryProvider);
    expect(state.entries, isEmpty);
    expect(state.customAvatarId, isNull);
  });

  testWidgets('cancelling the confirmation reports nothing', (
    final tester,
  ) async {
    setUpContainer();
    addFinished('a');
    await pumpActions(tester);

    await tapReport(tester);
    await tester.tap(find.text('取消'));
    await settle(tester);

    expect(repository.reported, isEmpty);
    expect(container.read(tryonGalleryProvider).entries, hasLength(1));
  });

  testWidgets('a failed report keeps the try-on and says so', (
    final tester,
  ) async {
    setUpContainer(failure: const ServerFailure());
    addFinished('a');
    await pumpActions(tester);

    await confirmReport(tester);

    expect(container.read(tryonGalleryProvider).entries, hasLength(1));
    expect(find.text('檢舉送出失敗，請稍後再試'), findsOneWidget);

    toastification.dismissAll(delayForAnimation: false);
    await settle(tester);
  });
}
