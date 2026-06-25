import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String id;
  final String creatorId;
  final String creatorName;
  final String title;
  final String description;
  final String category;
  final int price;
  final List<String> imageUrls;
  final String materialType;
  final double weightGrams;
  final double co2OffsetGrams;
  final bool isVerified;
  final String? workspaceId;
  final List<String> transparencySteps;
  final String status;
  final Timestamp createdAt;

  const ProductModel({
    required this.id,
    required this.creatorId,
    required this.creatorName,
    required this.title,
    required this.description,
    required this.category,
    required this.price,
    required this.imageUrls,
    required this.materialType,
    required this.weightGrams,
    required this.co2OffsetGrams,
    required this.isVerified,
    required this.workspaceId,
    required this.transparencySteps,
    required this.status,
    required this.createdAt,
  });

  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? <String, dynamic>{};
    return ProductModel(
      id: doc.id,
      creatorId: data['creatorId'] as String? ?? '',
      creatorName: data['creatorName'] as String? ?? '',
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      category: data['category'] as String? ?? 'lainnya',
      price: (data['price'] as num?)?.toInt() ?? 0,
      imageUrls: (data['imageUrls'] as List<dynamic>? ?? const []).whereType<String>().toList(),
      materialType: data['materialType'] as String? ?? 'lainnya',
      weightGrams: (data['weightGrams'] as num?)?.toDouble() ?? 0,
      co2OffsetGrams: (data['co2OffsetGrams'] as num?)?.toDouble() ?? 0,
      isVerified: data['isVerified'] as bool? ?? false,
      workspaceId: data['workspaceId'] as String?,
      transparencySteps: (data['transparencySteps'] as List<dynamic>? ?? const []).whereType<String>().toList(),
      status: data['status'] as String? ?? 'draft',
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'creatorId': creatorId,
      'creatorName': creatorName,
      'title': title,
      'description': description,
      'category': category,
      'price': price,
      'imageUrls': imageUrls,
      'materialType': materialType,
      'weightGrams': weightGrams,
      'co2OffsetGrams': co2OffsetGrams,
      'isVerified': isVerified,
      'workspaceId': workspaceId,
      'transparencySteps': transparencySteps,
      'status': status,
      'createdAt': createdAt,
    };
  }

  ProductModel copyWith({
    String? title,
    String? description,
    String? category,
    int? price,
    List<String>? imageUrls,
    String? status,
    bool? isVerified,
  }) {
    return ProductModel(
      id: id,
      creatorId: creatorId,
      creatorName: creatorName,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      price: price ?? this.price,
      imageUrls: imageUrls ?? this.imageUrls,
      materialType: materialType,
      weightGrams: weightGrams,
      co2OffsetGrams: co2OffsetGrams,
      isVerified: isVerified ?? this.isVerified,
      workspaceId: workspaceId,
      transparencySteps: transparencySteps,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }
}
