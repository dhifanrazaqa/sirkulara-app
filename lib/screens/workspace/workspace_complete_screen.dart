import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/utils/impact_calculator.dart';
import '../../services/workspace_service.dart';

class WorkspaceCompleteScreen extends StatefulWidget {
  const WorkspaceCompleteScreen({super.key});

  @override
  State<WorkspaceCompleteScreen> createState() => _WorkspaceCompleteScreenState();
}

class _WorkspaceCompleteScreenState extends State<WorkspaceCompleteScreen> with SingleTickerProviderStateMixin {
  late AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    return Consumer<WorkspaceService>(
      builder: (context, workspace, _) {
        final double plasticGrams = workspace.completedPlasticGrams ?? 0;
        final double co2Grams = workspace.completedCo2Grams ?? 0;

        String finalImageUrl = '';
        if (workspace.steps.isNotEmpty && workspace.steps.last.evidenceImageUrl != null) {
          finalImageUrl = workspace.steps.last.evidenceImageUrl!;
        }

        return Scaffold(
          backgroundColor: const Color(0xFFFAFAF4),
          body: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 280,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFFCCEA9D),
                        Color(0xFFFAFAF4),
                      ],
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    children: [
                      // Hero Section
                      AnimatedBuilder(
                        animation: _floatController,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, -5 * _floatController.value),
                            child: child,
                          );
                        },
                        child: Container(
                          height: 220,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF1D6940).withValues(alpha: 0.1),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: finalImageUrl.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: finalImageUrl,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                                        errorWidget: (context, url, error) => Container(
                                          color: const Color(0xFFEEEEE9),
                                          child: const Icon(Icons.image, size: 64, color: Colors.grey),
                                        ),
                                      )
                                    : Image.network(
                                        'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?auto=format&fit=crop&w=900&q=60',
                                        fit: BoxFit.cover,
                                      ),
                              ),
                              Positioned.fill(
                                child: Container(
                                  color: Colors.black26,
                                ),
                              ),
                              Center(
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1D6940).withValues(alpha: 0.9),
                                    shape: BoxShape.circle,
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 20,
                                        offset: Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.check_circle,
                                    color: Colors.white,
                                    size: 48,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Proyek Selesai!',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1C19),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Karya hebat untuk bumi yang lebih sehat.',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF404941),
                        ),
                      ),
                      const Gap(24),

                      // Impact Stats Section
                      Container(
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
                            const Text(
                              'Dampak Sirkular Anda',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A1C19),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildImpactRow(
                              icon: Icons.recycling,
                              iconColor: const Color(0xFF516A2C),
                              bgColor: const Color(0xFFCCEA9D),
                              label: 'Plastic Recycled',
                              value: '+${ImpactCalculator.formatWeight(plasticGrams)}',
                              progress: 0.85,
                            ),
                            const Divider(height: 16, color: Color(0xFFEEEEE9)),
                            _buildImpactRow(
                              icon: Icons.eco,
                              iconColor: const Color(0xFF1D6940),
                              bgColor: const Color(0xFFDEE5D4),
                              label: 'CO2 Saved',
                              value: '+${ImpactCalculator.formatCo2(co2Grams)}',
                              progress: 0.65,
                            ),
                            const Divider(height: 16, color: Color(0xFFEEEEE9)),
                            _buildImpactRow(
                              icon: Icons.inventory_2,
                              iconColor: const Color(0xFFBA1A1A),
                              bgColor: const Color(0xFFFFDAD6),
                              label: 'Product Made',
                              value: '+1 item',
                              progress: 1.0,
                            ),
                          ],
                        ),
                      ),
                      const Gap(16),

                      // Badge Card
                      Container(
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
                        child: Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: const BoxDecoration(
                                color: Color(0xFFCCEA9D),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.workspace_premium,
                                color: Color(0xFF516A2C),
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'BADGE BARU DIRAIH',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1D6940),
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Sirkulara Hero',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1A1C19),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: const [
                                Text(
                                  '+50',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF1D6940),
                                  ),
                                ),
                                Text(
                                  'XP POINT',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF404941),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Gap(16),

                      // Motivational Message
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(16),
                            bottomRight: Radius.circular(16),
                          ),
                          border: Border(
                            left: BorderSide(
                              color: Color(0xFF1D6940),
                              width: 4,
                            ),
                          ),
                        ),
                        child: const Text(
                          '"Satu langkah kecil hari ini adalah kontribusi besar bagi kelestarian esok. Teruslah berkarya!"',
                          style: TextStyle(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            color: Color(0xFF404941),
                          ),
                        ),
                      ),
                      const Gap(24),

                      // Action Buttons
                      Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: () {
                                workspace.resetWorkspace();
                                Navigator.pushReplacementNamed(context, '/home', arguments: 0);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1D6940),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Lihat di Dashboard',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: OutlinedButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    backgroundColor: Color(0xFF1D6940),
                                    content: Text('Tautan progres berhasil disalin ke papan klip!'),
                                  ),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF1D6940)),
                                foregroundColor: const Color(0xFF1D6940),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                              child: const Text(
                                'Bagikan Progres',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: OutlinedButton(
                              onPressed: () => Navigator.pushNamed(context, '/sell-product'),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF1D6940)),
                                foregroundColor: const Color(0xFF1D6940),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                              child: const Text(
                                'Jual di Marketplace',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Gap(24),

                      // Explore More Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Ingin mulai proyek baru? ',
                            style: TextStyle(fontSize: 13, color: Color(0xFF404941)),
                          ),
                          GestureDetector(
                            onTap: () {
                              workspace.resetWorkspace();
                              Navigator.pushReplacementNamed(context, '/home', arguments: 0);
                            },
                            child: const Text(
                              'Eksplor Ide',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1D6940),
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImpactRow({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String label,
    required String value,
    required double progress,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1C19),
                      ),
                    ),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1D6940),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  height: 6,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F4EE),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: progress,
                      child: Container(
                        decoration: BoxDecoration(
                          color: iconColor,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
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
