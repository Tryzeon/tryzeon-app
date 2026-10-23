import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tryzeon/core/di/core_providers.dart';
import 'package:tryzeon/feature/store/tutorial/data/datasources/store_tutorial_local_datasource.dart';
import 'package:tryzeon/feature/store/tutorial/data/repositories/store_tutorial_repository_impl.dart';
import 'package:tryzeon/feature/store/tutorial/domain/repositories/store_tutorial_repository.dart';
import 'package:tryzeon/feature/store/tutorial/domain/usecases/finish_store_tutorial.dart';
import 'package:tryzeon/feature/store/tutorial/domain/usecases/is_store_tutorial_finished.dart';

part 'store_tutorial_providers.g.dart';

@riverpod
StoreTutorialLocalDataSource storeTutorialLocalDataSource(final Ref ref) {
  return StoreTutorialLocalDataSource(ref.watch(sharedPreferencesProvider));
}

@riverpod
StoreTutorialRepository storeTutorialRepository(final Ref ref) {
  return StoreTutorialRepositoryImpl(
    ref.watch(storeTutorialLocalDataSourceProvider),
  );
}

@riverpod
IsStoreTutorialFinished isStoreTutorialFinishedUseCase(final Ref ref) =>
    IsStoreTutorialFinished(ref.watch(storeTutorialRepositoryProvider));

@riverpod
FinishStoreTutorial finishStoreTutorialUseCase(final Ref ref) =>
    FinishStoreTutorial(ref.watch(storeTutorialRepositoryProvider));
