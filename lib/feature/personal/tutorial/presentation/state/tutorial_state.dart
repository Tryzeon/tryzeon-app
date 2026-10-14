import 'package:freezed_annotation/freezed_annotation.dart';

part 'tutorial_state.freezed.dart';

@freezed
sealed class TutorialState with _$TutorialState {
  const factory TutorialState.inactive() = TutorialInactive;
  const factory TutorialState.pickModel() = TutorialPickModel;
  const factory TutorialState.startTryon() = TutorialStartTryon;
  const factory TutorialState.generating(final Set<String> requestIds) =
      TutorialGenerating;
  const factory TutorialState.reviewResult(final String requestId) =
      TutorialReviewResult;
}
