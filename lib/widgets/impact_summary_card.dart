import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../core/utils/impact_calculator.dart';
import '../models/product_model.dart';
import '../models/user_model.dart';

class ImpactSummaryCard extends StatelessWidget {
  final UserModel? user;
  final List<Map<String, dynamic>> workspaces;
  final List<ProductModel> myProducts;
  final VoidCallback? onSeeAllPressed;

  const ImpactSummaryCard({
    super.key,
    required this.user,
    required this.workspaces,
    required this.myProducts,
    this.onSeeAllPressed,
  });

  String _getGrowthText(double growth) {
    if (growth > 0) {
      return '+${growth.toStringAsFixed(0)}%';
    } else if (growth < 0) {
      return '${growth.toStringAsFixed(0)}%';
    } else {
      return '0%';
    }
  }

  double _calculatePlasticGrowth() {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final fourteenDaysAgo = now.subtract(const Duration(days: 14));

    double currentWeekPlastic = 0;
    double lastWeekPlastic = 0;

    for (var w in workspaces) {
      final status = w['status'] as String? ?? 'in_progress';
      if (status != 'completed') continue;

      final completedAt =
          (w['completedAt'] as Timestamp?)?.toDate() ??
          (w['startedAt'] as Timestamp?)?.toDate();
      if (completedAt == null) continue;

      final weight = (w['weightGrams'] as num?)?.toDouble() ?? 0.0;

      if (completedAt.isAfter(sevenDaysAgo)) {
        currentWeekPlastic += weight;
      } else if (completedAt.isAfter(fourteenDaysAgo)) {
        lastWeekPlastic += weight;
      }
    }

    if (lastWeekPlastic == 0) {
      return currentWeekPlastic > 0 ? 100.0 : 0.0;
    }
    return ((currentWeekPlastic - lastWeekPlastic) / lastWeekPlastic) * 100.0;
  }

  double _calculateProductsGrowth() {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final fourteenDaysAgo = now.subtract(const Duration(days: 14));

    int currentWeekProducts = 0;
    int lastWeekProducts = 0;

    for (var p in myProducts) {
      final createdAt = p.createdAt.toDate();
      if (createdAt.isAfter(sevenDaysAgo)) {
        currentWeekProducts++;
      } else if (createdAt.isAfter(fourteenDaysAgo)) {
        lastWeekProducts++;
      }
    }

    if (lastWeekProducts == 0) {
      return currentWeekProducts > 0 ? 100.0 : 0.0;
    }
    return ((currentWeekProducts - lastWeekProducts) / lastWeekProducts) *
        100.0;
  }

  @override
  Widget build(BuildContext context) {
    final plasticGrowth = _calculatePlasticGrowth();
    final plasticProgress = ((user?.totalPlasticDiverted ?? 0) / 5000.0).clamp(
      0.0,
      1.0,
    );
    final co2Progress = ((user?.totalCo2Offset ?? 0) / 7500.0).clamp(0.0, 1.0);
    final productsGrowth = _calculateProductsGrowth();
    final productsProgress = myProducts.isEmpty
        ? 0.0
        : (myProducts.length / 5.0).clamp(0.05, 1.0);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D6940).withValues(alpha: 0.05),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Impact Summary',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1C19),
                ),
              ),
              if (onSeeAllPressed != null)
                GestureDetector(
                  onTap: onSeeAllPressed,
                  child: const Text(
                    'See all',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1D6940),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Item 1: Plastic Recycled
          _buildImpactItem(
            icon: Icons.local_drink,
            iconColor: const Color(0xFF516A2C),
            iconBgColor: const Color(0xFFCCEA9D),
            title: 'Plastic Recycled',
            growth: _getGrowthText(plasticGrowth),
            value: ImpactCalculator.formatWeight(
              user?.totalPlasticDiverted ?? 0,
            ),
            barColor: const Color(0xFF4D6628),
            barPercentage: plasticProgress,
          ),

          const Divider(color: Color(0xFFEEEEE9), height: 24),

          // Item 2: CO2 Saved
          _buildImpactItem(
            icon: Icons.eco,
            iconColor: const Color(0xFF171D13),
            iconBgColor: const Color(0xFFDEE5D4),
            title: 'CO2 Saved',
            growth: _getGrowthText(
              plasticGrowth,
            ), // CO2 growth is proportional to plastic recycled
            value: ImpactCalculator.formatCo2(user?.totalCo2Offset ?? 0),
            barColor: const Color(0xFF1D6940),
            barPercentage: co2Progress,
          ),

          const Divider(color: Color(0xFFEEEEE9), height: 24),

          // Item 3: Products Made
          _buildImpactItem(
            icon: Icons.inventory_2,
            iconColor: const Color(0xFF93000A),
            iconBgColor: const Color(0xFFFFDAD6),
            title: 'Products Made',
            growth: _getGrowthText(productsGrowth),
            value: '${myProducts.length} items',
            barColor: const Color(0xFF575E51),
            barPercentage: productsProgress,
          ),
        ],
      ),
    );
  }

  Widget _buildImpactItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String growth,
    required String value,
    required Color barColor,
    required double barPercentage,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1C19),
                    ),
                  ),
                  Row(
                    children: [
                      if (growth != '0%' && !growth.startsWith('0'))
                        const Icon(
                          Icons.arrow_upward,
                          size: 12,
                          color: Color(0xFF3A8257),
                        ),
                      Text(
                        growth,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: (growth == '0%' || growth.startsWith('0'))
                              ? const Color(0xFF404941)
                              : const Color(0xFF3A8257),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        height: 6,
                        color: const Color(0xFFEEEEE9),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: barPercentage,
                            child: Container(color: barColor),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF404941),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
