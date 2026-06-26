import 'package:flutter/material.dart';

class WeavingCameraOverlay extends StatelessWidget {
  final String validationType;
  final int stepNumber;

  const WeavingCameraOverlay({
    super.key,
    required this.validationType,
    required this.stepNumber,
  });

  String _getGuidanceText() {
    switch (validationType) {
      case 'fold_alignment':
        if (stepNumber == 1) {
          return 'PANDUAN STRIP: Letakkan strip sachet secara vertikal sejajar garis tengah. Ukuran target lebar 2-3 cm.';
        }
        return 'PANDUAN LIPATAN: Sejajarkan garis lipatan strip dengan garis bantu vertikal tengah.';
      case 'fold_module':
        if (stepNumber == 6) {
          return 'PANDUAN MODUL V: Sejajarkan modul anyaman V Anda dengan siluet V di tengah.';
        }
        return 'PANDUAN MODUL KOTAK: Sejajarkan modul kotak Anda dengan siluet persegi di tengah.';
      case 'weave_base':
        return 'PANDUAN ALAS: Arahkan kamera tegak lurus sejajar dengan grid alas tas Anda.';
      case 'weave_wall':
        return 'PANDUAN DINDING: Foto dari samping. Sejajarkan tinggi dinding dengan garis pembatas.';
      case 'finishing':
        return 'PANDUAN FINISHING: Sejajarkan seluruh badan tas di tengah frame untuk melihat kerapian ujung.';
      case 'handle':
        return 'PANDUAN HANDLE: Tempatkan handle di dalam dua area bantuan kiri-kanan secara simetris.';
      default:
        return 'PANDUAN FOTO: Posisikan objek utama di tengah frame secara fokus.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: CameraOverlayPainter(
              validationType: validationType,
              stepNumber: stepNumber,
            ),
          ),
          Positioned(
            bottom: 120,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.65),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getGuidanceText(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CameraOverlayPainter extends CustomPainter {
  final String validationType;
  final int stepNumber;

  CameraOverlayPainter({
    required this.validationType,
    required this.stepNumber,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paintLine = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final paintGuide = Paint()
      ..color = const Color(0xFF2ECC71) // App primary (green)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    switch (validationType) {
      case 'fold_alignment':
        // Vertical guide line down the middle
        canvas.drawLine(Offset(centerX, 50), Offset(centerX, size.height - 150), paintGuide);

        // Draw 5x5 cm calibration reference box in bottom corner
        final boxPaint = Paint()
          ..color = Colors.yellow.withOpacity(0.6)
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke;
        
        final boxRect = Rect.fromLTWH(20, size.height - 230, 80, 80);
        canvas.drawRect(boxRect, boxPaint);
        
        final textPainter = TextPainter(
          text: const TextSpan(
            text: 'Skala 5x5cm',
            style: TextStyle(color: Colors.yellow, fontSize: 10, fontWeight: FontWeight.bold),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(20, size.height - 250));
        break;

      case 'fold_module':
        if (stepNumber == 6) {
          // Draw V shape outline outline target
          final path = Path()
            ..moveTo(centerX - 60, centerY - 60)
            ..lineTo(centerX, centerY + 60)
            ..lineTo(centerX + 60, centerY - 60)
            ..lineTo(centerX + 30, centerY - 60)
            ..lineTo(centerX, centerY)
            ..lineTo(centerX - 30, centerY - 60)
            ..close();
          canvas.drawPath(path, paintGuide);
        } else {
          // Draw square outline target (box module / kotak pertama)
          final rect = Rect.fromCenter(center: Offset(centerX, centerY), width: 120, height: 120);
          canvas.drawRect(rect, paintGuide);
        }
        break;

      case 'weave_base':
        // 3x3 thin grid guide
        final stepX = size.width / 3;
        final stepY = (size.height - 150) / 3;

        for (int i = 1; i < 3; i++) {
          canvas.drawLine(Offset(stepX * i, 50), Offset(stepX * i, size.height - 150), paintLine);
          canvas.drawLine(Offset(0, 50 + stepY * i), Offset(size.width, 50 + stepY * i), paintLine);
        }

        // Draw center alignment reticle
        final rect = Rect.fromCenter(center: Offset(centerX, centerY - 50), width: 150, height: 150);
        canvas.drawRect(rect, paintGuide);
        break;

      case 'weave_wall':
        // Horizontal guides for height check
        canvas.drawLine(Offset(20, centerY - 80), Offset(size.width - 20, centerY - 80), paintGuide);
        canvas.drawLine(Offset(20, centerY + 80), Offset(size.width - 20, centerY + 80), paintGuide);
        
        final textPainter = TextPainter(
          text: TextSpan(
            text: 'SEJAJARKAN DINDING SISI ${stepNumber == 9 ? "DEPAN" : "SAMPING"}',
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(centerX - textPainter.width / 2, centerY - 110));
        break;

      case 'finishing':
        // Silhouette guide representing the whole bag
        final rect = Rect.fromCenter(center: Offset(centerX, centerY), width: 220, height: 200);
        canvas.drawRect(rect, paintGuide);
        break;

      case 'handle':
        // Draw dual guides (left and right boxes) for symmetric handle alignment
        final leftBox = Rect.fromCenter(center: Offset(centerX - 80, centerY), width: 60, height: 150);
        final rightBox = Rect.fromCenter(center: Offset(centerX + 80, centerY), width: 60, height: 150);
        
        canvas.drawRect(leftBox, paintGuide);
        canvas.drawRect(rightBox, paintGuide);
        break;

      default:
        // Basic rectangular bounding box
        final rect = Rect.fromCenter(center: Offset(centerX, centerY), width: 200, height: 200);
        canvas.drawRect(rect, paintLine);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
