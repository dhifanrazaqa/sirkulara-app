import 'package:cloud_firestore/cloud_firestore.dart';

class WasteScanModel {
  final String id;
  final String userId;
  final String imageUrl;
  final String materialType;
  final String wasteCondition;
  final double weightGrams;
  final List<Map<String, dynamic>> recommendations;
  final Timestamp scannedAt;

  const WasteScanModel({
    required this.id,
    required this.userId,
    required this.imageUrl,
    required this.materialType,
    required this.wasteCondition,
    required this.weightGrams,
    required this.recommendations,
    required this.scannedAt,
  });

  WasteScanModel copyWith({
    String? id,
    String? userId,
    String? imageUrl,
    String? materialType,
    String? wasteCondition,
    double? weightGrams,
    List<Map<String, dynamic>>? recommendations,
    Timestamp? scannedAt,
  }) {
    return WasteScanModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      imageUrl: imageUrl ?? this.imageUrl,
      materialType: materialType ?? this.materialType,
      wasteCondition: wasteCondition ?? this.wasteCondition,
      weightGrams: weightGrams ?? this.weightGrams,
      recommendations: recommendations ?? this.recommendations,
      scannedAt: scannedAt ?? this.scannedAt,
    );
  }

  factory WasteScanModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? <String, dynamic>{};
    final rawRecommendations = data['recommendations'] as List<dynamic>? ?? const [];
    return WasteScanModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      materialType: data['materialType'] as String? ?? 'lainnya',
      wasteCondition: data['wasteCondition'] as String? ?? 'bersih_kering',
      weightGrams: (data['weightGrams'] as num?)?.toDouble() ?? 0,
      recommendations: rawRecommendations
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(),
      scannedAt: data['scannedAt'] as Timestamp? ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'imageUrl': imageUrl,
      'materialType': materialType,
      'wasteCondition': wasteCondition,
      'weightGrams': weightGrams,
      'recommendations': recommendations,
      'scannedAt': scannedAt,
    };
  }
}
