import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tryzeon/core/presentation/widgets/app_upgrade_alert.dart';
import 'package:upgrader/upgrader.dart';

final _storeListing = jsonEncode({
  'resultCount': 1,
  'results': [
    {
      'version': '1.1.0',
      'bundleId': 'com.tryzeon.app',
      'trackViewUrl': 'https://apps.apple.com/app/id1',
      'releaseNotes': 'Bug fixes',
    },
  ],
});

Future<void> pumpAlert(
  final WidgetTester tester, {
  required final Map<String, Object> savedPrefs,
}) async {
  SharedPreferences.setMockInitialValues(savedPrefs);
  PackageInfo.setMockInitialValues(
    appName: 'TryZeon',
    packageName: 'com.tryzeon.app',
    version: '1.0.0',
    buildNumber: '1',
    buildSignature: '',
  );
  final navigatorKey = GlobalKey<NavigatorState>();
  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: navigatorKey,
      home: AppUpgradeAlert(
        upgrader: createAppUpgrader(
          upgraderOS: MockUpgraderOS(ios: true),
          client: MockClient(
            (final _) async => http.Response(_storeListing, 200),
          ),
        ),
        navigatorKey: navigatorKey,
        child: const SizedBox.shrink(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.pump();
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a newer store version offers only Update Now', (
    final tester,
  ) async {
    await pumpAlert(tester, savedPrefs: {});

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('UPDATE NOW'), findsOneWidget);
    expect(find.text('IGNORE'), findsNothing);
    expect(find.text('LATER'), findsNothing);
  });

  testWidgets(
    'the dialog comes back on every launch, however recent the last',
    (final tester) async {
      await pumpAlert(
        tester,
        savedPrefs: {
          'lastTimeAlerted': DateTime.now().toString(),
          'lastVersionAlerted': '1.1.0',
        },
      );

      expect(find.byType(AlertDialog), findsOneWidget);
    },
  );
}
