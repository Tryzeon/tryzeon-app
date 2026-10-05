import 'dart:ui' show lerpDouble;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:tryzeon/core/theme/app_theme.dart';

/// Single-pointer gestures are left to the surrounding scrollables, so paging
/// and pull-to-refresh keep working. The zoomed copy is drawn in the root
/// overlay so it rises above every piece of chrome stacked over [child].
class PinchToZoom extends HookWidget {
  const PinchToZoom({super.key, required this.child, this.maxScale = 4});

  final Widget child;
  final double maxScale;

  @override
  Widget build(final BuildContext context) {
    final frame = useValueNotifier(_ZoomFrame.identity);
    final entry = useRef<OverlayEntry?>(null);
    final isZooming = useState(false);
    final pinchStart = useRef<({Offset focal, _ZoomFrame frame})?>(null);
    final pointers = useRef(<int>{});
    final releaseFrom = useRef(_ZoomFrame.identity);
    final release = useAnimationController(duration: AppDuration.standard);

    useEffect(() {
      void settle() => frame.value = _ZoomFrame.lerp(
        releaseFrom.value,
        _ZoomFrame.identity,
        AppCurves.emphasized.transform(release.value),
      );
      void finish(final AnimationStatus status) {
        if (!status.isCompleted) return;
        entry.value
          ?..remove()
          ..dispose();
        entry.value = null;
        isZooming.value = false;
      }

      release
        ..addListener(settle)
        ..addStatusListener(finish);
      return () {
        release
          ..removeListener(settle)
          ..removeStatusListener(finish);
        entry.value
          ?..remove()
          ..dispose();
      };
    }, const []);

    void showZoomLayer() {
      final overlay = Overlay.of(context, rootOverlay: true);
      final box = context.findRenderObject()! as RenderBox;
      final rect =
          box.localToGlobal(
            Offset.zero,
            ancestor: overlay.context.findRenderObject(),
          ) &
          box.size;
      final layer = OverlayEntry(
        builder: (final context) =>
            _ZoomLayer(rect: rect, frame: frame, child: child),
      );
      overlay.insert(layer);
      entry.value = layer;
      isZooming.value = true;
    }

    void handleScaleStart(final ScaleStartDetails details) {
      if (details.pointerCount < 2) return;
      release.stop();
      if (entry.value == null) showZoomLayer();
      pinchStart.value = (focal: details.localFocalPoint, frame: frame.value);
    }

    void handleScaleUpdate(final ScaleUpdateDetails details) {
      final start = pinchStart.value;
      if (start == null) return;
      final scale = (start.frame.scale * details.scale).clamp(1.0, maxScale);
      final anchor = (start.focal - start.frame.offset) / start.frame.scale;
      frame.value = _ZoomFrame(
        scale: scale,
        offset: details.localFocalPoint - anchor * scale,
      );
    }

    void handleScaleEnd(final ScaleEndDetails details) =>
        pinchStart.value = null;

    // The recognizer reports no end for fingers lifted after an earlier one
    // left without moving, so the release follows the raw pointer count.
    void handlePointerGone(final PointerEvent event) {
      pointers.value.remove(event.pointer);
      if (pointers.value.length >= 2 ||
          entry.value == null ||
          release.isAnimating) {
        return;
      }
      releaseFrom.value = frame.value;
      release.forward(from: 0);
    }

    return Listener(
      onPointerDown: (final event) => pointers.value.add(event.pointer),
      onPointerUp: handlePointerGone,
      onPointerCancel: handlePointerGone,
      child: RawGestureDetector(
        gestures: {
          _PinchGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<_PinchGestureRecognizer>(
                _PinchGestureRecognizer.new,
                (final recognizer) => recognizer
                  ..onStart = handleScaleStart
                  ..onUpdate = handleScaleUpdate
                  ..onEnd = handleScaleEnd,
              ),
        },
        child: Opacity(opacity: isZooming.value ? 0 : 1, child: child),
      ),
    );
  }
}

/// On iOS the scrollables measure a two-finger drag by its focal point, which
/// drifts past their slop before a natural pinch spreads past the scale slop.
/// Two fingers on the image always mean a pinch, so the arena is claimed as
/// soon as the second one lands.
class _PinchGestureRecognizer extends ScaleGestureRecognizer {
  @override
  void handleEvent(final PointerEvent event) {
    super.handleEvent(event);
    if (event is PointerDownEvent && pointerCount >= 2) {
      resolve(GestureDisposition.accepted);
    }
  }
}

class _ZoomLayer extends StatelessWidget {
  const _ZoomLayer({
    required this.rect,
    required this.frame,
    required this.child,
  });

  final Rect rect;
  final ValueNotifier<_ZoomFrame> frame;
  final Widget child;

  @override
  Widget build(final BuildContext context) {
    final scrim = Theme.of(context).colorScheme.scrim;

    return IgnorePointer(
      child: ValueListenableBuilder(
        valueListenable: frame,
        builder: (final context, final frame, final child) => Stack(
          children: [
            Positioned.fill(
              child: ColoredBox(
                color: scrim.withValues(
                  alpha: AppOpacity.overlay * (frame.scale - 1).clamp(0.0, 1.0),
                ),
              ),
            ),
            Positioned.fromRect(
              rect: rect,
              child: Transform(transform: frame.matrix, child: child),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

@immutable
class _ZoomFrame {
  const _ZoomFrame({required this.scale, required this.offset});

  static const identity = _ZoomFrame(scale: 1, offset: Offset.zero);

  final double scale;
  final Offset offset;

  Matrix4 get matrix =>
      Matrix4.diagonal3Values(scale, scale, 1)
        ..setTranslationRaw(offset.dx, offset.dy, 0);

  static _ZoomFrame lerp(
    final _ZoomFrame a,
    final _ZoomFrame b,
    final double t,
  ) => _ZoomFrame(
    scale: lerpDouble(a.scale, b.scale, t)!,
    offset: Offset.lerp(a.offset, b.offset, t)!,
  );
}
