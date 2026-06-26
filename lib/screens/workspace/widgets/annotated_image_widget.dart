import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../models/visual_annotation_model.dart';
import 'visual_feedback_painter.dart';

class AnnotatedImageWidget extends StatelessWidget {
  final String imageUrl;
  final List<VisualAnnotationModel> annotations;
  final double height;

  const AnnotatedImageWidget({
    super.key,
    required this.imageUrl,
    required this.annotations,
    this.height = 220,
  });

  @override
  Widget build(BuildContext context) {
    final isLocal = imageUrl.startsWith('/') || imageUrl.startsWith('file://');

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.black.withOpacity(0.04),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              fit: StackFit.expand,
              children: [
                // Background Image
                isLocal
                    ? Image.file(
                        File(imageUrl.replaceFirst('file://', '')),
                        fit: BoxFit.cover,
                      )
                    : CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(),
                        ),
                        errorWidget: (context, url, error) => const Center(
                          child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
                        ),
                      ),

                // Painting Layer (overlaid)
                Positioned.fill(
                  child: CustomPaint(
                    painter: VisualFeedbackPainter(annotations: annotations),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
