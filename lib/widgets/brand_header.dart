import 'package:flutter/material.dart';
import '../theme/app_palette.dart';

/// App mark: a gradient squircle carrying a stylised "Z". Painted rather than
/// shipped as an asset so it follows the accent colour the user picks in
/// Settings and stays crisp at any size.
class ZanhaLogo extends StatelessWidget {
  final double size;
  const ZanhaLogo({super.key, this.size = 64});

  @override
  Widget build(BuildContext context) {
    final accent = context.accent;
    final hsl = HSLColor.fromColor(accent);
    final light =
        hsl.withLightness((hsl.lightness + 0.10).clamp(0.0, 1.0)).toColor();
    final dark =
        hsl.withLightness((hsl.lightness - 0.14).clamp(0.0, 1.0)).toColor();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [light, dark],
        ),
        borderRadius: BorderRadius.circular(size * 0.3),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.32),
            blurRadius: size * 0.22,
            offset: Offset(0, size * 0.09),
          ),
        ],
      ),
      child: CustomPaint(painter: const _ZanhaMark()),
    );
  }
}

class _ZanhaMark extends CustomPainter {
  const _ZanhaMark();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final stroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.115
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(
      Path()
        ..moveTo(s * 0.29, s * 0.31)
        ..lineTo(s * 0.71, s * 0.31)
        ..lineTo(s * 0.29, s * 0.69)
        ..lineTo(s * 0.71, s * 0.69),
      stroke,
    );
  }

  @override
  bool shouldRepaint(_ZanhaMark oldDelegate) => false;
}

class BrandWelcomeHeader extends StatelessWidget {
  final String title;
  const BrandWelcomeHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final accent = context.accent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ZanhaPay Mobil Pos\'a',
          style: TextStyle(
            color: accent,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            color: accent,
            fontSize: 34,
            fontWeight: FontWeight.w900,
            height: 1.15,
          ),
        ),
      ],
    );
  }
}
