import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../services/product_service.dart';
import '../../services/storage_service.dart';
import '../../services/workspace_service.dart';

class SellProductScreen extends StatefulWidget {
  const SellProductScreen({super.key});

  @override
  State<SellProductScreen> createState() => _SellProductScreenState();
}

class _SellProductScreenState extends State<SellProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  
  String? _selectedCategory;
  File? _selectedImageFile;
  bool _isUploading = false;
  
  final List<String> _categories = ['Fashion', 'Home Decor', 'Aksesoris', 'Lainnya'];
  final StorageService _storageService = StorageService();

  @override
  void initState() {
    super.initState();
    // Pre-fill fields from active workspace
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final workspace = context.read<WorkspaceService>();
      if (workspace.activeProductName != null) {
        _titleController.text = workspace.activeProductName!;
      }
      final material = workspace.activeMaterialType ?? 'lainnya';
      _descriptionController.text =
          'Produk upcycling hasil workspace terverifikasi dari material $material.';
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedImageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil foto: $e')),
      );
    }
  }

  Future<void> _publishProduct(bool asDraft) async {
    final workspace = context.read<WorkspaceService>();
    final productService = context.read<ProductService>();

    final productId = workspace.createdProductId;
    if (productId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID Produk tidak ditemukan. Silakan selesaikan proyek terlebih dahulu.')),
      );
      return;
    }

    if (asDraft) {
      workspace.resetWorkspace();
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produk berhasil disimpan ke draft.')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih kategori produk.')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      List<String> imageUrls = [];
      
      final lastStepWithImage = workspace.steps.lastWhere(
        (step) => step.evidenceImageUrl != null && step.evidenceImageUrl!.isNotEmpty,
        orElse: () => workspace.steps.last,
      );
      if (lastStepWithImage.evidenceImageUrl != null) {
        imageUrls.add(lastStepWithImage.evidenceImageUrl!);
      }

      if (_selectedImageFile != null) {
        final uploadedUrl = await _storageService.uploadImage(
          _selectedImageFile!,
          'products/$productId/${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        imageUrls.insert(0, uploadedUrl);
      }

      final price = int.tryParse(_priceController.text) ?? 0;

      await productService.publishProductDetailed(
        productId: productId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        price: price,
        category: _selectedCategory!,
        imageUrls: imageUrls,
      );

      workspace.resetWorkspace();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Produk berhasil diterbitkan ke Marketplace!'),
          backgroundColor: Color(0xFF1D6940),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mempublikasikan produk: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final workspace = context.watch<WorkspaceService>();
    
    // Find default image URL from workspace steps
    String? defaultImageUrl;
    if (workspace.steps.isNotEmpty) {
      final lastStepWithImage = workspace.steps.lastWhere(
        (step) => step.evidenceImageUrl != null && step.evidenceImageUrl!.isNotEmpty,
        orElse: () => workspace.steps.last,
      );
      defaultImageUrl = lastStepWithImage.evidenceImageUrl;
    }

    final co2Kg = ((workspace.completedCo2Grams ?? 0) / 1000.0).toStringAsFixed(1);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF4),
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 320,
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
            child: Column(
              children: [
                // Custom App Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1C19)),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        'Kembali',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1C19),
                        ),
                      ),
                    ],
                  ),
                ),
                // Main Content Form
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Text
                          const Text(
                            'Jual Produk',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1C19),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Lengkapi detail produk upcycled Anda',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF404941),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Image Upload Area
                          GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              height: 240,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: const Color(0xFFBFC9BF),
                                  width: 2,
                                  style: BorderStyle.solid,
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  // Display selected or default image
                                  if (_selectedImageFile != null)
                                    Image.file(
                                      _selectedImageFile!,
                                      fit: BoxFit.cover,
                                    )
                                  else if (defaultImageUrl != null && defaultImageUrl.isNotEmpty)
                                    CachedNetworkImage(
                                      imageUrl: defaultImageUrl,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => const Center(
                                        child: CircularProgressIndicator(color: Color(0xFF1D6940)),
                                      ),
                                      errorWidget: (context, url, error) => const Center(
                                        child: Icon(Icons.image, size: 48, color: Colors.grey),
                                      ),
                                    )
                                  else
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 64,
                                          height: 64,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFEEEEE9),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.add_a_photo_outlined,
                                            color: Color(0xFF1D6940),
                                            size: 28,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        const Text(
                                          'Tambah Foto Produk',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1A1C19),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          'Tunjukkan keunikan barang upcycled Anda',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF707A71),
                                          ),
                                        ),
                                      ],
                                    ),
                                  
                                  // Edit overlay badge
                                  if (_selectedImageFile != null || (defaultImageUrl != null && defaultImageUrl.isNotEmpty))
                                    Positioned(
                                      bottom: 16,
                                      right: 16,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.6),
                                          borderRadius: BorderRadius.circular(99),
                                        ),
                                        child: Row(
                                          children: const [
                                            Icon(Icons.edit, color: Colors.white, size: 14),
                                            SizedBox(width: 6),
                                            Text(
                                              'Ubah Foto',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Nama Produk
                          const Text(
                            'Nama Produk',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF404941),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFBFC9BF)),
                            ),
                            child: TextFormField(
                              controller: _titleController,
                              style: const TextStyle(fontSize: 16, color: Color(0xFF1A1C19)),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Contoh: Totebag Kain Perca Premium',
                                hintStyle: TextStyle(color: Color(0xFF909A91)),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Nama produk tidak boleh kosong';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Deskripsi Produk
                          const Text(
                            'Deskripsi Produk',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF404941),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFBFC9BF)),
                            ),
                            child: TextFormField(
                              controller: _descriptionController,
                              maxLines: 4,
                              style: const TextStyle(fontSize: 16, color: Color(0xFF1A1C19)),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Ceritakan bahan upcycled yang digunakan...',
                                hintStyle: TextStyle(color: Color(0xFF909A91)),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Deskripsi produk tidak boleh kosong';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Harga & Kategori
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Harga
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Harga',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF404941),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: const Color(0xFFBFC9BF)),
                                      ),
                                      child: Row(
                                        children: [
                                          const Text(
                                            'Rp ',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1A1C19),
                                            ),
                                          ),
                                          Expanded(
                                            child: TextFormField(
                                              controller: _priceController,
                                              keyboardType: TextInputType.number,
                                              style: const TextStyle(fontSize: 16, color: Color(0xFF1A1C19)),
                                              decoration: const InputDecoration(
                                                border: InputBorder.none,
                                                hintText: '0',
                                                hintStyle: TextStyle(color: Color(0xFF909A91)),
                                              ),
                                              validator: (value) {
                                                if (value == null || value.trim().isEmpty) {
                                                  return 'Harga tidak boleh kosong';
                                                }
                                                if (int.tryParse(value) == null || int.parse(value) <= 0) {
                                                  return 'Harga tidak valid';
                                                }
                                                return null;
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Kategori
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Kategori',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF404941),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: const Color(0xFFBFC9BF)),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButtonFormField<String>(
                                          isExpanded: true,
                                          initialValue: _selectedCategory,
                                          hint: const Text(
                                            'Pilih Kategori',
                                            style: TextStyle(color: Color(0xFF909A91), fontSize: 13),
                                          ),
                                          decoration: const InputDecoration(
                                            border: InputBorder.none,
                                            contentPadding: EdgeInsets.zero,
                                          ),
                                          icon: const Icon(Icons.expand_more, color: Color(0xFF404941)),
                                          items: _categories.map((cat) {
                                            return DropdownMenuItem<String>(
                                              value: cat,
                                              child: Text(cat),
                                            );
                                          }).toList(),
                                          onChanged: (val) {
                                            setState(() {
                                              _selectedCategory = val;
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Impact Badge
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFCCEA9D).withValues(alpha: 0.5)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.eco,
                                    color: Color(0xFF1D6940),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Dampak Lingkungan',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1D6940),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Produk ini menghemat sekitar ${co2Kg}kg CO2',
                                        style: const TextStyle(
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
                          const SizedBox(height: 32),

                          // Action Buttons
                          if (_isUploading)
                            const Center(
                              child: CircularProgressIndicator(color: Color(0xFF1D6940)),
                            )
                          else
                            Column(
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: () => _publishProduct(false),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1D6940),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(99),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: const [
                                        Text(
                                          'Tampilkan Produk',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Icon(Icons.rocket_launch, size: 18),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: OutlinedButton(
                                    onPressed: () => _publishProduct(true),
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: const Color(0xFF1A1C19),
                                      side: const BorderSide(color: Color(0xFFBFC9BF)),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(99),
                                      ),
                                    ),
                                    child: const Text(
                                      'Simpan ke Draft',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
