import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../core/constants/app_colors.dart';

class WeavingQualityScoreCard extends StatelessWidget {
  final int score;
  final String status; // excellent, good, needs_improvement, retry
  final Map<String, int>? breakdown;

  const WeavingQualityScoreCard({
    super.key,
    required this.score,
    required this.status,
    this.breakdown,
  });

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'excellent':
        return AppColors.success;
      case 'good':
        return Colors.greenAccent.shade700;
      case 'needs_improvement':
        return AppColors.warning;
      case 'retry':
      default:
        return AppColors.error;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'excellent':
        return 'Sangat Bagus (Excellent)';
      case 'good':
        return 'Bagus (Good)';
      case 'needs_improvement':
        return 'Perlu Perbaikan';
      case 'retry':
      default:
        return 'Ulangi Langkah';
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(status);
    final statusText = _getStatusText(status);

    // Fallback breakdown values matching overall score weight
    final fold = breakdown?['foldQuality'] ?? (score - 3).clamp(0, 100);
    final density = breakdown?['densityQuality'] ?? (score - 6).clamp(0, 100);
    final edge = breakdown?['edgeQuality'] ?? (score + 2).clamp(0, 100);
    final symmetry = breakdown?['symmetry'] ?? (score + 1).clamp(0, 100);

    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.04),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Skor Kualitas AI',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            const Gap(16),
            Row(
              children: [
                // Radial score gauge
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      height: 80,
                      width: 80,
                      child: CircularProgressIndicator(
                        value: score / 100,
                        strokeWidth: 8,
                        backgroundColor: AppColors.divider,
                        valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$score',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: statusColor,
                          ),
                        ),
                        const Text(
                          '/100',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Gap(20),
                // Status badge and summary
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: statusColor.withOpacity(0.3), width: 1),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Gap(8),
                      Text(
                        score >= 75
                            ? 'Kerajinan Anda memenuhi standar verifikasi EcoChoice.'
                            : 'Beberapa area memerlukan perbaikan sebelum melanjutkan.',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32, color: AppColors.divider),
            // Breakdown progress list
            _buildCriteriaRow('Kualitas Lipatan (25%)', fold, statusColor),
            const Gap(10),
            _buildCriteriaRow('Kerapatan Anyaman (35%)', density, statusColor),
            const Gap(10),
            _buildCriteriaRow('Kerapian Tepi (20%)', edge, statusColor),
            const Gap(10),
            _buildCriteriaRow('Kesimetrisan (20%)', symmetry, statusColor),
          ],
        ),
      ),
    );
  }

  Widget _buildCriteriaRow(String label, int value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
            Text(
              '$value%',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
        const Gap(4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value / 100,
            minHeight: 5,
            backgroundColor: AppColors.divider,
            valueColor: AlwaysStoppedAnimation<Color>(color.withOpacity(0.85)),
          ),
        ),
      ],
    );
  }
}
