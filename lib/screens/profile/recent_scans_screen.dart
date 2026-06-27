import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../services/auth_service.dart';
import '../../services/scanner_service.dart';

class RecentScansScreen extends StatefulWidget {
  const RecentScansScreen({super.key});

  @override
  State<RecentScansScreen> createState() => _RecentScansScreenState();
}

class _RecentScansScreenState extends State<RecentScansScreen> {
  String _selectedFilter = 'Semua';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthService>().currentUser;
      if (user != null) {
        context.read<ScannerService>().fetchScanHistory(user.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.2,
            colors: [
              Color(0xFFCFEDA0),
              Color(0xFFFAFAF4),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Custom Header App Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Sirkulara',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF404941),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Riwayat Scan',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1C19),
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => Navigator.maybePop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.8),
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.close, color: Color(0xFF1A1C19), size: 20),
                      ),
                    ),
                  ],
                ),
              ),

              // Filter Chips
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildFilterChip('Semua'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Plastik'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Logam'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Kertas'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Scan List
              Expanded(
                child: Consumer<ScannerService>(
                  builder: (context, scannerService, _) {
                    if (scannerService.isLoading) {
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1D6940)),
                        ),
                      );
                    }

                    final allScans = scannerService.scanHistory;
                    
                    // Apply filtering
                    final filteredScans = allScans.where((scan) {
                      if (_selectedFilter == 'Semua') return true;
                      return scan.materialType.toLowerCase() == _selectedFilter.toLowerCase();
                    }).toList();

                    if (filteredScans.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              'Tidak ada riwayat scan ${_selectedFilter != 'Semua' ? _selectedFilter.toLowerCase() : ''}',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                            ),
                          ],
                        ),
                      );
                    }

                    // Group scans by Month/Year for section headers (optional but matches HTML style "September 2023")
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      itemCount: filteredScans.length,
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, index) {
                        final scan = filteredScans[index];
                        final dateStr = DateFormat('dd MMM').format(scan.scannedAt.toDate());
                        
                        // Render scan card
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
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
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(24),
                              onTap: () {
                                // Navigate to scan result with this scan details if needed
                                Navigator.pushNamed(context, '/scan-result', arguments: scan);
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    // Left Image
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF4F4EE),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: CachedNetworkImage(
                                        imageUrl: scan.imageUrl,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                        errorWidget: (context, url, error) => const Icon(Icons.image, color: Colors.grey),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    // Middle Info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  _capitalize(scan.materialType) == 'Plastik' 
                                                      ? 'Botol Air PET' 
                                                      : _capitalize(scan.materialType) == 'Kertas' 
                                                          ? 'Kardus Box' 
                                                          : 'Sampah Terdeteksi',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF1A1C19),
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              Text(
                                                dateStr,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0xFF707A71),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${_capitalize(scan.materialType)} (${scan.weightGrams.toInt()}g)',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF404941),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: const [
                                              Icon(Icons.verified, color: Color(0xFF1D6940), size: 16),
                                              SizedBox(width: 4),
                                              Text(
                                                'TERVERIFIKASI',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF1D6940),
                                                  letterSpacing: 1,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.chevron_right, color: Color(0xFF707A71)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1D6940) : Colors.white,
          borderRadius: BorderRadius.circular(99),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  )
                ]
              : const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  )
                ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF404941),
          ),
        ),
      ),
    );
  }

  String _capitalize(String text) {
    if (text.isEmpty) return '';
    return '${text[0].toUpperCase()}${text.substring(1)}';
  }
}

extension MarginBottomExtension on Widget {
  Widget marginWith(double bottom) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: this,
    );
  }
}
