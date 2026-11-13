import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../ml/topic_progress_analytics.dart';

/// Small tactile trend line widget (Task 5.3) visualizing a topic's mastery
/// over time using [CustomPaint].
class TopicTrendLine extends StatelessWidget {
  final List<TopicTrendPoint> points;
  final bool isImproving;
  final double width;
  final double height;

  const TopicTrendLine({
    super.key,
    required this.points,
    this.isImproving = true,
    this.width = 68.0,
    this.height = 28.0,
  });

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const SizedBox();
    }

    final color = isImproving ? AppColors.success : AppColors.accent;

    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _TrendLinePainter(
          points: points,
          lineColor: color,
        ),
      ),
    );
  }
}

class _TrendLinePainter extends CustomPainter {
  final List<TopicTrendPoint> points;
  final Color lineColor;

  _TrendLinePainter({
    required this.points,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final dotPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    if (points.length == 1) {
      // Single attempt: draw a center dot with a subtle indicator
      final cy = size.height * (1.0 - points.first.mastery.clamp(0.05, 0.95));
      final cx = size.width / 2.0;
      canvas.drawCircle(Offset(cx, cy), 3.5, dotPaint);
      return;
    }

    final path = Path();
    final stepX = size.width / (points.length - 1);

    for (var i = 0; i < points.length; i++) {
      final x = i * stepX;
      // Invert y: 1.0 (100% mastery) at top (y=2), 0.0 at bottom (y=size.height-2)
      final normalizedMastery = points[i].mastery.clamp(0.0, 1.0);
      final y = 2.0 + (size.height - 4.0) * (1.0 - normalizedMastery);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }

      // Draw end dot on the latest point
      if (i == points.length - 1) {
        canvas.drawCircle(Offset(x, y), 3.0, dotPaint);
      }
    }

    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _TrendLinePainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.lineColor != lineColor;
  }
}
