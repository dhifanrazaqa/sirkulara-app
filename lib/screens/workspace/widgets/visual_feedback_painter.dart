import 'dart:math';
import 'package:flutter/material.dart';
import '../../../models/visual_annotation_model.dart';

class VisualFeedbackPainter extends CustomPainter {
  final List<VisualAnnotationModel> annotations;

  VisualFeedbackPainter({required this.annotations});

  @override
  void paint(Canvas canvas, Size size) {
    for (final ann in annotations) {
      final actualX = ann.x * size.width;
      final actualY = ann.y * size.height;
      final position = Offset(actualX, actualY);

      Color strokeColor;
      switch (ann.type) {
        case 'warning':
          strokeColor = Colors.orange.shade700;
          _drawWarning(canvas, position, strokeColor);
          break;
        case 'arrow':
          strokeColor = Colors.blue.shade700;
          _drawArrow(canvas, position, strokeColor);
          break;
        case 'highlight':
          strokeColor = Colors.yellow.shade700;
          _drawHighlight(canvas, position, strokeColor);
          break;
        case 'circle':
        default:
          strokeColor = Colors.red.shade700;
          _drawCircle(canvas, position, strokeColor);
          break;
      }

      // Draw label text next to the shape
      _drawLabelText(canvas, position, ann.label, strokeColor, size);
    }
  }

  void _drawCircle(Canvas canvas, Offset position, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;
    
    // Draw glowing circles
    canvas.drawCircle(position, 22.0, paint);
    
    final paintGlow = Paint()
      ..color = color.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(position, 22.0, paintGlow);
  }

  void _drawArrow(Canvas canvas, Offset position, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final start = Offset(position.dx - 35, position.dy - 35);
    final end = position;

    // Draw main arrow shaft
    canvas.drawLine(start, end, paint);

    // Draw arrowhead
    final angle = atan2(end.dy - start.dy, end.dx - start.dx);
    final arrowSize = 10.0;
    final path = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(end.dx - arrowSize * cos(angle - pi / 6), end.dy - arrowSize * sin(angle - pi / 6))
      ..lineTo(end.dx - arrowSize * cos(angle + pi / 6), end.dy - arrowSize * sin(angle + pi / 6))
      ..close();

    final paintHead = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paintHead);
  }

  void _drawWarning(Canvas canvas, Offset position, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    // Draw triangle
    final size = 20.0;
    final path = Path()
      ..moveTo(position.dx, position.dy - size)
      ..lineTo(position.dx - size, position.dy + size)
      ..lineTo(position.dx + size, position.dy + size)
      ..close();

    canvas.drawPath(path, paint);

    final paintGlow = Paint()
      ..color = color.withOpacity(0.15)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paintGlow);

    // Draw exclamation mark (!)
    final textPainter = TextPainter(
      text: TextSpan(
        text: '!',
        style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(position.dx - textPainter.width / 2, position.dy - textPainter.height / 3),
    );
  }

  void _drawHighlight(Canvas canvas, Offset position, Color color) {
    final rectSize = 40.0;
    final rect = Rect.fromCenter(center: position, width: rectSize, height: rectSize);

    final paintFill = Paint()
      ..color = color.withOpacity(0.15)
      ..style = PaintingStyle.fill;
    canvas.drawRect(rect, paintFill);

    final paintBorder = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawRect(rect, paintBorder);
  }

  void _drawLabelText(Canvas canvas, Offset position, String text, Color color, Size canvasSize) {
    if (text.isEmpty) return;

    final textSpan = TextSpan(
      text: text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.bold,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(maxWidth: 150);

    // Position label slightly below the shape
    double lx = position.dx - textPainter.width / 2;
    double ly = position.dy + 30;

    // Clamp inside canvas bounds
    lx = lx.clamp(6.0, canvasSize.width - textPainter.width - 12.0);
    ly = ly.clamp(6.0, canvasSize.height - textPainter.height - 10.0);

    final rect = Rect.fromLTWH(
      lx - 6,
      ly - 4,
      textPainter.width + 12,
      textPainter.height + 8,
    );

    final bgPaint = Paint()
      ..color = color.withOpacity(0.88)
      ..style = PaintingStyle.fill;

    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));
    canvas.drawRRect(rrect, bgPaint);

    textPainter.paint(canvas, Offset(lx, ly));
  }

  @override
  bool shouldRepaint(covariant VisualFeedbackPainter oldDelegate) =>
      oldDelegate.annotations != annotations;
}
