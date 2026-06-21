import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String role;
  final double totalPlasticDiverted;
  final double totalCo2Offset;
  final Timestamp createdAt;

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    required this.totalPlasticDiverted,
    required this.totalCo2Offset,
    required this.createdAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? <String, dynamic>{};
    return UserModel(
      uid: doc.id,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String? ?? 'User',
      role: data['role'] as String? ?? 'kreator',
      totalPlasticDiverted: (data['totalPlasticDiverted'] as num?)?.toDouble() ?? 0,
      totalCo2Offset: (data['totalCo2Offset'] as num?)?.toDouble() ?? 0,
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'role': role,
      'totalPlasticDiverted': totalPlasticDiverted,
      'totalCo2Offset': totalCo2Offset,
      'createdAt': createdAt,
    };
  }

  UserModel copyWith({
    String? email,
    String? displayName,
    String? role,
    double? totalPlasticDiverted,
    double? totalCo2Offset,
    Timestamp? createdAt,
  }) {
    return UserModel(
      uid: uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      totalPlasticDiverted: totalPlasticDiverted ?? this.totalPlasticDiverted,
      totalCo2Offset: totalCo2Offset ?? this.totalCo2Offset,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
