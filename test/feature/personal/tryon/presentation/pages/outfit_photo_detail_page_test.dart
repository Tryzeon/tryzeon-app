import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tryzeon/core/router/app_routes.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/pages/outfit_photo_detail_page.dart';

void main() {
  testWidgets('shows the photo and goes back to where it was opened from', (
    final tester,
  ) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (final context, final _) => TextButton(
            onPressed: () =>
                context.push(AppRoutes.personalHomePhotoPath('/tmp/a b.jpg')),
            child: const Text('home'),
          ),
        ),
        GoRoute(
          path: AppRoutes.personalHomePhoto,
          builder: (final _, final state) =>
              OutfitPhotoDetailPage(path: state.uri.queryParameters['path']!),
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.lightTheme, routerConfig: router),
    );

    await tester.tap(find.text('home'));
    await tester.pumpAndSettle();

    final image = tester.widget<Image>(find.byType(Image));
    expect((image.image as FileImage).file.path, '/tmp/a b.jpg');
    expect(find.text('照片'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();

    expect(find.text('home'), findsOneWidget);
  });
}
