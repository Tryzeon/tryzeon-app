import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/presentation/coach_mark/coach_mark_registry.dart';
import 'package:tryzeon/core/presentation/coach_mark/coach_mark_target.dart';

/// Marks [child] as the [target] a coach-mark hint points at.
class CoachMarkAnchor extends ConsumerStatefulWidget {
  const CoachMarkAnchor({super.key, required this.target, required this.child});

  final CoachMarkTarget target;
  final Widget child;

  @override
  ConsumerState<CoachMarkAnchor> createState() => _CoachMarkAnchorState();
}

class _CoachMarkAnchorState extends ConsumerState<CoachMarkAnchor> {
  late final CoachMarkRegistry _registry;

  @override
  void initState() {
    super.initState();
    _registry = ref.read(coachMarkRegistryProvider)
      ..register(widget.target, context);
  }

  @override
  void didUpdateWidget(final CoachMarkAnchor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.target == widget.target) return;
    _registry
      ..unregister(oldWidget.target, context)
      ..register(widget.target, context);
  }

  @override
  void dispose() {
    _registry.unregister(widget.target, context);
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) => widget.child;
}
