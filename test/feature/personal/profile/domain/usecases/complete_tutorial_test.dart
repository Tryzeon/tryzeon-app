import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/user_profile.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/user_profile_update.dart';
import 'package:tryzeon/feature/personal/profile/domain/repositories/user_profile_repository.dart';
import 'package:tryzeon/feature/personal/profile/domain/usecases/complete_tutorial.dart';
import 'package:typed_result/typed_result.dart';

final _saved = UserProfile(
  userId: 'u1',
  name: 'n',
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
  isTutorialCompleted: true,
);

class _FakeRepository implements UserProfileRepository {
  UserProfileUpdate? saved;

  @override
  Future<Result<UserProfile, Failure>> updateUserProfile(
    final UserProfileUpdate update,
  ) async {
    saved = update;
    return Ok(_saved);
  }

  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

void main() {
  test('marks the tutorial completed and nothing else', () async {
    final repository = _FakeRepository();

    final result = await CompleteTutorial(repository)();

    expect(result.get(), _saved);
    expect(
      repository.saved,
      const UserProfileUpdate(isTutorialCompleted: true),
    );
  });
}
