import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tryzeon/core/presentation/coach_mark/coach_mark_target.dart';

part 'coach_mark_registry.g.dart';

class CoachMarkRegistry {
  final _anchors = <CoachMarkTarget, BuildContext>{};

  BuildContext? anchorOf(final CoachMarkTarget target) => _anchors[target];

  void register(final CoachMarkTarget target, final BuildContext anchor) =>
      _anchors[target] = anchor;

  void unregister(final CoachMarkTarget target, final BuildContext anchor) {
    if (identical(_anchors[target], anchor)) _anchors.remove(target);
  }
}

@Riverpod(keepAlive: true)
CoachMarkRegistry coachMarkRegistry(final Ref ref) => CoachMarkRegistry();
