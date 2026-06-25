import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:gap/gap.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../services/workspace_service.dart';
import '../../services/visual_validation_service.dart';
import 'weaving_camera_screen.dart';
import 'widgets/annotated_image_widget.dart';
import 'widgets/validation_result_card.dart';

class WorkspaceStepScreen extends StatefulWidget {
  const WorkspaceStepScreen({super.key});

  @override
  State<WorkspaceStepScreen> createState() => _WorkspaceStepScreenState();
}

class _WorkspaceStepScreenState extends State<WorkspaceStepScreen> {
  bool _navigated = false;

  Future<void> _pickEvidence(
    ImageSource source,
    String stepTitle,
    int stepNumber,
    String validationType,
  ) async {
    final workspaceService = context.read<WorkspaceService>();
    final validationService = context.read<VisualValidationService>();

    if (source == ImageSource.camera) {
      final resultFile = await Navigator.push<File>(
        context,
        MaterialPageRoute(
          builder: (context) => WeavingCameraScreen(
            validationType: validationType,
            stepNumber: stepNumber,
            title: stepTitle,
          ),
        ),
      );
      if (resultFile == null) return;
      if (!mounted) return;

      await workspaceService.uploadAndValidateStepEvidence(resultFile, validationService);
    } else {
      final picker = ImagePicker();
      final file = await picker.pickImage(source: source, imageQuality: 90);
      if (file == null) return;
      if (!mounted) return;

      await workspaceService.uploadAndValidateStepEvidence(File(file.path), validationService);
    }
  }

  Future<void> _showPicker(String stepTitle, int stepNumber, String validationType) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Unggah Foto Hasil Progres',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1C19),
                ),
              ),
              const Gap(16),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF1D6940)),
                title: const Text('Ambil Foto Kamera', style: TextStyle(fontWeight: FontWeight.w500)),
                onTap: () {
                  Navigator.pop(context);
                  _pickEvidence(ImageSource.camera, stepTitle, stepNumber, validationType);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF1D6940)),
                title: const Text('Pilih dari Galeri', style: TextStyle(fontWeight: FontWeight.w500)),
                onTap: () {
                  Navigator.pop(context);
                  _pickEvidence(ImageSource.gallery, stepTitle, stepNumber, validationType);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkspaceService>(
      builder: (context, workspace, _) {
        if (workspace.isWorkspaceComplete && !_navigated) {
          _navigated = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/workspace-complete');
            }
          });
        }

        final step = workspace.currentStep;
        if (step == null) {
          return Scaffold(
            backgroundColor: const Color(0xFFFAFAF4),
            appBar: AppBar(
              title: const Text('Workspace Step'),
              backgroundColor: const Color(0xFFFAFAF4),
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1C19)),
                onPressed: () => Navigator.maybePop(context),
              ),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.info_outline, size: 48, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      workspace.errorMessage ?? 'Belum ada workspace aktif',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final isEvidenceUploaded = step.evidenceImageUrl != null;

        final isPassed = step.requiresValidation
            ? (isEvidenceUploaded || (step.validationResult != null && step.validationResult!.isValid))
            : true;

        final isStepValid = !step.requiresValidation || 
            isEvidenceUploaded ||
            (step.validationResult != null && 
             (step.validationResult!.isValid || step.validationResult!.status == 'manual_override'));

        final progressPercent = workspace.steps.isEmpty 
            ? 0 
            : ((workspace.currentStepIndex + 1) / workspace.steps.length * 100).round();

        final showBypass = step.requiresValidation && step.retryCount >= 3 && !isPassed;

        return Scaffold(
          backgroundColor: const Color(0xFFFAFAF4),
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(64),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.maybePop(context),
                          child: const Icon(Icons.arrow_back, color: Color(0xFF1A1C19), size: 24),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Sirkulara',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF404941),
                              ),
                            ),
                            Text(
                              workspace.activeProductName ?? 'Circular Craft',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1C19),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFCCEA9D),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            '$progressPercent%',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF364E12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.notifications_none, size: 20, color: Color(0xFF1A1C19)),
                            onPressed: () {},
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          body: Stack(
            children: [
              // Header Gradient Background
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 200,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFFCCEA9D),
                        Color(0xFFFAFAF4),
                      ],
                    ),
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Column(
                  children: [
                    // Progress bar area
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Tutorial Progress',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF404941),
                                ),
                              ),
                              Text(
                                'Step ${workspace.currentStepIndex + 1} of ${workspace.steps.length}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF404941),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 4,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE3E3DE),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: FractionallySizedBox(
                                widthFactor: workspace.steps.isEmpty 
                                    ? 0 
                                    : (workspace.currentStepIndex + 1) / workspace.steps.length,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1D6940),
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Main Scrollable Content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Main Instruction Card
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF1D6940).withValues(alpha: 0.05),
                                    blurRadius: 30,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (step.referenceImageUrl != null)
                                    Container(
                                      height: 220,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        color: const Color(0xFFEEEEE9),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: CachedNetworkImage(
                                        imageUrl: step.referenceImageUrl!,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => const Center(
                                          child: CircularProgressIndicator(strokeWidth: 3),
                                        ),
                                        errorWidget: (context, url, error) => const Icon(
                                          Icons.image,
                                          color: Colors.grey,
                                          size: 48,
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Step ${step.stepNumber}: ${step.title}',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1D6940),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    step.instruction,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      height: 1.5,
                                      color: Color(0xFF404941),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Gap(16),

                            // Technical Criteria Section
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF1D6940).withValues(alpha: 0.05),
                                    blurRadius: 30,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'TECHNICAL CRITERIA',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF707A71),
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ...step.technicalCriteria.map(
                                    (criteria) => Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: isEvidenceUploaded && isPassed 
                                                  ? const Color(0xFFCCEA9D) 
                                                  : Colors.transparent,
                                              border: isEvidenceUploaded && isPassed 
                                                  ? null 
                                                  : Border.all(color: const Color(0xFFBFC9BF), width: 2),
                                            ),
                                            child: isEvidenceUploaded && isPassed 
                                                ? const Icon(
                                                    Icons.check_circle,
                                                    color: Color(0xFF364E12),
                                                    size: 20,
                                                  )
                                                : null,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              criteria,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Color(0xFF1A1C19),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Gap(16),

                            // Log Progres Kreasi Section (When photo is uploaded)
                            if (isEvidenceUploaded) ...[
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF1D6940).withValues(alpha: 0.05),
                                      blurRadius: 30,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'LOG PROGRES KREASI',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF707A71),
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Container(
                                      height: 220,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        color: const Color(0xFFEEEEE9),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: AnnotatedImageWidget(
                                        imageUrl: step.evidenceImageUrl!,
                                        annotations: step.validationResult?.annotations ?? const [],
                                        height: 220,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    if (step.validationResult != null) ...[
                                      ValidationResultCard(result: step.validationResult!),
                                      const SizedBox(height: 12),
                                    ],
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isPassed 
                                            ? const Color(0xFFCCEA9D).withValues(alpha: 0.3)
                                            : const Color(0xFFFFDAD6).withValues(alpha: 0.3),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isPassed 
                                              ? const Color(0xFFCCEA9D).withValues(alpha: 0.5)
                                              : const Color(0xFFFFDAD6).withValues(alpha: 0.5),
                                        ),
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Icon(
                                            isPassed ? Icons.check_circle : Icons.error,
                                            color: isPassed ? const Color(0xFF1D6940) : const Color(0xFFBA1A1A),
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              isPassed
                                                  ? 'Progres Tercatat: Langkah ${step.stepNumber} berhasil didokumentasikan. ${step.title} telah terekam dalam log proyek Anda.'
                                                  : 'Verifikasi Gagal: Beberapa kriteria belum terpenuhi. Silakan coba ambil foto ulang.',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Color(0xFF1A1C19),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Gap(16),
                            ],

                            // Loading Verification State
                            if (workspace.isLoading) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1D6940).withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(color: const Color(0xFF1D6940).withValues(alpha: 0.1)),
                                ),
                                child: Column(
                                  children: const [
                                    CircularProgressIndicator(color: Color(0xFF1D6940)),
                                    SizedBox(height: 16),
                                    Text(
                                      'Kopilot AI sedang memverifikasi hasil...',
                                      style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1D6940)),
                                    ),
                                    SizedBox(height: 4),
                                    Text('Mengidentifikasi anyaman & lipatan Anda', style: TextStyle(fontSize: 11, color: Color(0xFF707A71))),
                                  ],
                                ),
                              ),
                              const Gap(16),
                            ],

                            // Milestone Highlight (Locked / Unlocked)
                            if (isPassed) ...[
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1D6940).withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFF1D6940).withValues(alpha: 0.15),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF1D6940),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.auto_fix_high,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Milestone Unlocked',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1D6940),
                                            ),
                                          ),
                                          Text(
                                            'Ready for: ${step.validationType}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: Color(0xFF404941),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ] else ...[
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEEEEE9),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFDADAD5),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.lock,
                                        color: Color(0xFF404941),
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: const [
                                          Text(
                                            'Locked Milestone',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF404941),
                                            ),
                                          ),
                                          Text(
                                            'Complete this step to unlock your next milestone.',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF404941),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            // Lewati Validasi Option
                            if (showBypass) ...[
                              const Gap(16),
                              SizedBox(
                                width: double.infinity,
                                child: TextButton.icon(
                                  onPressed: () async {
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Lewati Validasi?'),
                                        content: const Text(
                                          'Anda telah mencoba beberapa kali dan hasil belum memenuhi standar. Apakah Anda ingin melewati validasi visual untuk langkah ini?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, false),
                                            child: const Text('Batal'),
                                          ),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFFBA1A1A),
                                              foregroundColor: Colors.white,
                                            ),
                                            onPressed: () => Navigator.pop(context, true),
                                            child: const Text('Ya, Lewati'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirmed == true) {
                                      await workspace.bypassStepValidation();
                                    }
                                  },
                                  icon: const Icon(Icons.warning_amber_rounded, size: 18),
                                  label: const Text('Lewati Validasi Langkah Ini'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFFBA1A1A),
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 120),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Bottom Navigation Bar
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 20,
                        offset: Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back Button
                      GestureDetector(
                        onTap: () {
                          if (workspace.currentStepIndex > 0) {
                            workspace.previousStep();
                          } else {
                            Navigator.maybePop(context);
                          }
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.chevron_left, color: Color(0xFF404941), size: 28),
                            Text(
                              'Back',
                              style: TextStyle(fontSize: 10, color: Color(0xFF404941), fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                      // Capture Button
                      GestureDetector(
                        onTap: () => _showPicker(step.title, step.stepNumber, step.validationType),
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: const BoxDecoration(
                            color: Color(0xFF1D6940),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.photo_camera,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                      // Next Button
                      Opacity(
                        opacity: isStepValid ? 1.0 : 0.4,
                        child: GestureDetector(
                          onTap: !isStepValid
                              ? null
                              : () async {
                                  await workspace.confirmStepComplete();
                                },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.chevron_right, color: Color(0xFF404941), size: 28),
                              Text(
                                'Next',
                                style: TextStyle(fontSize: 10, color: Color(0xFF404941), fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
