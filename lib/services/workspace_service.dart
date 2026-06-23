import 'dart:io';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

import '../core/utils/impact_calculator.dart';
import '../models/product_model.dart';
import '../models/workspace_step_model.dart';
import '../models/visual_validation_model.dart';
import '../core/constants/workspace_reference_data.dart';
import 'catalog_service.dart';
import 'storage_service.dart';
import 'visual_validation_service.dart';

class WorkspaceService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageService _storageService = StorageService();

  String? _activeWorkspaceId;
  String? _activeProductName;
  String? _activeMaterialType;
  double? _activeWeightGrams;
  List<WorkspaceStepModel> _steps = [];
  int _currentStepIndex = 0;
  bool _isLoading = false;
  bool _isWorkspaceComplete = false;
  String? _errorMessage;
  String? _createdProductId;
  double? _completedPlasticGrams;
  double? _completedCo2Grams;
  String? _finalReviewNotes;

  String? get activeWorkspaceId => _activeWorkspaceId;
  String? get activeProductName => _activeProductName;
  String? get activeMaterialType => _activeMaterialType;
  double? get activeWeightGrams => _activeWeightGrams;
  String? get finalReviewNotes => _finalReviewNotes;
  List<WorkspaceStepModel> get steps => List.unmodifiable(_steps);
  int get currentStepIndex => _currentStepIndex;
  bool get isLoading => _isLoading;
  bool get isWorkspaceComplete => _isWorkspaceComplete;
  String? get errorMessage => _errorMessage;
  WorkspaceStepModel? get currentStep {
    if (_steps.isEmpty) return null;
    final index = _currentStepIndex.clamp(0, _steps.length - 1).toInt();
    return _steps[index];
  }
  String? get createdProductId => _createdProductId;
  double? get completedPlasticGrams => _completedPlasticGrams;
  double? get completedCo2Grams => _completedCo2Grams;

  List<Map<String, dynamic>> _allWorkspaces = [];
  bool _isLoadingAll = false;

  List<Map<String, dynamic>> get allWorkspaces => _allWorkspaces;
  bool get isLoadingAll => _isLoadingAll;

  static const Map<String, List<Map<String, dynamic>>> _stepTemplates = {
    'tas_sachet': [
      {
        'stepNumber': 1,
        'title': 'Potong Sachet',
        'instruction': 'Potong sachet menjadi strip dengan lebar konsisten 2–3 cm menggunakan penggaris dan gunting.',
        'technicalCriteria': [
          'Lebar potongan rata-rata 20-30 mm',
          'Konsisten di sepanjang strip',
          'Potongan lurus dan bersih',
        ],
        'milestoneIndex': 0,
        'requiresValidation': true,
        'validationType': 'fold_alignment',
      },
      {
        'stepNumber': 2,
        'title': 'Lipat Kiri',
        'instruction': 'Lipat sisi kiri strip ke tengah, rapikan sehingga tepi lipatan sejajar dengan tepi strip.',
        'technicalCriteria': [
          'Sudut deviasi lipatan kiri ≤ 8°',
          'Lipatan lurus rata',
        ],
        'milestoneIndex': 0,
        'requiresValidation': true,
        'validationType': 'fold_alignment',
      },
      {
        'stepNumber': 3,
        'title': 'Lipat Kanan',
        'instruction': 'Lipat sisi kanan strip ke tengah, tumpuk rapi di atas lipatan kiri.',
        'technicalCriteria': [
          'Sudut deviasi lipatan kanan ≤ 8°',
          'Area tumpang tindih ≥ 60% lebar strip',
        ],
        'milestoneIndex': 0,
        'requiresValidation': true,
        'validationType': 'fold_alignment',
      },
      {
        'stepNumber': 4,
        'title': 'Lipat Memanjang',
        'instruction': 'Lipat strip menjadi dua memanjang, sehingga lebar akhir menjadi setelah dari lebar sebelumnya.',
        'technicalCriteria': [
          'Lebar strip setelah dilipat rata setengah dari lebar awal',
          'Sisi strip rata',
        ],
        'milestoneIndex': 0,
        'requiresValidation': true,
        'validationType': 'fold_alignment',
      },
      {
        'stepNumber': 5,
        'title': 'Lipat Tengah',
        'instruction': 'Lipat strip sekali lagi di titik tengah membentuk unit dasar siap-anyam.',
        'technicalCriteria': [
          'Terbagi menjadi dua bagian sama panjang',
          'Selisih panjang lipatan kiri vs kanan ≤ 10%',
        ],
        'milestoneIndex': 0,
        'requiresValidation': true,
        'validationType': 'fold_module',
      },
      {
        'stepNumber': 6,
        'title': 'Bentuk Modul V',
        'instruction': 'Bentuk dua strip yang sudah dilipat menjadi unit V (modul dasar anyaman).',
        'technicalCriteria': [
          'Bentuk modul menyerupai huruf V',
          'Kedua lengan modul berukuran sama',
        ],
        'milestoneIndex': 1,
        'requiresValidation': true,
        'validationType': 'fold_module',
      },
      {
        'stepNumber': 7,
        'title': 'Kotak Pertama',
        'instruction': 'Anyam modul V pertama menjadi unit kotak dasar (modul awal alas).',
        'technicalCriteria': [
          'Modul membentuk kotak persegi',
          'Sudut modul mendekati 90 derajat',
        ],
        'milestoneIndex': 1,
        'requiresValidation': true,
        'validationType': 'fold_module',
      },
      {
        'stepNumber': 8,
        'title': 'Alas Tas',
        'instruction': 'Sambungkan beberapa modul kotak menjadi alas tas berbentuk grid rapi.',
        'technicalCriteria': [
          'Grid alas simetris dan rectangular',
          'Tidak ada lubang/gap besar pada alas',
        ],
        'milestoneIndex': 1,
        'requiresValidation': true,
        'validationType': 'weave_base',
      },
      {
        'stepNumber': 9,
        'title': 'Dinding Tas',
        'instruction': 'Bangun dinding tas dari alas ke atas dengan tinggi yang konsisten di semua sisi.',
        'technicalCriteria': [
          'Dinding tegak dan lurus',
          'Deviasi tinggi antar 4 sisi ≤ 12%',
        ],
        'milestoneIndex': 2,
        'requiresValidation': true,
        'validationType': 'weave_wall',
      },
      {
        'stepNumber': 10,
        'title': 'Finishing',
        'instruction': 'Rapikan semua ujung anyaman yang menonjol, sembunyikan ke dalam struktur.',
        'technicalCriteria': [
          'Ujung anyaman tersembunyi rapi',
          'Permukaan anyaman rata tanpa bagian menonjol',
        ],
        'milestoneIndex': 3,
        'requiresValidation': true,
        'validationType': 'finishing',
      },
      {
        'stepNumber': 11,
        'title': 'Handle',
        'instruction': 'Buat dua tali handle dari strip yang dianyam rapat, panjang sama kiri-kanan.',
        'technicalCriteria': [
          'Mempunyai panjang handle yang simetris',
          'Rapat dan kokoh',
        ],
        'milestoneIndex': 4,
        'requiresValidation': true,
        'validationType': 'handle',
      },
      {
        'stepNumber': 12,
        'title': 'Pasang Handle',
        'instruction': 'Pasang kedua handle ke badan tas dengan posisi simetris di sisi kiri dan kanan.',
        'technicalCriteria': [
          'Posisi handle simetris dari sumbu tengah',
          'Sambungan handle kokoh',
        ],
        'milestoneIndex': 4,
        'requiresValidation': true,
        'validationType': 'handle',
      },
    ],
    'lampu_botol_pet': [
      {
        'stepNumber': 1,
        'title': 'Persiapan Botol PET',
        'instruction': 'Bersihkan botol PET dari label dan sisa cairan. Keringkan sempurna. Siapkan alat untuk membuat lubang.',
        'technicalCriteria': [
          'Botol bersih dari label dan residu',
          'Botol kering sepenuhnya',
          'Tidak ada retakan pada botol',
        ],
      },
      {
        'stepNumber': 2,
        'title': 'Pembuatan Lubang Kabel',
        'instruction': 'Buat lubang di bagian bawah botol untuk kabel lampu. Diameter lubang harus pas dengan kabel (sekitar 5-6mm).',
        'technicalCriteria': [
          'Lubang berdiameter 5-6mm',
          'Tepi lubang halus tidak tajam',
          'Posisi lubang di center bawah botol',
        ],
      },
      {
        'stepNumber': 3,
        'title': 'Pemasangan Komponen Lampu',
        'instruction': 'Masukkan fitting lampu melalui lubang. Pasang bohlam LED. Pastikan semua koneksi aman dan tidak ada kabel yang terekspos.',
        'technicalCriteria': [
          'Fitting terpasang kuat tidak goyang',
          'Bohlam terpasang sempurna',
          'Tidak ada kabel terekspos di luar botol',
        ],
      },
      {
        'stepNumber': 4,
        'title': 'Test & Finishing',
        'instruction': 'Test lampu menyala dengan benar. Hias bagian luar botol sesuai desain. Dokumentasikan hasil akhir.',
        'technicalCriteria': [
          'Lampu menyala normal tanpa kedip',
          'Suhu botol tidak panas berlebihan setelah 5 menit',
          'Finishing estetik rapi',
        ],
      },
    ],
    'kertas': [
      {
        'stepNumber': 1,
        'title': 'Sortir dan Siapkan Kertas',
        'instruction': 'Pisahkan kertas yang masih layak pakai dan bersihkan dari staples atau perekat berlebih.',
        'technicalCriteria': ['Kertas bersih', 'Tidak lembap', 'Potongan seragam'],
      },
      {
        'stepNumber': 2,
        'title': 'Bentuk Produk',
        'instruction': 'Lipat atau anyam kertas sesuai pola produk yang dipilih.',
        'technicalCriteria': ['Bentuk konsisten', 'Sambungan rapi', 'Ukuran sesuai template'],
      },
    ],
    'kain': [
      {
        'stepNumber': 1,
        'title': 'Potong Kain',
        'instruction': 'Potong kain menjadi pola dasar sesuai rancangan.',
        'technicalCriteria': ['Ukuran sesuai pola', 'Tepi kain rapi'],
      },
      {
        'stepNumber': 2,
        'title': 'Jahit dan Finishing',
        'instruction': 'Rakit bagian kain dan lakukan finishing pada tepi produk.',
        'technicalCriteria': ['Jahitan kuat', 'Finishing bersih'],
      },
    ],
  };

  Future<void> fetchActiveWorkspace(String userId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final query = await _firestore
          .collection('workspaces')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'in_progress')
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        final data = doc.data();
        
        final stepsData = data['steps'] as List<dynamic>? ?? [];
        final mappedSteps = stepsData
            .map((item) => WorkspaceStepModel.fromMap(Map<String, dynamic>.from(item as Map)))
            .toList();

        // Only set active state if mapping succeeds
        _activeWorkspaceId = doc.id;
        _activeProductName = data['productName'] as String?;
        _activeMaterialType = data['materialType'] as String?;
        _activeWeightGrams = (data['weightGrams'] as num?)?.toDouble();
        _steps = mappedSteps;
        
        _currentStepIndex = 0;
        for (int i = 0; i < _steps.length; i++) {
          if (!_steps[i].isCompleted) {
            _currentStepIndex = i;
            break;
          }
        }
        
        _isWorkspaceComplete = false;
        _createdProductId = null;
        _completedPlasticGrams = null;
        _completedCo2Grams = null;
      } else {
        _activeWorkspaceId = null;
        _steps = [];
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Gagal memuat workspace aktif: $e';
      _activeWorkspaceId = null;
      _steps = [];
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAllWorkspaces(String userId) async {
    try {
      _isLoadingAll = true;
      notifyListeners();

      final query = await _firestore
          .collection('workspaces')
          .where('userId', isEqualTo: userId)
          .get();

      final docs = query.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      docs.sort((a, b) {
        final aTime = a['startedAt'] as Timestamp?;
        final bTime = b['startedAt'] as Timestamp?;
        if (aTime == null || bTime == null) return 0;
        return bTime.compareTo(aTime); // descending order
      });

      _allWorkspaces = docs;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching all workspaces: $e');
    } finally {
      _isLoadingAll = false;
      notifyListeners();
    }
  }

  Future<void> loadWorkspaceAsActive(String workspaceId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final doc = await _firestore.collection('workspaces').doc(workspaceId).get();
      if (doc.exists) {
        final data = doc.data()!;
        _activeWorkspaceId = doc.id;
        _activeProductName = data['productName'] as String?;
        _activeMaterialType = data['materialType'] as String?;
        _activeWeightGrams = (data['weightGrams'] as num?)?.toDouble();
        
        final stepsData = data['steps'] as List<dynamic>? ?? [];
        _steps = stepsData
            .map((item) => WorkspaceStepModel.fromMap(Map<String, dynamic>.from(item as Map)))
            .toList();
        
        _currentStepIndex = 0;
        for (int i = 0; i < _steps.length; i++) {
          if (!_steps[i].isCompleted) {
            _currentStepIndex = i;
            break;
          }
        }
        _isWorkspaceComplete = false;
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Gagal memuat workspace: $e';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> startWorkspace(String userId, String productName, String materialType, double weightGrams) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final workspaceRef = _firestore.collection('workspaces').doc();
      final normalizedKey = _normalizeProductName(productName);
      _steps = _buildSteps(normalizedKey);
      _activeWorkspaceId = workspaceRef.id;
      _activeProductName = productName;
      _activeMaterialType = materialType;
      _activeWeightGrams = weightGrams;
      _currentStepIndex = 0;
      _isWorkspaceComplete = false;
      _createdProductId = null;
      _completedPlasticGrams = null;
      _completedCo2Grams = null;

      // Seed & Fetch references from Firestore
      final stepsRef = _firestore
          .collection('workspace_references')
          .doc(normalizedKey)
          .collection('steps');

      var querySnap = await stepsRef.get();
      if (querySnap.docs.isEmpty) {
        await _seedWorkspaceReferences(normalizedKey);
        querySnap = await stepsRef.get();
      }

      final refDataMap = <int, Map<String, dynamic>>{};
      for (var doc in querySnap.docs) {
        final stepNum = int.tryParse(doc.id.replaceAll('step_', '')) ?? 0;
        if (stepNum > 0) {
          refDataMap[stepNum] = doc.data();
        }
      }

      for (int i = 0; i < _steps.length; i++) {
        final stepNum = _steps[i].stepNumber;
        final refData = refDataMap[stepNum];
        if (refData != null) {
          _steps[i] = _steps[i].copyWith(
            referenceImageUrl: refData['idealImage'] as String?,
            badExampleUrl: refData['badExample'] as String?,
            videoUrl: refData['videoUrl'] as String?,
          );
        } else {
          _steps[i] = _steps[i].copyWith(
            referenceImageUrl: _fallbackIdealUrl(normalizedKey, stepNum),
            badExampleUrl: _fallbackBadUrl(normalizedKey, stepNum),
            videoUrl: 'https://www.w3schools.com/html/mov_bbb.mp4',
          );
        }
      }

      await workspaceRef.set({
        'userId': userId,
        'productName': productName,
        'materialType': materialType,
        'weightGrams': weightGrams,
        'status': 'in_progress',
        'steps': _steps.map((step) => step.toMap()).toList(),
        'startedAt': Timestamp.now(),
        'completedAt': null,
      });

      notifyListeners();
    } catch (e) {
      _errorMessage = 'Gagal memulai workspace: $e';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> uploadStepEvidence(File imageFile) async {
    final workspaceId = _activeWorkspaceId;
    final currentStep = this.currentStep;
    if (workspaceId == null || currentStep == null) return;
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final url = await _storageService.uploadImage(
        imageFile,
        'workspaces/$workspaceId/step_${currentStep.stepNumber}.jpg',
      );

      _steps[_currentStepIndex] = currentStep.copyWith(
        evidenceImageUrl: url,
      );

      await _firestore.collection('workspaces').doc(workspaceId).update({
        'steps': _steps.map((step) => step.toMap()).toList(),
      });
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Gagal mengunggah foto bukti: $e';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> uploadAndValidateStepEvidence(
    File imageFile,
    VisualValidationService validationService,
  ) async {
    final workspaceId = _activeWorkspaceId;
    final currentStep = this.currentStep;
    if (workspaceId == null || currentStep == null) return;
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      if (!currentStep.requiresValidation) {
        _isLoading = false;
        await uploadStepEvidence(imageFile);
        return;
      }

      Map<String, dynamic>? baselineData;
      if (currentStep.validationType == 'fold_alignment' && currentStep.stepNumber == 4) {
        final step1 = _steps.firstWhere((s) => s.stepNumber == 1, orElse: () => currentStep);
        if (step1.validationResult != null) {
          baselineData = {
            'measuredWidthMm': step1.validationResult!.score,
          };
        }
      }

      final result = await validationService.validateStep(
        imageFile: imageFile,
        workspaceId: workspaceId,
        stepNumber: currentStep.stepNumber,
        validationType: currentStep.validationType,
        baselineData: baselineData,
      );

      int updatedRetryCount = currentStep.retryCount;
      if (!result.isValid) {
        updatedRetryCount += 1;
      }

      _steps[_currentStepIndex] = currentStep.copyWith(
        evidenceImageUrl: result.validatedImageUrl,
        validationResult: result,
        retryCount: updatedRetryCount,
        qualityScore: result.score,
      );

      await _firestore.collection('workspaces').doc(workspaceId).update({
        'steps': _steps.map((step) => step.toMap()).toList(),
      });
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Gagal memproses dan menganalisis foto bukti: $e';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> bypassStepValidation() async {
    final workspaceId = _activeWorkspaceId;
    final currentStep = this.currentStep;
    if (workspaceId == null || currentStep == null) return;
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final updatedResult = VisualValidationModel(
        isValid: true,
        score: 60,
        status: 'manual_override',
        feedback: const ['Validasi dilewati secara manual oleh pengguna setelah beberapa kali kegagalan.'],
        validatedImageUrl: currentStep.evidenceImageUrl ?? '',
        validatedAt: Timestamp.now(),
      );

      _steps[_currentStepIndex] = currentStep.copyWith(
        validationResult: updatedResult,
      );

      await _firestore.collection('workspaces').doc(workspaceId).update({
        'steps': _steps.map((step) => step.toMap()).toList(),
      });
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Gagal melakukan bypass: $e';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> confirmStepComplete() async {
    final workspaceId = _activeWorkspaceId;
    final currentStep = this.currentStep;
    if (workspaceId == null || currentStep == null) return;
    try {
      _isLoading = true;
      _errorMessage = null;

      if (currentStep.requiresValidation &&
          currentStep.evidenceImageUrl == null &&
          (currentStep.validationResult == null || !currentStep.validationResult!.isValid) &&
          currentStep.validationResult?.status != 'manual_override') {
        throw Exception('Langkah ini memerlukan verifikasi visual sebelum dapat dilanjutkan.');
      }

      final completedStep = currentStep.copyWith(isCompleted: true, completedAt: Timestamp.now());
      _steps[_currentStepIndex] = completedStep;
      await _firestore.collection('workspaces').doc(workspaceId).update({
        'steps': _steps.map((step) => step.toMap()).toList(),
      });

      if (_currentStepIndex < _steps.length - 1) {
        _currentStepIndex += 1;
        notifyListeners();
      } else {
        await _completeWorkspace();
      }
    } catch (_) {
      _errorMessage = 'Gagal mengonfirmasi langkah.';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _completeWorkspace() async {
    final workspaceId = _activeWorkspaceId;
    if (workspaceId == null) return;
    final materialType = _activeMaterialType ?? 'lainnya';
    final plasticGrams = _activeWeightGrams ?? 0;
    final co2Saved = ImpactCalculator.calculateCo2Saved(plasticGrams);
    final transparencySteps = _steps
        .map((step) => step.evidenceImageUrl)
        .whereType<String>()
        .toList();
    final productRef = _firestore.collection('products').doc();

    final category = _inferCategory(_activeProductName ?? 'lainnya');
    final imageUrls = transparencySteps.isNotEmpty
        ? transparencySteps
        : [
            'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?auto=format&fit=crop&w=900&q=60',
          ];

    final product = ProductModel(
      id: productRef.id,
      creatorId: FirebaseAuth.instance.currentUser?.uid ?? '',
      creatorName: FirebaseAuth.instance.currentUser?.displayName ?? 'Kreator',
      title: _activeProductName ?? 'Produk Sirkulara',
      description: 'Produk upcycling hasil workspace terverifikasi dari material $materialType.',
      category: category,
      price: 0,
      imageUrls: imageUrls,
      materialType: materialType,
      weightGrams: plasticGrams,
      co2OffsetGrams: co2Saved,
      isVerified: true,
      workspaceId: workspaceId,
      transparencySteps: transparencySteps,
      status: 'draft',
      createdAt: Timestamp.now(),
    );

    String? finalNotes;
    const apiKey = String.fromEnvironment('OPENAI_API_KEY');
    if (apiKey.isEmpty || apiKey == 'YOUR_OPENAI_API_KEY_HERE' || !apiKey.startsWith('sk-')) {
      throw Exception('OpenAI API Key tidak valid atau masih menggunakan placeholder. Harap masukkan API Key OpenAI asli yang diawali dengan "sk-" di dalam file env.json.');
    }
    
    try {
      final dio = Dio();
      final List<Map<String, dynamic>> contentList = [
        {
          'type': 'text',
          'text': 'Berikut adalah foto-foto dokumentasi proses pembuatan tas anyaman sachet saya dari langkah 1 sampai 12. Harap evaluasi kualitas produk akhirnya.'
        }
      ];
      
      for (var step in _steps) {
        if (step.evidenceImageUrl != null && step.evidenceImageUrl!.isNotEmpty) {
          contentList.add({
            'type': 'image_url',
            'image_url': {'url': step.evidenceImageUrl}
          });
        }
      }

      final response = await dio.post(
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
              'content': "Kamu adalah quality reviewer untuk produk upcycling. Diberikan kumpulan foto dokumentasi proses pembuatan tas anyaman sachet (12 foto, satu per tahap), berikan catatan kualitas singkat dalam Bahasa Indonesia. Kembalikan HANYA JSON: { 'overallQuality': string (baik|cukup|perlu_perbaikan), 'notes': string (maks 2 kalimat) }"
            },
            {
              'role': 'user',
              'content': contentList,
            }
          ],
          'temperature': 0.3,
          'response_format': {'type': 'json_object'},
        },
      );

      final content = response.data['choices'][0]['message']['content'] as String? ?? '{}';
      final cleaned = content.replaceAll(RegExp(r'```json|```'), '').trim();
      final decoded = Map<String, dynamic>.from(jsonDecode(cleaned) as Map);
      finalNotes = decoded['notes'] as String?;
      if (finalNotes == null || finalNotes.isEmpty) {
        throw Exception('Response OpenAI tidak mengandung field "notes".');
      }
    } catch (e) {
      debugPrint('Gagal memanggil OpenAI untuk review produk akhir: $e');
      rethrow;
    }

    _finalReviewNotes = finalNotes;

    await _firestore.collection('workspaces').doc(workspaceId).update({
      'status': 'completed',
      'completedAt': Timestamp.now(),
      'steps': _steps.map((step) => step.toMap()).toList(),
      'finalReviewNotes': finalNotes,
    });
    await productRef.set(product.toMap());

    _createdProductId = productRef.id;
    _completedPlasticGrams = plasticGrams;
    _completedCo2Grams = co2Saved;
    _isWorkspaceComplete = true;
    notifyListeners();
  }

  void resetWorkspace() {
    _activeWorkspaceId = null;
    _activeProductName = null;
    _activeMaterialType = null;
    _activeWeightGrams = null;
    _steps = [];
    _currentStepIndex = 0;
    _isLoading = false;
    _isWorkspaceComplete = false;
    _errorMessage = null;
    _createdProductId = null;
    _completedPlasticGrams = null;
    _completedCo2Grams = null;
    _finalReviewNotes = null;
    notifyListeners();
  }

  void previousStep() {
    if (_currentStepIndex > 0) {
      _currentStepIndex--;
      notifyListeners();
    }
  }

  void nextStep() {
    if (_currentStepIndex < _steps.length - 1) {
      _currentStepIndex++;
      notifyListeners();
    }
  }

  String _normalizeProductName(String productName) {
    return productName.toLowerCase().trim().replaceAll(RegExp(r'\s+'), '_');
  }

  List<WorkspaceStepModel> _buildSteps(String key) {
    final catalogSteps = CatalogService().getSteps(key);
    if (catalogSteps.isNotEmpty) {
      return catalogSteps.map((item) => WorkspaceStepModel.fromMap(item)).toList();
    }

    final template = _stepTemplates[key] ?? [
      {
        'stepNumber': 1,
        'title': 'Persiapan Material',
        'instruction': 'Siapkan material dan pastikan kondisi awal sesuai untuk proses workspace.',
        'technicalCriteria': ['Material tersedia', 'Material siap diproses'],
        'milestoneIndex': 0,
        'requiresValidation': false,
      },
      {
        'stepNumber': 2,
        'title': 'Proses Pembuatan',
        'instruction': 'Lakukan proses utama sesuai rancangan produk.',
        'technicalCriteria': ['Proses selesai', 'Hasil rapi'],
        'milestoneIndex': 1,
        'requiresValidation': false,
      },
      {
        'stepNumber': 3,
        'title': 'Finishing',
        'instruction': 'Selesaikan detailing dan cek kualitas akhir produk.',
        'technicalCriteria': ['Finishing selesai', 'Kualitas terverifikasi'],
        'milestoneIndex': 2,
        'requiresValidation': false,
      },
    ];
    return template.map((item) => WorkspaceStepModel.fromMap(item)).toList();
  }

  String _inferCategory(String productName) {
    final lower = productName.toLowerCase();
    if (lower.contains('tas')) return 'aksesori';
    if (lower.contains('lampu') || lower.contains('dekor')) return 'dekorasi';
    if (lower.contains('meja') || lower.contains('furnitur')) return 'furnitur';
    return 'lainnya';
  }

  Future<void> _seedWorkspaceReferences(String productName) async {
    final refDoc = _firestore.collection('workspace_references').doc(productName);
    final stepsColl = refDoc.collection('steps');

    if (productName == 'tas_sachet') {
      final stepsData = {
        'step_1': {
          'idealImage': 'https://images.unsplash.com/photo-1611080626919-7cf5a9dbab5b?auto=format&fit=crop&w=600&q=80',
          'badExample': 'https://images.unsplash.com/photo-1530587191325-3db32d826c18?auto=format&fit=crop&w=600&q=80',
          'videoUrl': 'https://www.w3schools.com/html/mov_bbb.mp4',
        },
        'step_2': {
          'idealImage': 'https://images.unsplash.com/photo-1589156280159-27698a70f29e?auto=format&fit=crop&w=600&q=80',
          'badExample': 'https://images.unsplash.com/photo-1595273670150-bd0c3c392e46?auto=format&fit=crop&w=600&q=80',
          'videoUrl': 'https://www.w3schools.com/html/mov_bbb.mp4',
        },
        'step_3': {
          'idealImage': 'https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?auto=format&fit=crop&w=600&q=80',
          'badExample': 'https://images.unsplash.com/photo-1541675154750-0444c7d51e8e?auto=format&fit=crop&w=600&q=80',
          'videoUrl': 'https://www.w3schools.com/html/mov_bbb.mp4',
        },
        'step_4': {
          'idealImage': 'https://images.unsplash.com/photo-1544816155-12df9643f363?auto=format&fit=crop&w=600&q=80',
          'badExample': 'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=600&q=80',
          'videoUrl': 'https://www.w3schools.com/html/mov_bbb.mp4',
        },
        'step_5': {
          'idealImage': 'https://images.unsplash.com/photo-1618220179428-22790b461013?auto=format&fit=crop&w=600&q=80',
          'badExample': 'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=600&q=80',
          'videoUrl': 'https://www.w3schools.com/html/mov_bbb.mp4',
        },
        'step_6': {
          'idealImage': 'https://images.unsplash.com/photo-1513519245088-0e12902e5a38?auto=format&fit=crop&w=600&q=80',
          'badExample': 'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=600&q=80',
          'videoUrl': 'https://www.w3schools.com/html/mov_bbb.mp4',
        },
        'step_7': {
          'idealImage': 'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?auto=format&fit=crop&w=600&q=80',
          'badExample': 'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=600&q=80',
          'videoUrl': 'https://www.w3schools.com/html/mov_bbb.mp4',
        },
        'step_8': {
          'idealImage': 'https://images.unsplash.com/photo-1506084868230-bb9d95c24759?auto=format&fit=crop&w=600&q=80',
          'badExample': 'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=600&q=80',
          'videoUrl': 'https://www.w3schools.com/html/mov_bbb.mp4',
        },
        'step_9': {
          'idealImage': 'https://images.unsplash.com/photo-1540555700478-4be289fbecef?auto=format&fit=crop&w=600&q=80',
          'badExample': 'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=600&q=80',
          'videoUrl': 'https://www.w3schools.com/html/mov_bbb.mp4',
        },
        'step_10': {
          'idealImage': 'https://images.unsplash.com/photo-1507473885765-e6ed057f782c?auto=format&fit=crop&w=600&q=80',
          'badExample': 'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=600&q=80',
          'videoUrl': 'https://www.w3schools.com/html/mov_bbb.mp4',
        },
        'step_11': {
          'idealImage': 'https://images.unsplash.com/photo-1565814636199-ae8133055c1c?auto=format&fit=crop&w=600&q=80',
          'badExample': 'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=600&q=80',
          'videoUrl': 'https://www.w3schools.com/html/mov_bbb.mp4',
        },
        'step_12': {
          'idealImage': 'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?auto=format&fit=crop&w=600&q=80',
          'badExample': 'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=600&q=80',
          'videoUrl': 'https://www.w3schools.com/html/mov_bbb.mp4',
        },
      };

      for (var entry in stepsData.entries) {
        await stepsColl.doc(entry.key).set(entry.value);
      }
    } else if (productName == 'lampu_botol_pet') {
      await stepsColl.doc('step_1').set({
        'idealImage': 'https://images.unsplash.com/photo-1501959915551-4e8d30928317?auto=format&fit=crop&w=600&q=80',
        'badExample': 'https://images.unsplash.com/photo-1527018601619-a508a2be00cd?auto=format&fit=crop&w=600&q=80',
        'videoUrl': 'https://www.w3schools.com/html/mov_bbb.mp4',
      });
      await stepsColl.doc('step_2').set({
        'idealImage': 'https://images.unsplash.com/photo-1527018601619-a508a2be00cd?auto=format&fit=crop&w=600&q=80',
        'badExample': 'https://images.unsplash.com/photo-1501959915551-4e8d30928317?auto=format&fit=crop&w=600&q=80',
        'videoUrl': 'https://www.w3schools.com/html/mov_bbb.mp4',
      });
      await stepsColl.doc('step_3').set({
        'idealImage': 'https://images.unsplash.com/photo-1565814636199-ae8133055c1c?auto=format&fit=crop&w=600&q=80',
        'badExample': 'https://images.unsplash.com/photo-1527018601619-a508a2be00cd?auto=format&fit=crop&w=600&q=80',
        'videoUrl': 'https://www.w3schools.com/html/mov_bbb.mp4',
      });
      await stepsColl.doc('step_4').set({
        'idealImage': 'https://images.unsplash.com/photo-1507473885765-e6ed057f782c?auto=format&fit=crop&w=600&q=80',
        'badExample': 'https://images.unsplash.com/photo-1565814636199-ae8133055c1c?auto=format&fit=crop&w=600&q=80',
        'videoUrl': 'https://www.w3schools.com/html/mov_bbb.mp4',
      });
    } else {
      for (int i = 1; i <= 3; i++) {
        await stepsColl.doc('step_$i').set({
          'idealImage': 'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?auto=format&fit=crop&w=600&q=80',
          'badExample': 'https://images.unsplash.com/photo-1506084868230-bb9d95c24759?auto=format&fit=crop&w=600&q=80',
          'videoUrl': 'https://www.w3schools.com/html/mov_bbb.mp4',
        });
      }
    }
  }

  String _fallbackIdealUrl(String productName, int stepNumber) {
    return WorkspaceReferenceData.getIdealUrl(productName, stepNumber);
  }

  String _fallbackBadUrl(String productName, int stepNumber) {
    return WorkspaceReferenceData.getBadUrl(productName, stepNumber);
  }
}
