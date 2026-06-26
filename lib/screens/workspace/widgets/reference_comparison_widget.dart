import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/visual_annotation_model.dart';
import 'annotated_image_widget.dart';

class ReferenceComparisonWidget extends StatelessWidget {
  final String referenceImageUrl;
  final String userImageUrl;
  final List<VisualAnnotationModel> annotations;

  const ReferenceComparisonWidget({
    super.key,
    required this.referenceImageUrl,
    required this.userImageUrl,
    required this.annotations,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.compare, color: AppColors.primaryDark),
            Gap(8),
            Text(
              'Perbandingan Hasil & Referensi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
          ],
        ),
        const Gap(12),
        Row(
          children: [
            // Left: Ideal Reference Image
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 6),
                    child: Text(
                      'Referensi (Ideal)',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                    ),
                  ),
                  Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: referenceImageUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: referenceImageUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                              errorWidget: (context, url, error) => const Center(
                                child: Icon(Icons.broken_image, size: 36, color: Colors.grey),
                              ),
                            )
                          : const Center(
                              child: Icon(Icons.image, size: 36, color: Colors.grey),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const Gap(12),
            // Right: User's image with overlays
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 6),
                    child: Text(
                      'Hasil Anda (AI)',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                    ),
                  ),
                  AnnotatedImageWidget(
                    imageUrl: userImageUrl,
                    annotations: annotations,
                    height: 180,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
