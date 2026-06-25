import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/order_model.dart';
import '../models/product_model.dart';

class ProductService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<ProductModel> _products = [];
  List<ProductModel> _myProducts = [];
  ProductModel? _selectedProduct;
  bool _isLoading = false;
  String? _filterCategory;
  String? _filterMaterial;
  bool _filterVerifiedOnly = false;
  String? _errorMessage;

  List<ProductModel> get products => List.unmodifiable(_products);
  List<ProductModel> get myProducts => List.unmodifiable(_myProducts);
  ProductModel? get selectedProduct => _selectedProduct;
  bool get isLoading => _isLoading;
  String? get filterCategory => _filterCategory;
  String? get filterMaterial => _filterMaterial;
  bool get filterVerifiedOnly => _filterVerifiedOnly;
  String? get errorMessage => _errorMessage;

  Future<void> fetchProducts() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final query = await _firestore
          .collection('products')
          .where('status', isEqualTo: 'active')
          .orderBy('createdAt', descending: true)
          .get();

      final allProducts = query.docs.map(ProductModel.fromFirestore).toList();
      _products = allProducts.where((product) {
        final categoryMatch = _filterCategory == null || product.category == _filterCategory;
        final materialMatch = _filterMaterial == null || product.materialType == _filterMaterial;
        final verifiedMatch = !_filterVerifiedOnly || product.isVerified;
        return categoryMatch && materialMatch && verifiedMatch;
      }).toList();
      notifyListeners();
    } catch (_) {
      _errorMessage = 'Gagal memuat produk.';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMyProducts(String userId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final query = await _firestore
          .collection('products')
          .where('creatorId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      _myProducts = query.docs.map(ProductModel.fromFirestore).toList();
      notifyListeners();
    } catch (_) {
      _errorMessage = 'Gagal memuat produk saya.';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> publishProduct(String productId, int price) async {
    try {
      await _firestore.collection('products').doc(productId).update({
        'status': 'active',
        'price': price,
      });
      _myProducts = _myProducts
          .map((product) => product.id == productId ? product.copyWith(price: price, status: 'active') : product)
          .toList();
      _products = _products
          .map((product) => product.id == productId ? product.copyWith(price: price, status: 'active') : product)
          .toList();
      notifyListeners();
    } catch (_) {
      _errorMessage = 'Gagal mempublikasikan produk.';
      notifyListeners();
    }
  }

  Future<void> publishProductDetailed({
    required String productId,
    required String title,
    required String description,
    required int price,
    required String category,
    required List<String> imageUrls,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _firestore.collection('products').doc(productId).update({
        'status': 'active',
        'title': title,
        'description': description,
        'price': price,
        'category': category.toLowerCase(),
        'imageUrls': imageUrls,
      });

      _myProducts = _myProducts.map((p) {
        if (p.id == productId) {
          return p.copyWith(
            title: title,
            description: description,
            price: price,
            category: category.toLowerCase(),
            imageUrls: imageUrls,
            status: 'active',
          );
        }
        return p;
      }).toList();

      _products = _products.map((p) {
        if (p.id == productId) {
          return p.copyWith(
            title: title,
            description: description,
            price: price,
            category: category.toLowerCase(),
            imageUrls: imageUrls,
            status: 'active',
          );
        }
        return p;
      }).toList();

      notifyListeners();
    } catch (e) {
      _errorMessage = 'Gagal mempublikasikan produk: $e';
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> applyFilter({String? category, String? material, bool verifiedOnly = false}) async {
    _filterCategory = category;
    _filterMaterial = material;
    _filterVerifiedOnly = verifiedOnly;
    await fetchProducts();
  }

  Future<void> clearFilters() async {
    _filterCategory = null;
    _filterMaterial = null;
    _filterVerifiedOnly = false;
    await fetchProducts();
  }

  void selectProduct(ProductModel product) {
    _selectedProduct = product;
    notifyListeners();
  }

  Future<void> buyProduct(ProductModel product) async {
    final buyer = FirebaseAuth.instance.currentUser;
    if (buyer == null) {
      _errorMessage = 'Silakan masuk terlebih dahulu.';
      notifyListeners();
      return;
    }

    try {
      final orderRef = _firestore.collection('orders').doc();
      final order = OrderModel(
        id: orderRef.id,
        buyerId: buyer.uid,
        productId: product.id,
        productTitle: product.title,
        productImageUrl: product.imageUrls.isNotEmpty ? product.imageUrls.first : '',
        price: product.price,
        status: 'pending',
        createdAt: Timestamp.now(),
      );
      await orderRef.set(order.toMap());
      await _firestore.collection('products').doc(product.id).update({'status': 'sold'});
      _products = _products.map((item) => item.id == product.id ? item.copyWith(status: 'sold') : item).toList();
      _myProducts = _myProducts.map((item) => item.id == product.id ? item.copyWith(status: 'sold') : item).toList();
      notifyListeners();
    } catch (_) {
      _errorMessage = 'Gagal membeli produk.';
      notifyListeners();
    }
  }
}
