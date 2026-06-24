import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/product_model.dart';
import '../../services/product_service.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final _currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductService>().fetchProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.2,
            colors: [
              Color(0xFFCFEDA0),
              Color(0xFFFAFAF4),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Custom Header App Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
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
                        SizedBox(height: 2),
                        Text(
                          'Marketplace',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1C19),
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => Navigator.maybePop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.8),
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.close, color: Color(0xFF1A1C19), size: 20),
                      ),
                    ),
                  ],
                ),
              ),

              // Search & Filter Toggle Row
              Consumer<ProductService>(
                builder: (context, products, _) {
                  return Column(
                    children: [
                      // Category Filter Chips
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: [
                              _buildCategoryChip(products, null, 'Semua'),
                              const SizedBox(width: 8),
                              _buildCategoryChip(products, 'aksesori', 'Aksesori'),
                              const SizedBox(width: 8),
                              _buildCategoryChip(products, 'dekorasi', 'Dekorasi'),
                              const SizedBox(width: 8),
                              _buildCategoryChip(products, 'furnitur', 'Furnitur'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // EcoChoice Filter Switch
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.verified, color: Color(0xFF1D6940), size: 20),
                                SizedBox(width: 6),
                                Text(
                                  'Hanya Produk Terverifikasi (EcoChoice)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1A1C19),
                                  ),
                                ),
                              ],
                            ),
                            Transform.scale(
                              scale: 0.8,
                              child: Switch(
                                activeColor: const Color(0xFF1D6940),
                                value: products.filterVerifiedOnly,
                                onChanged: (value) => products.applyFilter(
                                  category: products.filterCategory,
                                  material: products.filterMaterial,
                                  verifiedOnly: value,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),

              // Product Grid
              Expanded(
                child: Consumer<ProductService>(
                  builder: (context, products, _) {
                    if (products.isLoading) {
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1D6940)),
                        ),
                      );
                    }

                    if (products.products.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            const Text(
                              'Belum ada produk di marketplace',
                              style: TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                          ],
                        ),
                      );
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      physics: const BouncingScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.55,
                      ),
                      itemCount: products.products.length,
                      itemBuilder: (context, index) {
                        final product = products.products[index];
                        return _buildProductCard(context, product);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(ProductService service, String? value, String label) {
    final isSelected = service.filterCategory == value;
    return GestureDetector(
      onTap: () => service.applyFilter(
        category: value,
        material: service.filterMaterial,
        verifiedOnly: service.filterVerifiedOnly,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1D6940) : Colors.white,
          borderRadius: BorderRadius.circular(99),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  )
                ]
              : const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  )
                ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF404941),
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, ProductModel product) {
    // Determine the label for items saved based on material type
    String savedText = '';
    if (product.materialType.toLowerCase().contains('sachet')) {
      final items = (product.weightGrams / 6.0).round().clamp(1, 999);
      savedText = '$items sachet diselamatkan';
    } else if (product.materialType.toLowerCase().contains('plastik') || product.materialType.toLowerCase().contains('pet')) {
      final items = (product.weightGrams / 25.0).round().clamp(1, 999);
      savedText = '$items botol plastik diselamatkan';
    } else if (product.materialType.toLowerCase().contains('kertas') || product.materialType.toLowerCase().contains('karton')) {
      final items = (product.weightGrams / 15.0).round().clamp(1, 999);
      savedText = '$items kantong kertas diselamatkan';
    } else {
      savedText = '${product.weightGrams.toInt()}g bahan diselamatkan';
    }

    return GestureDetector(
      onTap: () {
        context.read<ProductService>().selectProduct(product);
        Navigator.pushNamed(context, '/product-detail', arguments: product);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image with rounded corners and EcoChoice badge
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (product.imageUrls.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: product.imageUrls.first,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1D6940)),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: const Color(0xFFF4F4EE),
                        child: const Icon(Icons.image, color: Colors.grey),
                      ),
                    )
                  else
                    Container(
                      color: const Color(0xFFF4F4EE),
                      child: const Icon(Icons.image, color: Colors.grey),
                    ),
                  if (product.isVerified)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A5335), // Dark green background
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 14,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'EcoChoice',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
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
          const SizedBox(height: 12),
          // Title
          Text(
            product.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1C19),
            ),
          ),
          const SizedBox(height: 6),
          // Saved Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFA8F3BF), // Light green background
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.recycling,
                  color: Color(0xFF1D6940),
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  savedText,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1D6940),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Price
          Text(
            _currencyFormatter.format(product.price),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D6940),
            ),
          ),
          const SizedBox(height: 2),
          // Creator Name
          Text(
            'oleh ${product.creatorName.isNotEmpty ? product.creatorName : "Arta Kreatif"}',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF404941),
            ),
          ),
        ],
      ),
    );
  }
}
