import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:gap/gap.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../services/auth_service.dart';
import '../../services/scanner_service.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> with TickerProviderStateMixin {
  String? _lastErrorShown;
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final service = context.read<ScannerService>();
    await service.pickImage(source);
    if (!mounted) return;
    if (service.selectedImage != null) {
      final auth = context.read<AuthService>();
      final user = auth.currentUser;
      if (user == null) return;
      await service.analyzeScan(user.uid);
      if (!mounted) return;
      if (service.lastScanResult != null) {
        Navigator.pushNamed(context, '/scan-result');
      }
    }
  }

  void _showPickerSheet() {
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
                'Pilih Sumber Foto',
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
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF1D6940)),
                title: const Text('Pilih dari Galeri', style: TextStyle(fontWeight: FontWeight.w500)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
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
    return Consumer<ScannerService>(
      builder: (context, service, _) {
        if (service.errorMessage != null && service.errorMessage != _lastErrorShown) {
          _lastErrorShown = service.errorMessage;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: const Color(0xFFBA1A1A),
                content: Text(service.errorMessage ?? ''),
              ),
            );
          });
        }

        final image = service.selectedImage;

        return Scaffold(
          backgroundColor: const Color(0xFFFAFAF4),
          body: Stack(
            children: [
              // Gradient Header Background
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 280,
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
                bottom: false,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Sirkulara',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF404941),
                                ),
                              ),
                              Text(
                                'Material Scanner',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1A1C19),
                                ),
                              ),
                            ],
                          ),
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
                      const Gap(24),

                      if (service.isScanning && image != null) ...[
                        // Dynamic AI Vision Scanner UI (Laser scanner effect overlay)
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
                            children: [
                              Container(
                                height: 220,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: const Color(0xFFFAFAF4),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: ScanningOverlayWidget(imageFile: image),
                              ),
                              const SizedBox(height: 24),
                              const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Color(0xFF1D6940),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'AI vision sedang mendeteksi jenis limbah, berat material, dan kondisi kelayakan...',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1D6940),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        // Last Scan Card if exists
                        if (service.lastScanResult != null) ...[
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
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Hasil Scan Terakhir',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF404941),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _formatMaterial(service.lastScanResult!.materialType),
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF1A1C19),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFCCEA9D),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.recycling,
                                        color: Color(0xFF516A2C),
                                        size: 24,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Container(
                                      width: 64,
                                      height: 64,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF4F4EE),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: const Color(0xFFE3E3DE),
                                          width: 1,
                                        ),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: CachedNetworkImage(
                                        imageUrl: service.lastScanResult!.imageUrl,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => const Center(
                                          child: SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          ),
                                        ),
                                        errorWidget: (context, url, error) => const Icon(
                                          Icons.image,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Material: ${_formatMaterial(service.lastScanResult!.materialType)}',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: Color(0xFF404941),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Berat estimasi: ${service.lastScanResult!.weightGrams.toStringAsFixed(0)} gram',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: Color(0xFF404941),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.pushNamed(context, '/scan-result');
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1D6940),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: const Text(
                                      'Buka',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Gap(24),
                          // Divider
                          Row(
                            children: const [
                              Expanded(
                                child: Divider(color: Color(0xFFBFC9BF), thickness: 0.5),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'Atau Scan Baru',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF707A71),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(color: Color(0xFFBFC9BF), thickness: 0.5),
                              ),
                            ],
                          ),
                          const Gap(24),
                        ],

                        // Camera Scanner Lens Button Area
                        Center(
                          child: Column(
                            children: [
                              GestureDetector(
                                onTap: _showPickerSheet,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Circular loop visual (rotating border)
                                    RotationTransition(
                                      turns: _rotationController,
                                      child: Container(
                                        width: 256,
                                        height: 256,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: const Color(0xFF1D6940).withValues(alpha: 0.3),
                                            width: 2,
                                            style: BorderStyle.solid,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      width: 240,
                                      height: 240,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: const Color(0xFFEEEEE9),
                                          width: 4,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF1D6940).withValues(alpha: 0.05),
                                            blurRadius: 30,
                                            offset: const Offset(0, 10),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            width: 96,
                                            height: 96,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF3A8257).withValues(alpha: 0.1),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.photo_camera,
                                              size: 48,
                                              color: Color(0xFF1D6940),
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          const Text(
                                            'Buka Kamera',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF1D6940),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Decorative sync icon accent on top
                                    Positioned(
                                      top: 0,
                                      child: Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: const Color(0xFF1D6940).withValues(alpha: 0.2),
                                            width: 1,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.sync,
                                          size: 14,
                                          color: Color(0xFF1D6940),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Gap(24),
                              const Text(
                                'Ketuk lensa di atas untuk mengambil foto atau pilih dari galeri untuk identifikasi material',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF404941),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 100),
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

  String _formatMaterial(String materialType) {
    switch (materialType) {
      case 'sachet_multilayer':
        return 'Sachet Multilayer';
      case 'botol_pet':
        return 'Botol PET';
      case 'kertas':
        return 'Kertas';
      case 'kain':
        return 'Kain';
      default:
        return 'Lainnya';
    }
  }
}

class ScanningOverlayWidget extends StatefulWidget {
  final File imageFile;
  const ScanningOverlayWidget({super.key, required this.imageFile});

  @override
  State<ScanningOverlayWidget> createState() => _ScanningOverlayWidgetState();
}

class _ScanningOverlayWidgetState extends State<ScanningOverlayWidget> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Stack(
          children: [
            Positioned.fill(
              child: Image.file(
                widget.imageFile,
                fit: BoxFit.cover,
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.25),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: _animationController.value * 220, // Height is 220
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF8CD7A4),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8CD7A4).withValues(alpha: 0.8),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
