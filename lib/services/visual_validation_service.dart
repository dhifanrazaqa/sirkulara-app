import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/visual_annotation_model.dart';
import '../models/visual_validation_model.dart';
import 'storage_service.dart';

class VisualValidationService extends ChangeNotifier {
  final StorageService _storageService = StorageService();
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  bool _isValidating = false;
  VisualValidationModel? _lastValidationResult;
  String? _errorMessage;

  bool get isValidating => _isValidating;
  VisualValidationModel? get lastValidationResult => _lastValidationResult;
  String? get errorMessage => _errorMessage;

  void resetValidation() {
    _isValidating = false;
    _lastValidationResult = null;
    _errorMessage = null;
    notifyListeners();
  }

  Future<VisualValidationModel> validateStep({
    required File imageFile,
    required String workspaceId,
    required int stepNumber,
    required String validationType,
    Map<String, dynamic>? baselineData,
  }) async {
    _isValidating = true;
    _errorMessage = null;
    notifyListeners();

    String? validatedImageUrl;
    try {
      // 1. Upload to Firebase Storage
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = 'workspaces/$workspaceId/validation/step_${stepNumber}_$timestamp.jpg';
      validatedImageUrl = await _storageService.uploadImage(imageFile, path);
    } catch (e) {
      _isValidating = false;
      _errorMessage = 'Gagal mengunggah foto bukti ke Storage: $e';
      notifyListeners();
      rethrow;
    }

    // 2. Fetch Base URL from Env
    const String baseUrl = String.fromEnvironment(
      'VALIDATION_API_BASE_URL',
      defaultValue: 'http://localhost:8000',
    );

    if (baseUrl.trim().isEmpty) {
      _isValidating = false;
      _errorMessage = 'VALIDATION_API_BASE_URL tidak terkonfigurasi.';
      notifyListeners();
      throw Exception('VALIDATION_API_BASE_URL is not set.');
    }

    final endpoint = _buildEndpointPath(validationType);
    final url = '$baseUrl$endpoint';

    // 3. Prepare payload arguments dynamically
    final Map<String, dynamic> data = {
      'imageUrl': validatedImageUrl,
    };

    if (validationType == 'fold_alignment') {
      data['mode'] = (stepNumber == 1) ? 'strip_width' : 'fold_angle';
      if (baselineData != null && baselineData.containsKey('measuredWidthMm')) {
        data['baselineWidth'] = baselineData['measuredWidthMm'];
      }
    } else if (validationType == 'fold_module') {
      data['shapeTarget'] = (stepNumber == 6) ? 'v_module' : 'box_module';
    } else if (validationType == 'weave_wall') {
      data['side'] = (baselineData != null && baselineData.containsKey('side'))
          ? baselineData['side']
          : 'front';
    } else if (validationType == 'handle') {
      data['stage'] = (stepNumber == 11) ? 'construction' : 'attachment';
    }

    try {
      final response = await _dio.post(url, data: data);
      final responseData = Map<String, dynamic>.from(response.data as Map);

      final rawAnnotations = responseData['annotations'] as List<dynamic>? ?? const [];
      final annotationsList = rawAnnotations
          .map((item) => VisualAnnotationModel.fromMap(Map<String, dynamic>.from(item as Map)))
          .toList();

      // Parse payload
      final result = VisualValidationModel(
        isValid: responseData['isValid'] as bool? ?? false,
        score: (responseData['score'] as num?)?.toInt() ?? 0,
        status: responseData['status'] as String? ?? 'failed',
        feedback: (responseData['feedback'] as List<dynamic>? ?? const [])
            .map((item) => item.toString())
            .toList(),
        validatedImageUrl: validatedImageUrl,
        validatedAt: Timestamp.now(),
        annotations: annotationsList,
      );

      _lastValidationResult = result;
      _isValidating = false;
      notifyListeners();
      return result;
    } catch (e) {
      String details = e.toString();
      if (e is DioException && e.response != null) {
        details = 'HTTP ${e.response!.statusCode}: ${e.response!.data}';
      }
      debugPrint('FastAPI connection failed ($details)');
      _errorMessage = 'Koneksi ke server validasi gagal: $details';
      _lastValidationResult = null;
      _isValidating = false;
      notifyListeners();
      rethrow;
    }
  }

  String _buildEndpointPath(String validationType) {
    switch (validationType) {
      case 'fold_alignment':
        return '/validate/fold-alignment';
      case 'fold_module':
        return '/validate/fold-module';
      case 'weave_base':
        return '/validate/weave-base';
      case 'weave_wall':
        return '/validate/weave-wall';
      case 'finishing':
        return '/validate/finishing';
      case 'handle':
        return '/validate/handle';
      default:
        return '/validate/fold-alignment';
    }
  }
}
