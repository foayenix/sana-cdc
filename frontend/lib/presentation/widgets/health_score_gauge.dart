import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:sana_app/core/theme/app_colors.dart';

class HealthScoreGauge extends StatefulWidget {
  final int score;
  final String status;
  final double size;

  const HealthScoreGauge({
    super.key,
    required this.score,
    required this.status,
    this.size = 200.0,
  });

  @override
  State<HealthScoreGauge> createState() => _HealthScoreGaugeState();
}

class _HealthScoreGaugeState extends State<HealthScoreGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 0,
      end: widget.score / 100,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _GaugePainter(
            progress: _animation.value,
            score: (widget.score * _animation.value).round(),
            status: widget.status,
          ),
        );
      },
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double progress;
  final int score;
  final String status;

  _GaugePainter({
    required this.progress,
    required this.score,
    required this.status,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;

    // Background circle
    final backgroundPaint = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Foreground arc (progress)
    final foregroundPaint = Paint()
      ..color = AppColors.getStatusColor(status)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;

    const startAngle = -math.pi / 2; // Start from top
    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      foregroundPaint,
    );

    // Draw score text
    final scoreTextPainter = TextPainter(
      text: TextSpan(
        text: score.toString(),
        style: TextStyle(
          fontSize: size.width / 4,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    scoreTextPainter.layout();
    scoreTextPainter.paint(
      canvas,
      Offset(
        center.dx - scoreTextPainter.width / 2,
        center.dy - scoreTextPainter.height / 2 - 10,
      ),
    );

    // Draw "/100" text
    final maxScoreTextPainter = TextPainter(
      text: TextSpan(
        text: '/100',
        style: TextStyle(
          fontSize: size.width / 12,
          color: AppColors.textSecondary,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    maxScoreTextPainter.layout();
    maxScoreTextPainter.paint(
      canvas,
      Offset(
        center.dx - maxScoreTextPainter.width / 2,
        center.dy + 10,
      ),
    );

    // Draw status text
    final statusTextPainter = TextPainter(
      text: TextSpan(
        text: _formatStatus(status),
        style: TextStyle(
          fontSize: size.width / 14,
          fontWeight: FontWeight.w600,
          color: AppColors.getStatusColor(status),
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    statusTextPainter.layout();
    statusTextPainter.paint(
      canvas,
      Offset(
        center.dx - statusTextPainter.width / 2,
        center.dy + 30,
      ),
    );
  }

  String _formatStatus(String status) {
    switch (status.toUpperCase()) {
      case 'NEEDS_SUPPORT':
        return 'Needs Support';
      case 'REBUILDING':
        return 'Rebuilding';
      case 'BALANCED':
        return 'Balanced';
      case 'THRIVING':
        return 'Thriving';
      case 'RADIANT':
        return 'Radiant';
      default:
        return status;
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.score != score ||
        oldDelegate.status != status;
  }
}
