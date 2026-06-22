import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String id;
  final String buyerId;
  final String productId;
  final String productTitle;
  final String productImageUrl;
  final int price;
  final String status;
  final Timestamp createdAt;

  const OrderModel({
    required this.id,
    required this.buyerId,
    required this.productId,
    required this.productTitle,
    required this.productImageUrl,
    required this.price,
    required this.status,
    required this.createdAt,
  });

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? <String, dynamic>{};
    return OrderModel(
      id: doc.id,
      buyerId: data['buyerId'] as String? ?? '',
      productId: data['productId'] as String? ?? '',
      productTitle: data['productTitle'] as String? ?? '',
      productImageUrl: data['productImageUrl'] as String? ?? '',
      price: (data['price'] as num?)?.toInt() ?? 0,
      status: data['status'] as String? ?? 'pending',
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'buyerId': buyerId,
      'productId': productId,
      'productTitle': productTitle,
      'productImageUrl': productImageUrl,
      'price': price,
      'status': status,
      'createdAt': createdAt,
    };
  }
}
