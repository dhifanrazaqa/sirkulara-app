import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'widgets/weaving_camera_overlay.dart';

class WeavingImageAlignScreen extends StatefulWidget {
  final File imageFile;
  final String validationType;
  final int stepNumber;

  const WeavingImageAlignScreen({
    super.key,
    required this.imageFile,
    required this.validationType,
    required this.stepNumber,
  });

  @override
  State<WeavingImageAlignScreen> createState() => _WeavingImageAlignScreenState();
}

class _WeavingImageAlignScreenState extends State<WeavingImageAlignScreen> {
  final GlobalKey _boundaryKey = GlobalKey();
  bool _isProcessing = false;

  Future<void> _cropAndConfirm() async {
    if (_isProcessing) return;
    setState(() {
      _isProcessing = true;
    });

    try {
      final boundary = _boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw Exception("Gagal mendeteksi boundary gambar");
      
      // Capture the viewport area (only the InteractiveViewer, without drawing lines on the saved image)
      ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception("Gagal mengonversi gambar");
      
      final pngBytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final croppedFile = File('${tempDir.path}/aligned_${DateTime.now().millisecondsSinceEpoch}.png');
      await croppedFile.writeAsBytes(pngBytes);
      
      if (!mounted) return;
      Navigator.pop(context, croppedFile);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyejajarkan gambar: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Sejajarkan Foto Anda', style: TextStyle(color: Colors.white, fontSize: 16)),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Align container
          Positioned(
            top: 0,
            bottom: 100 + MediaQuery.of(context).padding.bottom, // leave space for custom bottom bar
            left: 0,
            right: 0,
            child: Stack(
              children: [
                Positioned.fill(
                  child: RepaintBoundary(
                    key: _boundaryKey,
                    child: Container(
                      color: Colors.black,
                      child: InteractiveViewer(
                        minScale: 0.1,
                        maxScale: 5.0,
                        child: Center(
                          child: Image.file(
                            widget.imageFile,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: WeavingCameraOverlay(
                    validationType: widget.validationType,
                    stepNumber: widget.stepNumber,
                  ),
                ),
              ],
            ),
          ),

          // Custom Bottom Bar positioned absolutely at the bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 80 + MediaQuery.of(context).padding.bottom,
              color: Colors.black,
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 16,
                bottom: MediaQuery.of(context).padding.bottom + 16,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Batal', style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                  ElevatedButton(
                    onPressed: _cropAndConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2ECC71),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Gunakan Foto', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),

          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
