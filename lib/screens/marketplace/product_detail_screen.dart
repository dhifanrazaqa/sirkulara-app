import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/impact_calculator.dart';
import '../../models/product_model.dart';
import '../../services/product_service.dart';

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key});

  Future<void> _buyProduct(BuildContext context, ProductModel product) async {
    final productService = context.read<ProductService>();
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(product.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const Gap(8),
              Text('Rp ${product.price}'),
              const Gap(16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Konfirmasi Pembelian'),
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed != true) return;
    await productService.buyProduct(product);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order berhasil dibuat')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final product = ModalRoute.of(context)!.settings.arguments as ProductModel;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (product.imageUrls.isNotEmpty)
                    CachedNetworkImage(imageUrl: product.imageUrls.first, fit: BoxFit.cover)
                  else
                    Container(color: AppColors.primaryLight, child: const Icon(Icons.image, size: 80)),
                  if (product.isVerified)
                    const Positioned(
                      left: 16,
                      bottom: 16,
                      child: Chip(label: Text('✓ EcoChoice')),
                    ),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                    const Gap(8),
                    Text('Rp ${product.price}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primaryDark)),
                    const Gap(8),
                    Row(
                      children: [
                        Text(product.creatorName, style: const TextStyle(color: AppColors.textSecondary)),
                        const Gap(8),
                        const Icon(Icons.star, size: 16, color: Colors.amber),
                        const Text('4.9'),
                      ],
                    ),
                    const Divider(height: 32),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Dampak Lingkungan Produk Ini', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                          const Gap(10),
                          Text('CO2 offset: ${ImpactCalculator.formatCo2(product.co2OffsetGrams)}'),
                          Text('Berat plastik: ${ImpactCalculator.formatWeight(product.weightGrams)}'),
                          Text('Material: ${product.materialType}'),
                        ],
                      ),
                    ),
                    const Gap(24),
                    const Text('Jejak Transparansi Produksi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    const Gap(6),
                    const Text('Dokumentasi nyata proses pembuatan produk ini', style: TextStyle(color: AppColors.textSecondary)),
                    const Gap(12),
                    SizedBox(
                      height: 140,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: product.transparencySteps.length,
                        separatorBuilder: (_, child) => const Gap(12),
                        itemBuilder: (context, index) {
                          final url = product.transparencySteps[index];
                          return InkWell(
                            onTap: () => showDialog(
                              context: context,
                              builder: (context) => Dialog(child: Image.network(url, fit: BoxFit.cover)),
                            ),
                            child: Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: SizedBox(
                                    width: 120,
                                    height: 120,
                                    child: CachedNetworkImage(imageUrl: url, fit: BoxFit.cover),
                                  ),
                                ),
                                const Gap(6),
                                Text('Step ${index + 1}'),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const Gap(24),
                    const Text('Tentang Produk', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    const Gap(8),
                    Text(product.description),
                    const Gap(96),
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: () => _buyProduct(context, product),
          child: const Text('Beli Sekarang'),
        ),
      ),
    );
  }
}
