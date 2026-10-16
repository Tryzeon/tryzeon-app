import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:tryzeon/feature/personal/settings/data/datasources/own_photo_invite_local_datasource.dart';

void main() {
  late OwnPhotoInviteLocalDataSource dataSource;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    dataSource = OwnPhotoInviteLocalDataSource(SharedPreferencesAsync());
  });

  test('the invite starts out not dismissed', () async {
    expect(await dataSource.isDismissed(), isFalse);
  });

  test('a dismissal is remembered', () async {
    await dataSource.dismiss();

    expect(await dataSource.isDismissed(), isTrue);
  });

  test('clearing brings the invite back', () async {
    await dataSource.dismiss();

    await dataSource.clear();

    expect(await dataSource.isDismissed(), isFalse);
  });
}
