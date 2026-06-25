import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../services/auth_service.dart';
import '../../services/catalog_service.dart';
import '../../services/workspace_service.dart';

class ProjectOverviewArguments {
  final String productId;
  final String materialType;
  final double weightGrams;

  const ProjectOverviewArguments({
    required this.productId,
    required this.materialType,
    required this.weightGrams,
  });
}

class ProjectOverviewScreen extends StatefulWidget {
  const ProjectOverviewScreen({super.key});

  @override
  State<ProjectOverviewScreen> createState() => _ProjectOverviewScreenState();
}

class _ProjectOverviewScreenState extends State<ProjectOverviewScreen> {
  bool _isStarting = false;

  String _formatMaterial(String materialType) {
    switch (materialType) {
      case 'sachet_multilayer':
        return 'Sachet';
      case 'botol_pet':
        return 'Botol PET';
      case 'kertas':
        return 'Kertas';
      case 'kain':
        return 'Kain';
      default:
        return 'Lainnya';
    }
  }

  Future<void> _startProject(
    String productId,
    String materialType,
    double weightGrams,
  ) async {
    final auth = context.read<AuthService>();
    final user = auth.currentUser;
    if (user == null) return;

    setState(() => _isStarting = true);

    try {
      await context.read<WorkspaceService>().startWorkspace(
            user.uid,
            productId,
            materialType,
            weightGrams,
          );
      if (!mounted) return;
      Navigator.pushNamed(context, '/workspace-step');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFBA1A1A),
          content: Text('Gagal memulai proyek.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isStarting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as ProjectOverviewArguments;
    
    final catalogProduct = CatalogService().getProductById(args.productId);
    final String title = catalogProduct != null 
        ? catalogProduct['title']?.toString() ?? args.productId 
        : args.productId.replaceAll('_', ' ').split(' ').map((str) => str.isNotEmpty ? '${str[0].toUpperCase()}${str.substring(1)}' : '').join(' ');

    final String imageUrl = catalogProduct != null 
        ? catalogProduct['imageUrl']?.toString() ?? ''
        : 'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?auto=format&fit=crop&w=900&q=60';

    final String difficulty = catalogProduct != null 
        ? catalogProduct['difficulty']?.toString() ?? 'sedang'
        : 'sedang';

    final String youtubeUrl = catalogProduct != null 
        ? catalogProduct['youtubeUrl']?.toString() ?? ''
        : '';

    final String description = catalogProduct != null 
        ? catalogProduct['description']?.toString() ?? 'Proyek daur ulang unik untuk mendaur ulang limbah secara fungsional.'
        : 'Proyek daur ulang unik untuk mendaur ulang limbah secara fungsional.';

    final String duration = catalogProduct != null
        ? catalogProduct['estimated_time']?.toString() ?? '45-60 min'
        : '45-60 min';

    final int estValue = catalogProduct != null 
        ? (catalogProduct['estimatedValue'] as num?)?.toInt() ?? 30000
        : 30000;

    final List<String> supplies = catalogProduct != null && catalogProduct['supplies_needed'] != null
        ? List<String>.from(catalogProduct['supplies_needed'] as List)
        : ['1 ${args.materialType}', '1 Gunting', '1 Lem'];

    final costAndPrice = catalogProduct != null ? catalogProduct['estimated_cost_and_price'] as Map<String, dynamic>? : null;
    final String suggestedPrice = costAndPrice != null ? costAndPrice['suggested_price']?.toString() ?? '25k - 35k' : '25k - 35k';
    final String profit = costAndPrice != null ? costAndPrice['profit']?.toString() ?? '16.5k - 24.5k' : '16.5k - 24.5k';

    final marketSegments = catalogProduct != null ? catalogProduct['market_segment'] as Map<String, dynamic>? : null;

    final steps = catalogProduct != null && catalogProduct['steps'] != null
        ? List<Map<String, dynamic>>.from(catalogProduct['steps'] as List)
        : [];

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF4),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.maybePop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back, color: Color(0xFF1D6940), size: 20),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1D6940),
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.more_vert, color: Color(0xFF1D6940), size: 20),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background organic radial gradient simulation
          Positioned(
            top: 0,
            right: 0,
            width: 300,
            height: 300,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFCCEA9D).withValues(alpha: 0.2),
              ),
            ),
          ),
          Positioned.fill(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 8, bottom: 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero Image Card
                  Container(
                    height: 320,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                            errorWidget: (context, url, error) => Container(
                              color: const Color(0xFFEEEEE9),
                              child: const Icon(Icons.image, size: 64, color: Colors.grey),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black87,
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 24,
                          left: 24,
                          right: 24,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFCCEA9D),
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                    child: Text(
                                      _formatMaterial(args.materialType),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF364E12),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1D6940),
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                    child: Text(
                                      difficulty.toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Watch Tutorial link overlay
                        if (youtubeUrl.isNotEmpty)
                          Positioned(
                            top: 24,
                            right: 24,
                            child: GestureDetector(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: youtubeUrl));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Link YouTube disalin ke papan klip!'),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  borderRadius: BorderRadius.circular(99),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.play_circle, color: Color(0xFF1D6940), size: 18),
                                    SizedBox(width: 6),
                                    Text(
                                      'Watch Tutorial',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1D6940),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Gap(24),

                  // Project Metadata Grid
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetadataCard(
                          icon: Icons.schedule,
                          label: 'Durasi',
                          value: duration,
                        ),
                      ),
                      const Gap(16),
                      Expanded(
                        child: _buildMetadataCard(
                          icon: Icons.payments,
                          label: 'Estimasi Biaya',
                          value: 'Rp ${(estValue / 1000).toStringAsFixed(0)}k',
                        ),
                      ),
                    ],
                  ),
                  const Gap(24),

                  // Tentang Proyek
                  const Text(
                    'Tentang Proyek',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1C19),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: Color(0xFF404941),
                    ),
                  ),
                  const Gap(24),

                  // Alat & Bahan
                  const Text(
                    'Alat & Bahan',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1C19),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: supplies.map((supply) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEEEE9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          supply,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF404941),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const Gap(24),

                  // Potensi Komersial
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D6940).withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFF1D6940).withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.trending_up, color: Color(0xFF1D6940)),
                            SizedBox(width: 8),
                            Text(
                              'Potensi Komersial',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1D6940),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Harga Jual',
                                    style: TextStyle(fontSize: 12, color: Color(0xFF707A71)),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    suggestedPrice,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1A1C19),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Estimasi Profit',
                                    style: TextStyle(fontSize: 12, color: Color(0xFF707A71)),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    profit,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1D6940),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Gap(24),

                  // Segmen Pasar
                  if (marketSegments != null) ...[
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 15,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: const Color(0xFFEEEEE9),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.groups, color: Color(0xFF1D6940)),
                              SizedBox(width: 8),
                              Text(
                                'Segmen Pasar',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A1C19),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ...marketSegments.entries.map((entry) {
                            final segmentName = entry.key;
                            final segmentDesc = entry.value?.toString() ?? '';
                            // Try to extract price from description if possible, e.g. "best at 25,000"
                            final priceMatch = RegExp(r'(\d{2,3},\d{3})|(\d{2,3}k)').firstMatch(segmentDesc);
                            final String priceStr = priceMatch != null ? 'Rp ${priceMatch.group(0)}' : '';

                            return Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: Color(0xFFBFC9BF),
                                    width: 0.5,
                                  ),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        segmentName,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1A1C19),
                                        ),
                                      ),
                                      if (priceStr.isNotEmpty)
                                        Text(
                                          priceStr,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1D6940),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    segmentDesc,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF707A71),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const Gap(24),
                  ],

                  // Tahapan Kerja
                  if (steps.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Tahapan Kerja',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1C19),
                          ),
                        ),
                        Text(
                          '${steps.length} Langkah',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1D6940),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: steps.length > 3 ? 3 : steps.length,
                      itemBuilder: (context, index) {
                        final step = steps[index];
                        final stepNumber = step['stepNumber'] ?? (index + 1);
                        final stepTitle = step['title']?.toString() ?? 'Langkah';
                        final stepInstruction = step['instruction']?.toString() ?? '';

                        final bool isLast = index == (steps.length > 3 ? 2 : steps.length - 1);

                        return Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: index == 0 ? const Color(0xFF1D6940) : const Color(0xFFA8F3BF),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '$stepNumber',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: index == 0 ? Colors.white : const Color(0xFF00210F),
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (!isLast)
                                      Container(
                                        width: 2,
                                        height: 60,
                                        color: const Color(0xFFBFC9BF),
                                      ),
                                  ],
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.8),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          stepTitle,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1A1C19),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          stepInstruction,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF707A71),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],
                        );
                      },
                    ),
                    if (steps.length > 3) ...[
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Icon(Icons.more_horiz, color: Color(0xFF707A71)),
                        ),
                      ),
                      // Last step summary
                      Builder(
                        builder: (context) {
                          final step = steps.last;
                          final stepNumber = step['stepNumber'] ?? steps.length;
                          final stepTitle = step['title']?.toString() ?? 'Langkah Akhir';
                          final stepInstruction = step['instruction']?.toString() ?? '';

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFA8F3BF),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '$stepNumber',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF00210F),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        stepTitle,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1A1C19),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        stepInstruction,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF707A71),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
          // Bottom Action Button Area
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    const Color(0xFFFAFAF4),
                    const Color(0xFFFAFAF4).withValues(alpha: 0.9),
                    const Color(0xFFFAFAF4).withValues(alpha: 0.0),
                  ],
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isStarting
                      ? null
                      : () => _startProject(
                            args.productId,
                            args.materialType,
                            args.weightGrams,
                          ),
                  icon: _isStarting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.play_arrow, size: 20),
                  label: Text(
                    _isStarting ? 'Menyiapkan...' : 'Mulai Proyek',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D6940),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFF1D6940).withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF1D6940)),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF707A71),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1C19),
            ),
          ),
        ],
      ),
    );
  }
}
