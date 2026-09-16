import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tryzeon/core/router/shells/personal_tab.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/outfit_piece.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_mode.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/controllers/tryon_controller.dart';

part 'tryon_coordinator.g.dart';

/// Navigation stays a bound callback because switching a [StatefulNavigationShell]
/// branch needs the shell's context; execution is a direct provider read, not a
/// bound callback, so a try-on can never silently no-op.
@Riverpod(keepAlive: true)
TryonCoordinator tryonCoordinator(final Ref ref) => TryonCoordinator(ref);

class TryonCoordinator {
  TryonCoordinator(this._ref);

  final Ref _ref;
  ValueChanged<PersonalTab>? _navigateTo;

  // ignore: use_setters_to_change_properties
  void bindNavigation(final ValueChanged<PersonalTab> fn) => _navigateTo = fn;
  void unbindNavigation(final ValueChanged<PersonalTab> fn) {
    if (_navigateTo == fn) _navigateTo = null;
  }

  void navigateTo(final PersonalTab tab) => _navigateTo?.call(tab);

  Future<void> tryonFromOutfit(
    final List<OutfitPiece> pieces, {
    final TryonMode mode = TryonMode.image,
  }) async {
    navigateTo(PersonalTab.home);
    await _ref.read(tryonControllerProvider.notifier).tryonFromOutfit(pieces, mode: mode);
  }
}
