import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../services/catalog_service.dart';
import '../../services/scanner_service.dart';
import '../workspace/project_overview_screen.dart';

class ScanResultScreen extends StatefulWidget {
  const ScanResultScreen({super.key});

  @override
  State<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends State<ScanResultScreen> {
  String? _lastErrorShown;

  String _getDetectedMaterialDescription(
    String materialType,
    double weightGrams,
  ) {
    switch (materialType) {
      case 'sachet_multilayer':
        final count = (weightGrams / 7.5).ceil();
        return '$count Sachet Plastik (${weightGrams.toStringAsFixed(0)}g)';
      case 'botol_pet':
        final count = (weightGrams / 25.0).ceil();
        return '$count Botol PET (${weightGrams.toStringAsFixed(0)}g)';
      case 'kertas':
        return 'Kertas (${weightGrams.toStringAsFixed(0)}g)';
      case 'kain':
        return 'Kain (${weightGrams.toStringAsFixed(0)}g)';
      default:
        return 'Material Lainnya (${weightGrams.toStringAsFixed(0)}g)';
    }
  }

  void _goToOverview(
    BuildContext context,
    Map<String, dynamic> recommendation,
  ) {
    final scan = context.read<ScannerService>().lastScanResult;
    if (scan == null) return;
    Navigator.pushNamed(
      context,
      '/project-overview',
      arguments: ProjectOverviewArguments(
        productId: recommendation['productName']?.toString() ?? 'tas_sachet',
        materialType: scan.materialType,
        weightGrams: scan.weightGrams,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ScannerService>(
      builder: (context, scanner, _) {
        if (scanner.errorMessage != null &&
            scanner.errorMessage != _lastErrorShown) {
          _lastErrorShown = scanner.errorMessage;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: const Color(0xFFBA1A1A),
                content: Text(scanner.errorMessage ?? ''),
              ),
            );
          });
        }

        final scan = scanner.lastScanResult;
        if (scan == null) {
          return const Scaffold(
            body: Center(child: Text('Belum ada hasil scan')),
          );
        }

        final hasAiRecommendations = scan.recommendations.any((r) {
          final name = r['productName']?.toString() ?? '';
          return CatalogService().getProductById(name) == null;
        });

        return Scaffold(
          backgroundColor: const Color.fromARGB(255, 255, 255, 30),
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(64),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.maybePop(context),
                          child: const Icon(
                            Icons.arrow_back,
                            color: Color(0xFF1A1C19),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Text(
                              'Sirkulara',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF404941),
                              ),
                            ),
                            Text(
                              'Hasil Scan',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1C19),
                              ),
                            ),
                          ],
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
                      child: IconButton(
                        icon: const Icon(
                          Icons.notifications_none,
                          size: 20,
                          color: Color(0xFF1A1C19),
                        ),
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          body: Stack(
            children: [
              // Header Gradient Background
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 200,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFCCEA9D), Color(0xFFFAFAF4)],
                    ),
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Detection Card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF1D6940,
                              ).withValues(alpha: 0.05),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 192,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: const Color(0xFFEEEEE9),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: CachedNetworkImage(
                                imageUrl: scan.imageUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                  ),
                                ),
                                errorWidget: (context, url, error) =>
                                    const Icon(
                                      Icons.image,
                                      color: Colors.grey,
                                      size: 48,
                                    ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Status Identifikasi',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF404941),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Material Terdeteksi',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1A1C19),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFCCEA9D),
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                  child: const Text(
                                    'Sirkulara Verified',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF364E12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _getDetectedMaterialDescription(
                                scan.materialType,
                                scan.weightGrams,
                              ),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1D6940),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Divider(color: Color(0xFFEEEEE9)),
                            const SizedBox(height: 8),
                            Row(
                              children: const [
                                Icon(
                                  Icons.check_circle,
                                  color: Color(0xFF516A2C),
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Semua material siap untuk diolah kembali.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF404941),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Gap(24),

                      // Recommendations Header
                      const Text(
                        'Proyek Kreasi Anda',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1C19),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Berdasarkan material yang tersedia, anda dapat memulai proyek ini:',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF404941),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Project Cards (List of Recommendations)
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: scan.recommendations.length,
                        separatorBuilder: (_, _) => const Gap(16),
                        itemBuilder: (context, index) {
                          final rec = scan.recommendations[index];
                          final difficulty =
                              rec['difficulty']?.toString() ?? 'sedang';
                          final productName =
                              rec['productName']?.toString() ?? 'tas_sachet';

                          final catalogProduct = CatalogService()
                              .getProductById(productName);

                          final String title = catalogProduct != null
                              ? catalogProduct['title']?.toString() ??
                                    productName
                              : productName
                                    .replaceAll('_', ' ')
                                    .split(' ')
                                    .map(
                                      (str) => str.isNotEmpty
                                          ? '${str[0].toUpperCase()}${str.substring(1)}'
                                          : '',
                                    )
                                    .join(' ');

                          final String imageUrl = catalogProduct != null
                              ? catalogProduct['imageUrl']?.toString() ?? ''
                              : 'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?auto=format&fit=crop&w=900&q=60';

                          final String duration = catalogProduct != null
                              ? catalogProduct['estimated_time']?.toString() ??
                                    '3-4 jam'
                              : (difficulty == 'mudah'
                                    ? '2-3 jam'
                                    : (difficulty == 'sedang'
                                          ? '3-4 jam'
                                          : '4-6 jam'));

                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF1D6940,
                                  ).withValues(alpha: 0.05),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                              border: Border.all(
                                color: const Color(0xFFEEEEE9),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 96,
                                  height: 96,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    color: const Color(0xFFF4F4EE),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: CachedNetworkImage(
                                    imageUrl: imageUrl,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => const Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        const Icon(
                                          Icons.image,
                                          color: Colors.grey,
                                        ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: SizedBox(
                                    height: 96,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              title,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF1A1C19),
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 2,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: const Color(
                                                      0xFFCCEA9D,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          99,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    difficulty.toUpperCase(),
                                                    style: const TextStyle(
                                                      fontSize: 8,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Color(0xFF364E12),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                const Icon(
                                                  Icons.schedule,
                                                  size: 14,
                                                  color: Color(0xFF1D6940),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  duration,
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: Color(0xFF1D6940),
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        GestureDetector(
                                          onTap: () =>
                                              _goToOverview(context, rec),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF1D6940),
                                              borderRadius:
                                                  BorderRadius.circular(99),
                                            ),
                                            child: const Text(
                                              'Mulai',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const Gap(24),

                      // Custom AI Recommendation Button
                      if (scanner.isLoadingAiRecommendations)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (!hasAiRecommendations)
                        Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          width: double.infinity,
                          height: 64,
                          child: ElevatedButton(
                            onPressed: () {
                              scanner.fetchAiRecommendations(scan.id);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1D6940),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFCCEA9D),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.auto_awesome,
                                        color: Color(0xFF1D6940),
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: const [
                                        Text(
                                          'Minta Rekomendasi AI',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                        Text(
                                          'Gunakan AI untuk ide proyek lainnya',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const Icon(Icons.bolt, color: Colors.white),
                              ],
                            ),
                          ),
                        ),
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
}
