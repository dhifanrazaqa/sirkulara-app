import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../core/utils/impact_calculator.dart';
import '../models/waste_scan_model.dart';
import 'catalog_service.dart';
import 'storage_service.dart';

class ScannerService extends ChangeNotifier {
  final ImagePicker _picker = ImagePicker();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageService _storageService = StorageService();
  final Dio _dio = Dio();

  File? _selectedImage;
  bool _isScanning = false;
  bool _isLoading = false;
  bool _isLoadingAiRecommendations = false;
  WasteScanModel? _lastScanResult;
  List<WasteScanModel> _scanHistory = [];
  String? _errorMessage;

  File? get selectedImage => _selectedImage;
  bool get isScanning => _isScanning;
  bool get isLoading => _isLoading;
  bool get isLoadingAiRecommendations => _isLoadingAiRecommendations;
  WasteScanModel? get lastScanResult => _lastScanResult;
  List<WasteScanModel> get scanHistory => List.unmodifiable(_scanHistory);
  String? get errorMessage => _errorMessage;

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  Future<void> pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 90);
      if (picked == null) return;
      _selectedImage = File(picked.path);
      _setError(null);
      notifyListeners();
    } catch (_) {
      _setError('Tidak bisa mengambil gambar.');
    }
  }

  Future<void> analyzeScan(String userId) async {
    final image = _selectedImage;
    if (image == null) {
      _setError('Pilih gambar terlebih dahulu.');
      return;
    }
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _setError('Sesi login habis. Silakan masuk ulang sebelum scan.');
      return;
    }
    if (currentUser.uid != userId) {
      _setError('User aktif tidak cocok dengan sesi scan. Silakan login ulang.');
      return;
    }
    try {
      _isScanning = true;
      _setError(null);
      notifyListeners();

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final imageUrl = await _storageService.uploadImage(image, 'scans/$userId/$timestamp.jpg');
      final result = await _analyzeWithOpenAi(imageUrl);
      final materialType = result['materialType'] as String? ?? 'lainnya';
      final weightGrams = (result['estimatedWeightGrams'] as num?)?.toDouble() ?? 9.0;
      final condition = result['condition'] as String? ?? 'bersih_kering';
      
      // 1. Ambil rekomendasi produk utama dari Katalog saja
      final catalogProducts = CatalogService().getProductsByMaterial(materialType);
      final List<Map<String, dynamic>> recommendations = catalogProducts.map((p) => {
        'productName': p['id'],
        'difficulty': p['difficulty'],
        'estimatedValue': p['estimatedValue'] ?? ImpactCalculator.estimateProductValue(materialType, weightGrams),
      }).toList();

      final scanRef = _firestore.collection('scans').doc();
      final scanModel = WasteScanModel(
        id: scanRef.id,
        userId: userId,
        imageUrl: imageUrl,
        materialType: materialType,
        wasteCondition: condition,
        weightGrams: weightGrams,
        recommendations: recommendations,
        scannedAt: Timestamp.now(),
      );
      await scanRef.set(scanModel.toMap());
      _lastScanResult = scanModel;
      _scanHistory = [scanModel, ..._scanHistory].take(10).toList();
      notifyListeners();
    } on FirebaseException catch (error) {
      if (error.code == 'unauthenticated' || error.code == 'unauthorized' || error.code == 'permission-denied') {
        _setError('Upload diblokir oleh Firebase Storage. Pastikan Storage Rules sudah di-deploy dan user sudah login.');
      } else {
        _setError('Gagal menganalisis scan.');
      }
      if (kDebugMode) {
        debugPrint('Scanner Firebase error: ${error.code} ${error.message}');
      }
    } catch (error) {
      _setError('Gagal menganalisis scan.');
      if (kDebugMode) {
        debugPrint('Scanner error: $error');
      }
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> _analyzeWithOpenAi(String imageUrl) async {
    const apiKey = String.fromEnvironment('OPENAI_API_KEY');
    if (apiKey.isEmpty || apiKey == 'YOUR_OPENAI_API_KEY_HERE' || !apiKey.startsWith('sk-')) {
      return _fallbackAnalysis();
    }

    final response = await _dio.post(
      'https://api.openai.com/v1/chat/completions',
      options: Options(headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      }),
      data: {
        'model': 'gpt-4o-mini',
        'messages': [
          {
            'role': 'system',
            'content':
                'Kamu adalah sistem identifikasi limbah plastik untuk platform upcycling Sirkulara. Analisis gambar limbah yang diberikan dan kembalikan HANYA JSON dengan format: {"materialType": string, "confidence": number, "description": string, "estimatedWeightGrams": number, "condition": string} dengan materialType salah satu sachet_multilayer, botol_pet, kertas, kain, lainnya. Estimasi berat limbah dalam satuan gram ("estimatedWeightGrams") berdasarkan jumlah/volume bahan yang terbaca di gambar. Tentukan juga kondisinya ("condition") antara "bersih_kering" atau "kotor_basah".',
          },
          {
            'role': 'user',
            'content': [
              {'type': 'text', 'text': 'Analisis gambar limbah ini.'},
              {
                'type': 'image_url',
                'image_url': {'url': imageUrl},
              },
            ],
          },
        ],
        'temperature': 0.2,
        'response_format': {'type': 'json_object'},
      },
    );

    final content = response.data['choices'][0]['message']['content'] as String? ?? '{}';
    return _decodeAnalysis(content);
  }

  Map<String, dynamic> _decodeAnalysis(String content) {
    try {
      final sanitized = content.replaceAll(RegExp(r'```json|```'), '').trim();
      return Map<String, dynamic>.from(jsonDecode(sanitized) as Map);
    } catch (_) {
      return _fallbackAnalysis();
    }
  }

  Map<String, dynamic> _fallbackAnalysis() {
    return {
      'materialType': 'sachet_multilayer',
      'confidence': 0.7,
      'description': 'Deteksi fallback untuk limbah upcycling.',
      'estimatedWeightGrams': 9.0,
      'condition': 'bersih_kering',
    };
  }

  Future<void> fetchScanHistory(String userId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final query = await _firestore
          .collection('scans')
          .where('userId', isEqualTo: userId)
          .orderBy('scannedAt', descending: true)
          .limit(10)
          .get();
      _scanHistory = query.docs.map(WasteScanModel.fromFirestore).toList();
      if (_scanHistory.isNotEmpty && _lastScanResult == null) {
        _lastScanResult = _scanHistory.first;
      }
      notifyListeners();
    } catch (_) {
      _setError('Gagal memuat riwayat scan.');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectScanResult(WasteScanModel scan) {
    _lastScanResult = scan;
    notifyListeners();
  }

  void resetScan() {
    _selectedImage = null;
    _lastScanResult = null;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> fetchAiRecommendations(String scanId) async {
    final scan = _lastScanResult;
    if (scan == null || scan.id != scanId) return;

    try {
      _isLoadingAiRecommendations = true;
      _setError(null);
      notifyListeners();

      // Call OpenAI to get creative recommendations
      final aiRecommendations = await _getAiRecommendationsFromOpenAi(scan.materialType, scan.weightGrams, scan.imageUrl);

      // Append/Update the recommendations list
      final updatedRecommendations = List<Map<String, dynamic>>.from(scan.recommendations);
      
      // Add recommendations from AI (making sure not to duplicate)
      final existingNames = updatedRecommendations.map((r) => r['productName'] as String).toSet();
      for (var aiRec in aiRecommendations) {
        final name = aiRec['productName'] as String? ?? '';
        if (name.isNotEmpty && !existingNames.contains(name)) {
          updatedRecommendations.add(aiRec);
          existingNames.add(name);
        }
      }

      // Update in Firestore
      await _firestore.collection('scans').doc(scanId).update({
        'recommendations': updatedRecommendations,
      });

      // Update local scan model
      final updatedScan = scan.copyWith(recommendations: updatedRecommendations);
      _lastScanResult = updatedScan;

      // Also update in scan history list
      _scanHistory = _scanHistory.map((item) => item.id == scanId ? updatedScan : item).toList();

      notifyListeners();
    } catch (e) {
      _setError('Gagal memuat rekomendasi tambahan.');
    } finally {
      _isLoadingAiRecommendations = false;
      notifyListeners();
    }
  }

  Future<List<Map<String, dynamic>>> _getAiRecommendationsFromOpenAi(
    String materialType,
    double weightGrams,
    String imageUrl,
  ) async {
    const apiKey = String.fromEnvironment('OPENAI_API_KEY');
    if (apiKey.isEmpty || apiKey == 'YOUR_OPENAI_API_KEY_HERE' || !apiKey.startsWith('sk-')) {
      return _fallbackAiRecommendations(materialType, weightGrams);
    }

    final response = await _dio.post(
      'https://api.openai.com/v1/chat/completions',
      options: Options(headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      }),
      data: {
        'model': 'gpt-4o-mini',
        'messages': [
          {
            'role': 'system',
            'content':
                'Kamu adalah desainer produk upcycling kreatif untuk platform upcycling Sirkulara. Berikan 3 ide produk kreatif unik (DI LUAR katalog umum seperti tas_sachet, lampu_botol_pet) yang bisa dibuat dari bahan plastik tipe $materialType dengan berat $weightGrams gram. Kembalikan HANYA JSON dengan format: {"recommendations": [{"productName": string, "difficulty": string, "estimatedValue": number}]} dengan difficulty salah satu: mudah, sedang, sulit.',
          },
          {
            'role': 'user',
            'content': [
              {'type': 'text', 'text': 'Berikan rekomendasi produk kreatif untuk limbah ini.'},
              {
                'type': 'image_url',
                'image_url': {'url': imageUrl},
              },
            ],
          },
        ],
        'temperature': 0.7,
        'response_format': {'type': 'json_object'},
      },
    );

    final content = response.data['choices'][0]['message']['content'] as String? ?? '{}';
    try {
      final sanitized = content.replaceAll(RegExp(r'```json|```'), '').trim();
      final decoded = Map<String, dynamic>.from(jsonDecode(sanitized) as Map);
      final rawRecommendations = decoded['recommendations'] as List<dynamic>? ?? const [];
      return rawRecommendations
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } catch (_) {
      return _fallbackAiRecommendations(materialType, weightGrams);
    }
  }

  List<Map<String, dynamic>> _fallbackAiRecommendations(String materialType, double weightGrams) {
    return [
      {
        'productName': 'hiasan_dinding_kreatif',
        'difficulty': 'mudah',
        'estimatedValue': ImpactCalculator.estimateProductValue(materialType, weightGrams) * 1.2,
      },
      {
        'productName': 'wadah_serbaguna_anyam',
        'difficulty': 'sedang',
        'estimatedValue': ImpactCalculator.estimateProductValue(materialType, weightGrams) * 1.5,
      },
    ];
  }
}
