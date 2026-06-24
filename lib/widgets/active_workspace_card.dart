import 'package:flutter/material.dart';

class ActiveWorkspaceCard extends StatelessWidget {
  final String productName;
  final int currentStep;
  final int totalSteps;
  final VoidCallback onContinue;

  const ActiveWorkspaceCard({
    super.key,
    required this.productName,
    required this.currentStep,
    required this.totalSteps,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final double percentage = totalSteps > 0 ? (currentStep / totalSteps) : 0;
    final percentageString = '${(percentage * 100).toInt()}%';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D6940).withOpacity(0.05),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.4),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                height: 192,
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFCCEA9D),
                ),
                child: const Center(
                  child: Icon(
                    Icons.handyman,
                    size: 64,
                    color: Color(0xFF1D6940),
                  ),
                ),
              ),
              Positioned(
                bottom: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: const Text(
                    'In Progress',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1D6940),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1C19),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Step $currentStep of $totalSteps',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF404941),
                      ),
                    ),
                    Text(
                      percentageString,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF404941),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEEEE9),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: percentage.clamp(0.0, 1.0),
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1D6940),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: onContinue,
                    icon: const Icon(Icons.play_arrow, size: 20),
                    label: const Text(
                      'Continue Project',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1D6940),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}