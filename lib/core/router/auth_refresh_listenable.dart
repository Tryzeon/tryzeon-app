import 'dart:async';

import 'package:flutter/foundation.dart';

/// Converts a [Stream] into a [Listenable] for GoRouter's
/// refreshListenable parameter.
class AuthRefreshListenable extends ChangeNotifier {
  AuthRefreshListenable(final Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((final _) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
