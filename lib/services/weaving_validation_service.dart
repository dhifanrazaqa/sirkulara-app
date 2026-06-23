import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/visual_annotation_model.dart';
import '../models/weaving_validation_model.dart';
import 'storage_service.dart';

class WeavingValidationService extends ChangeNotifier {
  final StorageService _storageService = StorageService();
  final Dio _dio = Dio();

  bool _isAnalyzing = false;
  WeavingValidationModel? _lastValidation;
  String? _errorMessage;

  bool get isAnalyzing => _isAnalyzing;
  WeavingValidationModel? get lastValidation => _lastValidation;
  String? get errorMessage => _errorMessage;

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  Future<WeavingValidationModel> validateFold(File image, String referenceImageUrl) async {
    return _validate(
      image: image,
      referenceImageUrl: referenceImageUrl,
      focusDescription: 'kualitas lipatan, konsistensi lebar, kerapatan lipatan, kerapian ujung lipatan',
      validationType: 'fold',
    );
  }

  Future<WeavingValidationModel> validateWeaving(File image, String referenceImageUrl) async {
    return _validate(
      image: image,
      referenceImageUrl: referenceImageUrl,
      focusDescription: 'kerapatan anyaman, pola over-under, konsistensi baris, kerapian tepi anyaman',
      validationType: 'weaving',
    );
  }

  Future<List<VisualAnnotationModel>> generateAnnotations(Map<String, dynamic> json) async {
    final rawAnnotations = json['annotations'] as List<dynamic>? ?? const [];
    return rawAnnotations
        .map((item) => VisualAnnotationModel.fromMap(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<WeavingValidationModel> _validate({
    required File image,
    required String referenceImageUrl,
    required String focusDescription,
    required String validationType,
  }) async {
    try {
      _isAnalyzing = true;
      _errorMessage = null;
      _lastValidation = null;
      notifyListeners();

      const apiKey = String.fromEnvironment('OPENAI_API_KEY');
      if (apiKey.isEmpty) {
        // Fallback for offline mode or empty api keys
        await Future.delayed(const Duration(seconds: 2));
        final fallback = _generateFallback(validationType);
        _lastValidation = fallback;
        return fallback;
      }

      // Upload local image to Firebase Storage first to get a URL
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final userImageUrl = await _storageService.uploadImage(
        image,
        'workspaces/validations/$userId/$timestamp.jpg',
      );

      final response = await _dio.post(
        'https://api.openai.com/v1/chat/completions',
        options: Options(headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        }),
        data: {
          'model': 'gpt-4o',
          'messages': [
            {
              'role': 'system',
              'content': '''Kamu adalah evaluator kerajinan anyaman terverifikasi.
Fokus analisis: $focusDescription.

Tugas Anda adalah mengevaluasi "Foto Hasil Kerja User" dengan membandingkannya ke "Foto Referensi (Ideal)" yang diberikan.
Lakukan analisis menyeluruh dan objektif.

Kembalikan respon HANYA dalam format JSON sebagai berikut:
{
  "score": <skor_kualitas_integer_0_100>,
  "status": "<excellent_jika_score>=90|good_jika_75-89|needs_improvement_jika_60-74|retry_jika_<60>",
  "feedback": "<masukan_konstruktif_singkat_maksimal_2_kalimat_dalam_bahasa_indonesia>",
  "breakdown": {
    "foldQuality": <nilai_0_100_lipatan>,
    "densityQuality": <nilai_0_100_kerapatan>,
    "edgeQuality": <nilai_0_100_kerapian_tepi>,
    "symmetry": <nilai_0_100_simetri>
  },
  "annotations": [
    {
      "type": "<circle|arrow|warning|highlight>",
      "x": <koordinat_x_relatif_pada_foto_user_0.0_sampai_1.0>,
      "y": <koordinat_y_relatif_pada_foto_user_0.0_sampai_1.0>,
      "label": "<deskripsi_singkat_kesalahan_di_area_tersebut>"
    }
  ]
}''',
            },
            {
              'role': 'user',
              'content': [
                {
                  'type': 'text',
                  'text': 'Bandingkan Gambar 1 (Foto Referensi / Ideal) dan Gambar 2 (Foto Hasil Kerja User). Tentukan apakah Gambar 2 memenuhi kriteria.',
                },
                {
                  'type': 'image_url',
                  'image_url': {'url': referenceImageUrl},
                },
                {
                  'type': 'image_url',
                  'image_url': {'url': userImageUrl},
                },
              ],
            },
          ],
          'temperature': 0.3,
          'response_format': {'type': 'json_object'},
        },
      );

      final content = response.data['choices'][0]['message']['content'] as String? ?? '{}';
      final cleaned = content.replaceAll(RegExp(r'```json|```'), '').trim();
      final decoded = Map<String, dynamic>.from(jsonDecode(cleaned) as Map);

      final model = WeavingValidationModel.fromMap(decoded);
      _lastValidation = model;
      return model;
    } catch (e) {
      _setError('Gagal memvalidasi gambar: $e');
      rethrow;
    } finally {
      _isAnalyzing = false;
      notifyListeners();
    }
  }

  WeavingValidationModel _generateFallback(String type) {
    if (type == 'fold') {
      return const WeavingValidationModel(
        score: 82,
        status: 'needs_improvement',
        feedback: 'Beberapa lipatan di sisi kanan atas masih kurang presisi dan kurang sejajar dengan referensi.',
        breakdown: {
          'foldQuality': 78,
          'densityQuality': 85,
          'edgeQuality': 80,
          'symmetry': 85,
        },
        annotations: [
          VisualAnnotationModel(
            type: 'circle',
            x: 0.65,
            y: 0.28,
            label: 'Lipatan kurang sejajar di area ini',
          ),
          VisualAnnotationModel(
            type: 'warning',
            x: 0.68,
            y: 0.30,
            label: 'Sejajarkan garis lipat dengan referensi',
          ),
        ],
      );
    } else {
      return const WeavingValidationModel(
        score: 84,
        status: 'needs_improvement',
        feedback: 'Kerapatan anyaman pada area kanan atas masih longgar. Pola over-under sudah konsisten.',
        breakdown: {
          'foldQuality': 90,
          'densityQuality': 72,
          'edgeQuality': 88,
          'symmetry': 85,
        },
        annotations: [
          VisualAnnotationModel(
            type: 'circle',
            x: 0.73,
            y: 0.18,
            label: 'Rapatkan area anyaman ini',
          ),
        ],
      );
    }
  }

  void reset() {
    _lastValidation = null;
    _errorMessage = null;
    _isAnalyzing = false;
    notifyListeners();
  }
}
