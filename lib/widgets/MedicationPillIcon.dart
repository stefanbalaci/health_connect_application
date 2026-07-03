import 'dart:math' as math;

import 'package:flutter/material.dart';

enum _Glyph { combo, capsule, tablet }

/// The generic capsule + scored-tablet medication mark (used for the nav tab
/// and as the fallback for unknown forms). Material has no capsule+tablet icon.
class MedicationPillIcon extends StatelessWidget {
  final double size;
  final Color color;

  const MedicationPillIcon({super.key, this.size = 24, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _MedPainter(color, _Glyph.combo)),
    );
  }
}

/// Renders a medication glyph that varies with its [form] using the bundled
/// medicine-form artwork (`assets/medication_icons/*.png`). Unknown/OTHER forms
/// fall back to the painted capsule+tablet mark tinted with [color].
class MedicationFormIcon extends StatelessWidget {
  final String? form;
  final double size;
  final Color color;

  const MedicationFormIcon({
    super.key,
    required this.form,
    this.size = 24,
    this.color = const Color(0xFF1A9882),
  });

  /// Maps a [MedicationForm] enum name to its asset file (sans extension).
  static const Map<String, String> _asset = {
    'TABLET': 'tablet',
    'CAPSULE': 'capsule',
    'SYRUP': 'syrup',
    'DROPS': 'drops',
    'INJECTION': 'syringe',
    'CREAM': 'cream',
    'INHALER': 'inhaler',
    'PATCH': 'patch',
    'SACHET': 'sachet',
    'SPRAY': 'spray',
  };

  @override
  Widget build(BuildContext context) {
    final name = _asset[form];
    if (name == null) {
      // OTHER / null / unknown → the generic capsule+tablet mark.
      return MedicationPillIcon(size: size, color: color);
    }
    return Image.asset(
      'assets/medication_icons/$name.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}

class _MedPainter extends CustomPainter {
  final Color color;
  final _Glyph glyph;
  _MedPainter(this.color, this.glyph);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24.0;
    switch (glyph) {
      case _Glyph.combo:
        _capsule(canvas, s, center: Offset(9.2 * s, 9.2 * s), length: 15, width: 8.2);
        _tablet(canvas, s, center: Offset(16.6 * s, 16.6 * s), radius: 5.4, diagonalScore: true);
        break;
      case _Glyph.capsule:
        _capsule(canvas, s, center: Offset(12 * s, 12 * s), length: 17, width: 9);
        break;
      case _Glyph.tablet:
        _tablet(canvas, s, center: Offset(12 * s, 12 * s), radius: 8, diagonalScore: false);
        break;
    }
  }

  void _capsule(Canvas canvas, double s,
      {required Offset center, required double length, required double width}) {
    final stroke = 2.2 * s;
    final outline = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-math.pi / 4);
    final rrect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: length * s, height: width * s),
      Radius.circular(width / 2 * s),
    );
    canvas.drawRRect(rrect, outline);
    canvas.drawLine(
      Offset(0, (-width / 2 + 0.4) * s),
      Offset(0, (width / 2 - 0.4) * s),
      outline,
    );
    canvas.restore();
  }

  void _tablet(Canvas canvas, double s,
      {required Offset center, required double radius, required bool diagonalScore}) {
    final r = radius * s;
    final bounds = Rect.fromCircle(center: center, radius: r + 2 * s);
    canvas.saveLayer(bounds, Paint());
    canvas.drawCircle(center, r, Paint()..color = color);
    final score = Paint()
      ..blendMode = BlendMode.clear
      ..strokeWidth = 1.5 * s
      ..strokeCap = StrokeCap.round;
    final d = r * 0.9;
    if (diagonalScore) {
      canvas.drawLine(Offset(center.dx - d, center.dy - d),
          Offset(center.dx + d, center.dy + d), score);
    } else {
      canvas.drawLine(Offset(center.dx - d, center.dy),
          Offset(center.dx + d, center.dy), score);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MedPainter old) =>
      old.color != color || old.glyph != glyph;
}
