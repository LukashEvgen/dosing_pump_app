import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme.dart';

class LiquidLevelIndicator extends StatefulWidget {
  final double percent; // 0.0 - 100.0

  const LiquidLevelIndicator({super.key, required this.percent});

  @override
  State<LiquidLevelIndicator> createState() => _LiquidLevelIndicatorState();
}

class _LiquidLevelIndicatorState extends State<LiquidLevelIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  Color get _liquidColor {
    if (widget.percent > 50) return AppTheme.accent;
    if (widget.percent > 20) return AppTheme.warning;
    return AppTheme.danger;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 120,
          height: 160,
          child: AnimatedBuilder(
            animation: _waveController,
            builder: (context, _) {
              return CustomPaint(
                painter: _BottlePainter(
                  percent: widget.percent / 100,
                  wavePhase: _waveController.value * 2 * math.pi,
                  color: _liquidColor,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${widget.percent.toStringAsFixed(0)}%',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: _liquidColor,
          ),
        ),
        const Text(
          'Рівень рідини',
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.onSurfaceMuted,
          ),
        ),
      ],
    );
  }
}

class _BottlePainter extends CustomPainter {
  final double percent;
  final double wavePhase;
  final Color color;

  _BottlePainter({
    required this.percent,
    required this.wavePhase,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Bottle outline path
    final bottlePath = _buildBottlePath(w, h);

    // Background bottle
    final bgPaint = Paint()
      ..color = AppTheme.surfaceCard
      ..style = PaintingStyle.fill;
    canvas.drawPath(bottlePath, bgPaint);

    // Liquid fill with wave
    if (percent > 0) {
      final liquidHeight = h * 0.88 * percent;
      final liquidTop = h * 0.12 + h * 0.88 * (1 - percent);

      final liquidPath = Path();
      liquidPath.moveTo(0, h);

      // Bottom corners
      liquidPath.lineTo(w * 0.1, h);
      liquidPath.lineTo(w * 0.9, h);
      liquidPath.lineTo(w, h);

      // Right side
      liquidPath.lineTo(w, liquidTop + liquidHeight * 0.1);

      // Wavy top
      final waveAmp = liquidHeight > 8 ? 4.0 : 1.0;
      for (double x = w; x >= 0; x -= 2) {
        final y = liquidTop +
            waveAmp * math.sin((x / w) * 4 * math.pi + wavePhase);
        liquidPath.lineTo(x, y);
      }

      liquidPath.lineTo(0, liquidTop);
      liquidPath.close();

      // Clip to bottle shape
      canvas.save();
      canvas.clipPath(bottlePath);

      final liquidPaint = Paint()
        ..color = color.withValues(alpha: 0.75)
        ..style = PaintingStyle.fill;
      canvas.drawPath(liquidPath, liquidPaint);

      // Shine overlay
      final shinePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.08)
        ..style = PaintingStyle.fill;
      final shinePath = Path()
        ..moveTo(w * 0.15, liquidTop)
        ..lineTo(w * 0.35, liquidTop)
        ..lineTo(w * 0.35, h)
        ..lineTo(w * 0.15, h)
        ..close();
      canvas.drawPath(shinePath, shinePaint);

      canvas.restore();
    }

    // Bottle border
    final borderPaint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(bottlePath, borderPaint);

    // Tick marks
    final tickPaint = Paint()
      ..color = AppTheme.onSurfaceMuted.withValues(alpha: 0.3)
      ..strokeWidth = 1;
    for (int i = 1; i < 4; i++) {
      final y = h * 0.12 + (h * 0.88) * i / 4;
      canvas.drawLine(
        Offset(w * 0.75, y),
        Offset(w * 0.88, y),
        tickPaint,
      );
    }
  }

  Path _buildBottlePath(double w, double h) {
    final path = Path();
    // Neck
    path.moveTo(w * 0.35, 0);
    path.lineTo(w * 0.35, h * 0.08);
    path.quadraticBezierTo(w * 0.1, h * 0.15, w * 0.08, h * 0.22);
    // Left side
    path.lineTo(w * 0.06, h * 0.90);
    path.quadraticBezierTo(w * 0.06, h, w * 0.15, h);
    // Bottom
    path.lineTo(w * 0.85, h);
    path.quadraticBezierTo(w * 0.94, h, w * 0.94, h * 0.90);
    // Right side
    path.lineTo(w * 0.92, h * 0.22);
    path.quadraticBezierTo(w * 0.9, h * 0.15, w * 0.65, h * 0.08);
    path.lineTo(w * 0.65, 0);
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(_BottlePainter old) =>
      old.percent != percent ||
      old.wavePhase != wavePhase ||
      old.color != color;
}
