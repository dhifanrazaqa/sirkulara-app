import 'dart:convert';
import 'package:flutter/services.dart';

class CatalogService {
  static final CatalogService _instance = CatalogService._internal();
  factory CatalogService() => _instance;
  CatalogService._internal();

  List<Map<String, dynamic>> _catalog = [];
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;

  Future<void> loadCatalog() async {
    if (_isLoaded) return;
    try {
      final jsonString = await rootBundle.loadString('assets/catalog.json');
      final List<dynamic> decoded = jsonDecode(jsonString) as List<dynamic>;
      _catalog = decoded.map((item) => Map<String, dynamic>.from(item as Map)).toList();
      _isLoaded = true;
    } catch (e) {
      // Fallback fallback catalog if loading fails
      _catalog = [];
    }
  }

  List<Map<String, dynamic>> getProductsByMaterial(String materialType) {
    return _catalog
        .where((product) => product['materialType'] == materialType)
        .toList();
  }

  List<Map<String, dynamic>> getSteps(String productId) {
    final product = _catalog.firstWhere(
      (p) => p['id'] == productId,
      orElse: () => <String, dynamic>{},
    );
    final rawSteps = product['steps'] as List<dynamic>? ?? const [];
    return rawSteps.map((s) => Map<String, dynamic>.from(s as Map)).toList();
  }

  Map<String, dynamic>? getProductById(String productId) {
    final index = _catalog.indexWhere((p) => p['id'] == productId);
    if (index != -1) {
      return _catalog[index];
    }
    return null;
  }
}
