import 'package:cloud_firestore/cloud_firestore.dart';
import 'visual_validation_model.dart';

class WorkspaceStepModel {
  final int stepNumber;
  final String title;
  final String instruction;
  final List<String> technicalCriteria;
  final String? evidenceImageUrl;
  final bool isCompleted;
  final Timestamp? completedAt;
  final String? referenceImageUrl;
  final String? badExampleUrl;
  final String? videoUrl;
  final String? annotatedImageUrl;
  final int qualityScore;
  final VisualValidationModel? validationResult;
  final int milestoneIndex;
  final bool requiresValidation;
  final String validationType;
  final int retryCount;

  const WorkspaceStepModel({
    required this.stepNumber,
    required this.title,
    required this.instruction,
    required this.technicalCriteria,
    required this.evidenceImageUrl,
    required this.isCompleted,
    required this.completedAt,
    this.referenceImageUrl,
    this.badExampleUrl,
    this.videoUrl,
    this.annotatedImageUrl,
    this.qualityScore = 0,
    this.validationResult,
    this.milestoneIndex = 0,
    this.requiresValidation = false,
    this.validationType = 'none',
    this.retryCount = 0,
  });

  factory WorkspaceStepModel.fromMap(Map<String, dynamic> map) {
    return WorkspaceStepModel(
      stepNumber: (map['stepNumber'] as num?)?.toInt() ?? 0,
      title: map['title'] as String? ?? '',
      instruction: map['instruction'] as String? ?? '',
      technicalCriteria: (map['technicalCriteria'] as List<dynamic>? ?? const []).whereType<String>().toList(),
      evidenceImageUrl: map['evidenceImageUrl'] as String?,
      isCompleted: map['isCompleted'] as bool? ?? false,
      completedAt: map['completedAt'] as Timestamp?,
      referenceImageUrl: map['referenceImageUrl'] as String?,
      badExampleUrl: map['badExampleUrl'] as String?,
      videoUrl: map['videoUrl'] as String?,
      annotatedImageUrl: map['annotatedImageUrl'] as String?,
      qualityScore: (map['qualityScore'] as num?)?.toInt() ?? 0,
      validationResult: map['validationResult'] != null
          ? VisualValidationModel.fromMap(Map<String, dynamic>.from(map['validationResult'] as Map))
          : null,
      milestoneIndex: (map['milestoneIndex'] as num?)?.toInt() ?? 0,
      requiresValidation: map['requiresValidation'] as bool? ?? false,
      validationType: map['validationType'] as String? ?? 'none',
      retryCount: (map['retryCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'stepNumber': stepNumber,
      'title': title,
      'instruction': instruction,
      'technicalCriteria': technicalCriteria,
      'evidenceImageUrl': evidenceImageUrl,
      'isCompleted': isCompleted,
      'completedAt': completedAt,
      'referenceImageUrl': referenceImageUrl,
      'badExampleUrl': badExampleUrl,
      'videoUrl': videoUrl,
      'annotatedImageUrl': annotatedImageUrl,
      'qualityScore': qualityScore,
      'validationResult': validationResult?.toMap(),
      'milestoneIndex': milestoneIndex,
      'requiresValidation': requiresValidation,
      'validationType': validationType,
      'retryCount': retryCount,
    };
  }

  WorkspaceStepModel copyWith({
    String? evidenceImageUrl,
    bool? isCompleted,
    Timestamp? completedAt,
    String? referenceImageUrl,
    String? badExampleUrl,
    String? videoUrl,
    String? annotatedImageUrl,
    int? qualityScore,
    VisualValidationModel? validationResult,
    int? milestoneIndex,
    bool? requiresValidation,
    String? validationType,
    int? retryCount,
  }) {
    return WorkspaceStepModel(
      stepNumber: stepNumber,
      title: title,
      instruction: instruction,
      technicalCriteria: technicalCriteria,
      evidenceImageUrl: evidenceImageUrl ?? this.evidenceImageUrl,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      referenceImageUrl: referenceImageUrl ?? this.referenceImageUrl,
      badExampleUrl: badExampleUrl ?? this.badExampleUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      annotatedImageUrl: annotatedImageUrl ?? this.annotatedImageUrl,
      qualityScore: qualityScore ?? this.qualityScore,
      validationResult: validationResult ?? this.validationResult,
      milestoneIndex: milestoneIndex ?? this.milestoneIndex,
      requiresValidation: requiresValidation ?? this.requiresValidation,
      validationType: validationType ?? this.validationType,
      retryCount: retryCount ?? this.retryCount,
    );
  }
}
