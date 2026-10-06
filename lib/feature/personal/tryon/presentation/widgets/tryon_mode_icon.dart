import 'package:flutter/material.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_mode.dart';

/// Both modes share a framed garment so they read as one family; video adds a
/// play badge knocked out of the frame's corner. Drawn on a 24-unit grid.
class TryonModeIcon extends StatelessWidget {
  const TryonModeIcon({super.key, required this.mode});

  static const double size = 32;

  final TryonMode mode;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return CustomPaint(
      size: const Size.square(size),
      painter: _ModeIconPainter(
        mode: mode,
        ink: colorScheme.onSurface,
        fill: colorScheme.primaryContainer,
        badgeGlyph: colorScheme.surface,
      ),
    );
  }
}

class _ModeIconPainter extends CustomPainter {
  const _ModeIconPainter({
    required this.mode,
    required this.ink,
    required this.fill,
    required this.badgeGlyph,
  });

  static const double _grid = 24;
  static const double _frameStroke = 1.4;
  static const double _garmentStroke = 1.1;

  static const Offset _badgeCenter = Offset(18.6, 18.6);
  static const double _badgeRadius = 4.2;
  static const double _badgeGap = 1.3;

  final TryonMode mode;
  final Color ink;
  final Color fill;
  final Color badgeGlyph;

  @override
  void paint(final Canvas canvas, final Size size) {
    final isVideo = mode == TryonMode.video;
    canvas
      ..save()
      ..scale(size.width / _grid, size.height / _grid);
    if (isVideo) {
      canvas.saveLayer(const Rect.fromLTWH(0, 0, _grid, _grid), Paint());
    }

    final frame = RRect.fromLTRBR(
      4.5,
      2.5,
      19.5,
      21.5,
      const Radius.circular(4),
    );
    final garment = Path()
      ..moveTo(10.2, 7.6)
      ..quadraticBezierTo(12, 9.2, 13.8, 7.6)
      ..lineTo(16.2, 8.6)
      ..quadraticBezierTo(16.9, 9.9, 17.2, 11.4)
      ..lineTo(15.1, 11.9)
      ..lineTo(15.1, 16.2)
      ..quadraticBezierTo(12, 16.8, 8.9, 16.2)
      ..lineTo(8.9, 11.9)
      ..lineTo(6.8, 11.4)
      ..quadraticBezierTo(7.1, 9.9, 7.8, 8.6)
      ..close();

    canvas
      ..drawPath(garment, Paint()..color = fill)
      ..drawPath(garment, _stroke(_garmentStroke))
      ..drawRRect(frame, _stroke(_frameStroke));

    if (isVideo) {
      final play = Path()
        ..moveTo(_badgeCenter.dx - 1.2, _badgeCenter.dy - 1.9)
        ..lineTo(_badgeCenter.dx + 2.1, _badgeCenter.dy)
        ..lineTo(_badgeCenter.dx - 1.2, _badgeCenter.dy + 1.9)
        ..close();
      canvas
        ..drawCircle(
          _badgeCenter,
          _badgeRadius + _badgeGap,
          Paint()..blendMode = BlendMode.clear,
        )
        ..restore()
        ..drawCircle(_badgeCenter, _badgeRadius, Paint()..color = ink)
        ..drawPath(play, Paint()..color = badgeGlyph);
    }

    canvas.restore();
  }

  Paint _stroke(final double width) => Paint()
    ..color = ink
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round;

  @override
  bool shouldRepaint(final _ModeIconPainter oldDelegate) =>
      oldDelegate.mode != mode ||
      oldDelegate.ink != ink ||
      oldDelegate.fill != fill ||
      oldDelegate.badgeGlyph != badgeGlyph;
}
