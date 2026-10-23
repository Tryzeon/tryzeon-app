import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/store/profile/providers/store_profile_providers.dart';
import 'package:tryzeon/feature/store/tutorial/providers/store_tutorial_providers.dart';
import 'package:typed_result/typed_result.dart';

part 'store_tutorial_finished_provider.g.dart';

/// Whether the brand skipped the tour or listed its first product. An
/// unreadable flag reads as finished: a broken store must not keep showing a
/// tour the brand may already have finished.
@riverpod
class StoreTutorialFinishedNotifier extends _$StoreTutorialFinishedNotifier {
  @override
  Future<bool> build() async {
    final storeId = await ref.watch(
      storeProfileProvider.selectAsync((final profile) => profile?.id),
    );
    if (storeId == null) return true;

    final result = await ref.read(isStoreTutorialFinishedUseCaseProvider)(
      storeId,
    );
    return result.isSuccess ? result.get()! : true;
  }

  Future<void> finish() async {
    state = const AsyncData(true);
    final storeId = ref.read(storeProfileProvider).value?.id;
    if (storeId == null) return;

    final result = await ref.read(finishStoreTutorialUseCaseProvider)(storeId);
    if (result.isFailure) {
      AppLogger.error(
        'Failed to persist the store tutorial finish',
        result.getError(),
      );
    }
  }
}
