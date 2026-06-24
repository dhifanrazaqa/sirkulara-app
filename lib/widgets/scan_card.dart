import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ScanCard extends StatelessWidget {
  final String imageUrl;
  final String materialType;
  final DateTime scannedAt;
  final VoidCallback onTap;

  const ScanCard({
    super.key,
    required this.imageUrl,
    required this.materialType,
    required this.scannedAt,
    required this.onTap,
  });

  String _formatMaterial(String material) {
    switch (material) {
      case 'sachet_multilayer':
        return 'Sachet Multilayer';
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1D6940).withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: Colors.white.withOpacity(0.5),
            width: 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: const Color(0xFFF4F4EE),
                        child: const Icon(Icons.image, color: Colors.grey),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(2),
                      child: const Icon(
                        Icons.check_circle,
                        color: Color(0xFF1D6940),
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatMaterial(materialType),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1C19),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(scannedAt),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF707A71),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}