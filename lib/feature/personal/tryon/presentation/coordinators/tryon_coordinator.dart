import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tryzeon/core/router/shells/personal_tab.dart';
import 'package:tryzeon/core/router/shells/personal_tab_navigator.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/outfit_piece.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_mode.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/controllers/tryon_controller.dart';

part 'tryon_coordinator.g.dart';

@Riverpod(keepAlive: true)
TryonCoordinator tryonCoordinator(final Ref ref) => TryonCoordinator(ref);

class TryonCoordinator {
  TryonCoordinator(this._ref);

  final Ref _ref;

  Future<void> tryonFromOutfit(
    final List<OutfitPiece> pieces, {
    final TryonMode mode = TryonMode.image,
  }) async {
    _ref.read(personalTabNavigatorProvider).goTo(PersonalTab.home);
    await _ref
        .read(tryonControllerProvider.notifier)
        .tryonFromOutfit(pieces, mode: mode);
  }
}
