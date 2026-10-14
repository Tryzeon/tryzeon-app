import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/user_profile_update.dart';
import 'package:tryzeon/feature/personal/profile/domain/repositories/user_profile_repository.dart';
import 'package:tryzeon/feature/personal/tutorial/domain/usecases/complete_tutorial.dart';
import 'package:typed_result/typed_result.dart';

class _FakeRepository implements UserProfileRepository {
  UserProfileUpdate? saved;

  @override
  Future<Result<void, Failure>> updateUserProfile(
    final UserProfileUpdate update,
  ) async {
    saved = update;
    return const Ok(null);
  }

  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

void main() {
  test('marks the tutorial completed and nothing else', () async {
    final repository = _FakeRepository();

    final result = await CompleteTutorial(repository)();

    expect(result.isSuccess, isTrue);
    expect(
      repository.saved,
      const UserProfileUpdate(isTutorialCompleted: true),
    );
  });
}
