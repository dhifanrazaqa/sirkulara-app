import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/visual_validation_model.dart';

class ValidationResultCard extends StatelessWidget {
  final VisualValidationModel result;

  const ValidationResultCard({
    super.key,
    required this.result,
  });

  Color _getStatusColor() {
    switch (result.status) {
      case 'good':
        return const Color(0xFF2ECC71); // Green
      case 'needs_improvement':
        return const Color(0xFFE67E22); // Orange/Amber
      case 'manual_override':
        return Colors.blueGrey;
      case 'failed':
      default:
        return const Color(0xFFE74C3C); // Red
    }
  }

  String _getStatusLabel() {
    switch (result.status) {
      case 'good':
        return 'Lolos Verifikasi';
      case 'needs_improvement':
        return 'Perlu Perbaikan';
      case 'manual_override':
        return 'Dilewati Manual';
      case 'failed':
      default:
        return 'Verifikasi Gagal';
    }
  }

  IconData _getStatusIcon() {
    switch (result.status) {
      case 'good':
        return Icons.check_circle_outline;
      case 'needs_improvement':
        return Icons.info_outline;
      case 'manual_override':
        return Icons.help_outline;
      case 'failed':
      default:
        return Icons.cancel_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final statusLabel = _getStatusLabel();
    final statusIcon = _getStatusIcon();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: statusColor.withOpacity(0.3), width: 1.5),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Score circular progress indicator
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      height: 56,
                      width: 56,
                      child: CircularProgressIndicator(
                        value: result.score / 100,
                        backgroundColor: Colors.grey.shade200,
                        color: statusColor,
                        strokeWidth: 5,
                      ),
                    ),
                    Text(
                      '${result.score}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
                const Gap(16),
                // Status badge and timestamp
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, color: statusColor, size: 16),
                            const Gap(4),
                            Text(
                              statusLabel,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Gap(4),
                      const Text(
                        'Hasil Analisis Kopilot AI',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (result.feedback.isNotEmpty) ...[
              const Divider(height: 24),
              const Text(
                'Feedback Konstruktif:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const Gap(8),
              ...result.feedback.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 6.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.arrow_right, color: statusColor, size: 20),
                        const Gap(4),
                        Expanded(
                          child: Text(
                            item,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textPrimary,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}
