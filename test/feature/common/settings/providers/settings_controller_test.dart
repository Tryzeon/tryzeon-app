import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/auth/domain/usecases/delete_account.dart';
import 'package:tryzeon/feature/auth/providers/auth_providers.dart';
import 'package:tryzeon/feature/common/settings/providers/settings_controller.dart';
import 'package:typed_result/typed_result.dart';

class _FailingDeleteAccount implements DeleteAccount {
  @override
  Future<Result<void, Failure>> call() async => const Err(ServerFailure());

  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

void main() {
  test('a failed account deletion surfaces as an error state', () async {
    final container = ProviderContainer(
      overrides: [
        deleteAccountUseCaseProvider.overrideWithValue(_FailingDeleteAccount()),
      ],
    );
    addTearDown(container.dispose);
    container.listen(settingsControllerProvider, (final _, final _) {});
    await container.read(settingsControllerProvider.future);

    final result = await container
        .read(settingsControllerProvider.notifier)
        .deleteAccount();

    expect(result.getError(), const ServerFailure());
    expect(container.read(settingsControllerProvider).hasError, isTrue);
  });
}
