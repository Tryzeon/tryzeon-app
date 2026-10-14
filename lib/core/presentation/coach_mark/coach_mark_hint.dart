import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/presentation/coach_mark/coach_mark_registry.dart';
import 'package:tryzeon/core/presentation/coach_mark/coach_mark_target.dart';
import 'package:tryzeon/core/presentation/widgets/bottom_nav_bar_inset.dart';
import 'package:tryzeon/core/theme/app_theme.dart';

typedef CoachMarkAction = ({String label, VoidCallback onPressed});

enum CoachMarkPlacement {
  /// Above the target, flipping below when there is more room there.
  above,

  /// Below the target, flipping above when there is more room there.
  below,

  /// Left of the target, as wide as the room beside it allows.
  left,

  /// Above a target that sits in the bottom chrome itself, such as a tab.
  aboveChrome,
}

/// Never blocks the screen: outside the bubble every tap reaches the real UI,
/// and nothing is mounted while the target is not fully visible clear of the
/// status bar, bottom chrome (unless [CoachMarkPlacement.aboveChrome]) and
/// pinned headers. The target is tracked every frame, and only while this
/// hint is mounted. The first frame is invisible: the bubble is measured
/// before it picks a side.
///
/// Must fill the screen (e.g. in an overlay): placement is decided in
/// [MediaQuery] coordinates.
class CoachMarkHint extends HookConsumerWidget {
  const CoachMarkHint({
    super.key,
    required this.target,
    required this.message,
    this.placement = CoachMarkPlacement.below,
    this.onSkip,
    this.action,
    this.revealTarget = false,
    this.stepLabel,
  });

  static const skipLabel = '略過';
  static const maxWidth = 280.0;
  static const _minWidth = 160.0;
  static const _screenMargin = AppSpacing.md;
  static const _gap = AppSpacing.sm;

  @visibleForTesting
  static const beaconKey = Key('coach-mark-beacon');

  @visibleForTesting
  static const bubbleKey = Key('coach-mark-bubble');

  @visibleForTesting
  static const caretKey = Key('coach-mark-caret');

  final CoachMarkTarget target;
  final String message;
  final CoachMarkPlacement placement;
  final VoidCallback? onSkip;
  final CoachMarkAction? action;
  final bool revealTarget;

  /// Where this hint sits in its sequence, e.g. `1 / 3`.
  final String? stepLabel;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final geometry = _useTargetGeometry(
      registry: ref.watch(coachMarkRegistryProvider),
      target: target,
      reveal: revealTarget,
      reduceMotion: MediaQuery.disableAnimationsOf(context),
    );
    final bubbleSize = useState<Size?>(null);
    final measureKey = useMemoized(GlobalKey.new);

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((final _) {
        final size = measureKey.currentContext?.size;
        if (context.mounted && size != null) bubbleSize.value = size;
      });
      return null;
    });

    final layout = geometry == null
        ? null
        : _resolveLayout(context, geometry, bubbleSize.value);
    if (layout == null || geometry == null) return const SizedBox.shrink();
    final measured = bubbleSize.value != null;

    final bubble = ConstrainedBox(
      key: measureKey,
      constraints: BoxConstraints(maxWidth: layout.maxWidth),
      child: _Bubble(
        key: bubbleKey,
        message: message,
        stepLabel: stepLabel,
        onSkip: onSkip,
        action: action,
        caret: layout.caret,
      ),
    );
    // Placed from the tracked target geometry, never with a
    // CompositedTransformFollower: on iOS 26 any follower layer in the scene
    // makes the native tab bar (a UiKitView) drop its touches. Nothing is
    // painted over a chrome target either, so it gets no beacon. The beacon
    // rings the target rather than sitting on it, so it never hides a label.
    final targetRect = geometry.target;
    final hint = Stack(
      fit: StackFit.expand,
      children: [
        if (placement != CoachMarkPlacement.aboveChrome)
          Positioned.fromRect(
            rect: targetRect.inflate(_Beacon.spread),
            child: const IgnorePointer(child: _Beacon(key: beaconKey)),
          ),
        Positioned(
          left: targetRect.left + layout.offset.dx,
          top: targetRect.top + layout.offset.dy,
          child: bubble,
        ),
      ],
    );
    return IgnorePointer(
      ignoring: !measured,
      child: Opacity(
        opacity: measured ? 1 : 0,
        child: TickerMode(enabled: measured, child: hint),
      ),
    );
  }

  _HintLayout? _resolveLayout(
    final BuildContext context,
    final _TargetGeometry geometry,
    final Size? bubbleSize,
  ) {
    final screen = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final clear = Rect.fromLTRB(
      0,
      padding.top,
      screen.width,
      screen.height - padding.bottom - BottomNavBarInset.of(context),
    );
    final rect = geometry.target;
    final bounds = geometry.bounds.intersect(Offset.zero & screen);
    if (!_contains(bounds, rect)) return null;
    final unobstructed = _contains(clear.intersect(bounds), rect);
    final room = Rect.fromLTRB(
      clear.left,
      math.max(clear.top, geometry.pinnedBottom),
      clear.right,
      clear.bottom,
    );
    final size = bubbleSize ?? Size.zero;

    double centeredLeft() => (rect.center.dx - size.width / 2).clamp(
      _screenMargin,
      math.max(_screenMargin, screen.width - _screenMargin - size.width),
    );

    final fullWidth = math.min(maxWidth, screen.width - 2 * _screenMargin);
    if (fullWidth < _minWidth) return null;

    switch (placement) {
      case CoachMarkPlacement.aboveChrome:
        final left = centeredLeft();
        final top = rect.top - _gap - size.height;
        if (top < clear.top) return null;
        return (
          offset: Offset(left - rect.left, top - rect.top),
          maxWidth: fullWidth,
          caret: (edge: _CaretEdge.bottom, offset: rect.center.dx - left),
        );
      case CoachMarkPlacement.left:
        if (!unobstructed) return null;
        final width = math.min(maxWidth, rect.left - _gap - _screenMargin);
        if (width < _minWidth) return null;
        final top = rect.center.dy - size.height / 2;
        return (
          offset: Offset(-_gap - size.width, top - rect.top),
          maxWidth: width,
          caret: (edge: _CaretEdge.right, offset: rect.center.dy - top),
        );
      case CoachMarkPlacement.above || CoachMarkPlacement.below:
        if (!unobstructed) return null;
        final roomAbove = rect.top - room.top - _gap;
        final roomBelow = room.bottom - rect.bottom - _gap;
        final prefersAbove = placement == CoachMarkPlacement.above;
        final preferredRoom = prefersAbove ? roomAbove : roomBelow;
        final otherRoom = prefersAbove ? roomBelow : roomAbove;
        if (preferredRoom < size.height && otherRoom < size.height) {
          return null;
        }
        final above = (preferredRoom >= size.height) == prefersAbove;
        final left = centeredLeft();
        final top = above ? rect.top - _gap - size.height : rect.bottom + _gap;
        return (
          offset: Offset(left - rect.left, top - rect.top),
          maxWidth: fullWidth,
          caret: (
            edge: above ? _CaretEdge.bottom : _CaretEdge.top,
            offset: rect.center.dx - left,
          ),
        );
    }
  }

  static bool _contains(final Rect outer, final Rect inner) =>
      inner.left >= outer.left - _epsilon &&
      inner.top >= outer.top - _epsilon &&
      inner.right <= outer.right + _epsilon &&
      inner.bottom <= outer.bottom + _epsilon;

  static const _epsilon = 0.5;
}

/// Global geometry of a painted target. [bounds] is the area its scroll views
/// leave unobstructed (viewports minus pinned headers), which the target must
/// sit inside. The bubble lives in an overlay, so only [pinnedBottom], the
/// lowest pinned header edge above the target, limits where it may go.
typedef _TargetGeometry = ({Rect target, Rect bounds, double pinnedBottom});

_TargetGeometry? _useTargetGeometry({
  required final CoachMarkRegistry registry,
  required final CoachMarkTarget target,
  required final bool reveal,
  required final bool reduceMotion,
}) {
  final geometry = useState<_TargetGeometry?>(null);
  final inputs = (
    registry: registry,
    target: target,
    reduceMotion: reduceMotion,
  );
  final latest = useRef(inputs)..value = inputs;
  final vsync = useSingleTickerProvider();

  useEffect(() {
    var revealPending = reveal;
    final ticker = vsync.createTicker((final _) {
      final (:registry, :target, :reduceMotion) = latest.value;
      final anchor = registry.anchorOf(target);
      if (anchor == null ||
          !TickerMode.getValuesNotifier(anchor).value.enabled) {
        geometry.value = null;
        return;
      }
      // A lazily built target may sit entirely below the fold, so the reveal
      // does not wait for the target to show.
      if (revealPending) {
        revealPending = false;
        Scrollable.ensureVisible(
          anchor,
          alignment: 0.5,
          duration: reduceMotion ? Duration.zero : AppDuration.slow,
          curve: AppCurves.standard,
        );
      }
      geometry.value = _locate(anchor);
    })..start();
    return ticker.dispose;
  }, const []);

  return geometry.value;
}

_TargetGeometry? _locate(final BuildContext anchor) {
  final box = anchor.findRenderObject();
  if (box is! RenderBox || !box.attached || !box.hasSize) return null;
  var bounds = Rect.largest;
  var pinnedBottom = double.negativeInfinity;
  RenderObject child = box;
  for (var node = box.parent; node != null; node = node.parent) {
    if (!node.paintsChild(child)) return null;
    if (node case final RenderBox viewport
        when node is RenderAbstractViewport) {
      bounds = bounds.intersect(_globalRect(viewport));
    }
    if (node is RenderViewportBase && child is RenderSliver) {
      pinnedBottom = math.max(pinnedBottom, _pinnedBottom(node, child));
    }
    child = node;
  }
  return (
    target: _globalRect(box),
    bounds: Rect.fromLTRB(
      bounds.left,
      math.max(bounds.top, pinnedBottom),
      bounds.right,
      bounds.bottom,
    ),
    pinnedBottom: pinnedBottom,
  );
}

Rect _globalRect(final RenderBox box) =>
    MatrixUtils.transformRect(box.getTransformTo(null), Offset.zero & box.size);

/// Lowest edge of the pinned slivers (e.g. [PinnedHeaderSliver]) painted
/// before [sliver], which stay on screen over the content scrolling under
/// them.
double _pinnedBottom(
  final RenderViewportBase viewport,
  final RenderSliver sliver,
) {
  var bottom = double.negativeInfinity;
  if (viewport.axisDirection != AxisDirection.down) return bottom;
  for (
    var before = viewport.firstChild;
    before != null && before != sliver;
    before = viewport.childAfter(before)
  ) {
    final geometry = before.geometry;
    if (geometry == null ||
        !geometry.visible ||
        geometry.maxScrollObstructionExtent <= 0) {
      continue;
    }
    final top = MatrixUtils.transformPoint(
      before.getTransformTo(null),
      Offset.zero,
    ).dy;
    bottom = math.max(bottom, top + geometry.paintExtent);
  }
  return bottom;
}

typedef _Caret = ({_CaretEdge edge, double offset});

enum _CaretEdge { top, bottom, right }

typedef _HintLayout = ({Offset offset, double maxWidth, _Caret caret});

class _Bubble extends StatelessWidget {
  const _Bubble({
    super.key,
    required this.message,
    required this.caret,
    this.stepLabel,
    this.onSkip,
    this.action,
  });

  static const _caretBase = AppSpacing.md;
  static const _caretDepth = AppSpacing.sm;
  static const _stepLetterSpacing = 1.2;
  static const _messageLineHeight = 1.45;

  final String message;
  final _Caret caret;
  final String? stepLabel;
  final VoidCallback? onSkip;
  final CoachMarkAction? action;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final muted = colorScheme.onInverseSurface.withValues(
      alpha: AppOpacity.overlay,
    );
    final hasHeader = stepLabel != null || onSkip != null;

    final body = Material(
      color: colorScheme.inverseSurface,
      borderRadius: AppRadius.dialogAll,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.mdLg,
          hasHeader ? AppSpacing.smMd : AppSpacing.mdLg,
          hasHeader ? AppSpacing.smMd : AppSpacing.mdLg,
          AppSpacing.mdLg,
        ),
        child: IntrinsicWidth(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasHeader)
                Row(
                  children: [
                    if (stepLabel case final stepLabel?)
                      Text(
                        stepLabel,
                        style: textTheme.labelSmall?.copyWith(
                          color: muted,
                          letterSpacing: _stepLetterSpacing,
                        ),
                      ),
                    const Spacer(),
                    if (onSkip case final onSkip?)
                      TextButton(
                        onPressed: onSkip,
                        style: TextButton.styleFrom(
                          foregroundColor: muted,
                          textStyle: textTheme.labelMedium,
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(CoachMarkHint.skipLabel),
                      ),
                  ],
                ),
              if (hasHeader) const SizedBox(height: AppSpacing.xs),
              Padding(
                padding: EdgeInsets.only(right: hasHeader ? AppSpacing.sm : 0),
                child: Text(
                  message,
                  textWidthBasis: TextWidthBasis.longestLine,
                  style: textTheme.titleSmall?.copyWith(
                    color: colorScheme.onInverseSurface,
                    height: _messageLineHeight,
                  ),
                ),
              ),
              if (action case final action?) ...[
                const SizedBox(height: AppSpacing.md),
                FilledButton(
                  onPressed: action.onPressed,
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.onInverseSurface,
                    foregroundColor: colorScheme.inverseSurface,
                    shape: const StadiumBorder(),
                    visualDensity: VisualDensity.compact,
                  ),
                  child: Text(action.label),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    return Stack(
      children: [
        Padding(
          padding: switch (caret.edge) {
            _CaretEdge.top => const EdgeInsets.only(top: _caretDepth),
            _CaretEdge.bottom => const EdgeInsets.only(bottom: _caretDepth),
            _CaretEdge.right => const EdgeInsets.only(right: _caretDepth),
          },
          child: body,
        ),
        Positioned.fill(
          child: CustomSingleChildLayout(
            delegate: _CaretLayout(caret),
            child: CustomPaint(
              key: CoachMarkHint.caretKey,
              painter: _CaretPainter(
                edge: caret.edge,
                color: colorScheme.inverseSurface,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CaretLayout extends SingleChildLayoutDelegate {
  const _CaretLayout(this.caret);

  final _Caret caret;

  @override
  BoxConstraints getConstraintsForChild(final BoxConstraints constraints) =>
      BoxConstraints.tight(switch (caret.edge) {
        _CaretEdge.top || _CaretEdge.bottom => const Size(
          _Bubble._caretBase,
          _Bubble._caretDepth,
        ),
        _CaretEdge.right => const Size(_Bubble._caretDepth, _Bubble._caretBase),
      });

  @override
  Offset getPositionForChild(final Size size, final Size childSize) {
    const inset = AppRadius.dialog + _Bubble._caretBase / 2;
    final length = caret.edge == _CaretEdge.right ? size.height : size.width;
    final center = caret.offset.clamp(inset, math.max(inset, length - inset));
    const half = _Bubble._caretBase / 2;
    return switch (caret.edge) {
      _CaretEdge.top => Offset(center - half, 0),
      _CaretEdge.bottom => Offset(
        center - half,
        size.height - childSize.height,
      ),
      _CaretEdge.right => Offset(size.width - childSize.width, center - half),
    };
  }

  @override
  bool shouldRelayout(final _CaretLayout oldDelegate) =>
      caret != oldDelegate.caret;
}

class _CaretPainter extends CustomPainter {
  const _CaretPainter({required this.edge, required this.color});

  static const _seamOverlap = AppStroke.thin;

  final _CaretEdge edge;
  final Color color;

  @override
  void paint(final Canvas canvas, final Size size) {
    final points = switch (edge) {
      _CaretEdge.top => [
        Offset(0, size.height + _seamOverlap),
        Offset(size.width / 2, 0),
        Offset(size.width, size.height + _seamOverlap),
      ],
      _CaretEdge.bottom => [
        const Offset(0, -_seamOverlap),
        Offset(size.width / 2, size.height),
        Offset(size.width, -_seamOverlap),
      ],
      _CaretEdge.right => [
        const Offset(-_seamOverlap, 0),
        Offset(size.width, size.height / 2),
        Offset(-_seamOverlap, size.height),
      ],
    };
    canvas.drawPath(Path()..addPolygon(points, true), Paint()..color = color);
  }

  @override
  bool shouldRepaint(final _CaretPainter oldDelegate) =>
      edge != oldDelegate.edge || color != oldDelegate.color;
}

class _Beacon extends HookWidget {
  const _Beacon({super.key});

  /// How far the pulse spreads beyond the target.
  static const spread = AppSpacing.smMd;
  static const _period = Duration(milliseconds: 1600);

  @override
  Widget build(final BuildContext context) {
    final color = Theme.of(context).colorScheme.inverseSurface;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final controller = useAnimationController(duration: _period);

    useEffect(() {
      if (reduceMotion) {
        controller.value = 0;
      } else {
        controller.repeat();
      }
      return null;
    }, [reduceMotion]);

    // Painted, not built from FadeTransition/ScaleTransition: their opacity
    // and transform layers make iOS 26's native tab bar drop its touches.
    return CustomPaint(
      painter: _BeaconPainter(pulse: controller, color: color),
    );
  }
}

/// A stadium hugging the target, plus a ring that eases outward and fades.
class _BeaconPainter extends CustomPainter {
  _BeaconPainter({required this.pulse, required this.color})
    : super(repaint: pulse);

  final Animation<double> pulse;
  final Color color;

  RRect _stadium(final Rect rect) =>
      RRect.fromRectAndRadius(rect, Radius.circular(rect.shortestSide / 2));

  @override
  void paint(final Canvas canvas, final Size size) {
    final target = (Offset.zero & size).deflate(_Beacon.spread);
    final t = Curves.easeOut.transform(pulse.value);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = AppStroke.medium;

    canvas
      ..drawRRect(
        _stadium(target.inflate(AppStroke.medium / 2)),
        stroke..color = color,
      )
      ..drawRRect(
        _stadium(target.inflate(AppStroke.medium / 2 + _Beacon.spread * t)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = AppStroke.medium
          ..color = color.withValues(alpha: 1 - t),
      );
  }

  @override
  bool shouldRepaint(final _BeaconPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.pulse != pulse;
}
