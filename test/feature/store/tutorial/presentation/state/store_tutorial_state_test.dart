import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/feature/store/tutorial/presentation/state/store_tutorial_state.dart';

void main() {
  test('every hint is its own numbered step', () {
    const steps = [
      StoreTutorialState.addProduct(),
      StoreTutorialState.pickImage(),
      StoreTutorialState.analyzing(),
      StoreTutorialState.reviewInfo(),
      StoreTutorialState.price(),
      StoreTutorialState.purchaseLink(),
      StoreTutorialState.sizes(),
      StoreTutorialState.save(),
      StoreTutorialState.reviewProduct(),
      StoreTutorialState.openAccount(),
      StoreTutorialState.viewPerformance(),
    ];

    expect(steps.map((final step) => step.stepLabel), [
      for (var n = 1; n <= steps.length; n++) '$n / ${steps.length}',
    ]);
  });

  test('an inactive tour has no step', () {
    expect(const StoreTutorialState.inactive().stepLabel, isNull);
  });
}
