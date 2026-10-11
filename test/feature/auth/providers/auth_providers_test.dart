import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/di/core_providers.dart';
import 'package:tryzeon/core/modules/auth_identity/domain/services/auth_identity_service.dart';
import 'package:tryzeon/feature/auth/providers/auth_providers.dart';

class _FakeAuthIdentityService implements AuthIdentityService {
  _FakeAuthIdentityService(this._changes, {this.currentUserId});

  final Stream<String?> _changes;

  @override
  String? currentUserId;

  @override
  Stream<String?> watchUserId() => _changes;
}

void main() {
  late StreamController<String?> changes;

  setUp(() => changes = StreamController<String?>.broadcast());
  tearDown(() => changes.close());

  ProviderContainer containerFor(final AuthIdentityService identity) {
    final container = ProviderContainer(
      overrides: [authIdentityServiceProvider.overrideWithValue(identity)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('reads a restored session before any auth event arrives', () {
    final container = containerFor(
      _FakeAuthIdentityService(changes.stream, currentUserId: 'u1'),
    );

    expect(container.read(currentUserIdProvider), 'u1');
    expect(container.read(isAuthenticatedProvider), isTrue);
  });

  test('follows sign-out on the next auth event', () async {
    final identity = _FakeAuthIdentityService(
      changes.stream,
      currentUserId: 'u1',
    );
    final container = containerFor(identity)
      ..listen(isAuthenticatedProvider, (final _, final _) {});

    identity.currentUserId = null;
    changes.add(null);
    await Future<void>.delayed(Duration.zero);

    expect(container.read(isAuthenticatedProvider), isFalse);
  });
}
