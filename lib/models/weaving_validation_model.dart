import 'visual_annotation_model.dart';

class WeavingValidationModel {
  final int score;
  final String status; // excellent, good, needs_improvement, retry
  final String feedback;
  final List<VisualAnnotationModel> annotations;
  final Map<String, int>? breakdown;

  const WeavingValidationModel({
    required this.score,
    required this.status,
    required this.feedback,
    required this.annotations,
    this.breakdown,
  });

  factory WeavingValidationModel.fromMap(Map<String, dynamic> map) {
    final rawAnnotations = map['annotations'] as List<dynamic>? ?? const [];
    final annotationsList = rawAnnotations
        .map((item) => VisualAnnotationModel.fromMap(Map<String, dynamic>.from(item as Map)))
        .toList();

    Map<String, int>? breakdownMap;
    if (map['breakdown'] != null) {
      try {
        final rawBreakdown = Map<String, dynamic>.from(map['breakdown'] as Map);
        breakdownMap = rawBreakdown.map((key, val) => MapEntry(key, (val as num).toInt()));
      } catch (_) {
        // Fallback if formatting is irregular
      }
    }

    return WeavingValidationModel(
      score: (map['score'] as num?)?.toInt() ?? 0,
      status: map['status'] as String? ?? 'retry',
      feedback: map['feedback'] as String? ?? '',
      annotations: annotationsList,
      breakdown: breakdownMap,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'score': score,
      'status': status,
      'feedback': feedback,
      'annotations': annotations.map((a) => a.toMap()).toList(),
      'breakdown': breakdown,
    };
  }
}
