import 'package:cloud_firestore/cloud_firestore.dart';
import 'visual_annotation_model.dart';

class VisualValidationModel {
  final bool isValid;
  final int score;
  final String status; // good, needs_improvement, failed, manual_override
  final List<String> feedback;
  final String validatedImageUrl;
  final Timestamp validatedAt;
  final List<VisualAnnotationModel> annotations;

  const VisualValidationModel({
    required this.isValid,
    required this.score,
    required this.status,
    required this.feedback,
    required this.validatedImageUrl,
    required this.validatedAt,
    this.annotations = const [],
  });

  factory VisualValidationModel.fromMap(Map<String, dynamic> map) {
    final rawAnnotations = map['annotations'] as List<dynamic>? ?? const [];
    final annotationsList = rawAnnotations
        .map((item) => VisualAnnotationModel.fromMap(Map<String, dynamic>.from(item as Map)))
        .toList();

    return VisualValidationModel(
      isValid: map['isValid'] as bool? ?? false,
      score: (map['score'] as num?)?.toInt() ?? 0,
      status: map['status'] as String? ?? 'failed',
      feedback: (map['feedback'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      validatedImageUrl: map['validatedImageUrl'] as String? ?? '',
      validatedAt: map['validatedAt'] != null
          ? map['validatedAt'] as Timestamp
          : Timestamp.now(),
      annotations: annotationsList,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isValid': isValid,
      'score': score,
      'status': status,
      'feedback': feedback,
      'validatedImageUrl': validatedImageUrl,
      'validatedAt': validatedAt,
      'annotations': annotations.map((a) => a.toMap()).toList(),
    };
  }
}
