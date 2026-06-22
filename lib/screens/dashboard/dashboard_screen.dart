import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sirkulara/widgets/appbar.dart';

import '../../models/user_model.dart';
import '../../models/product_model.dart';
import '../../services/auth_service.dart';
import '../../services/product_service.dart';
import '../../services/scanner_service.dart';
import '../../services/workspace_service.dart';
import '../../widgets/impact_summary_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? _loadedUserId;
  late ScrollController _scrollController;
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      if (_scrollController.offset > 20 && !_isScrolled) {
        setState(() {
          _isScrolled = true;
        });
      } else if (_scrollController.offset <= 20 && _isScrolled) {
        setState(() {
          _isScrolled = false;
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = Provider.of<AuthService>(context).currentUser;
    if (user != null && _loadedUserId != user.uid) {
      _loadedUserId = user.uid;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<ScannerService>().fetchScanHistory(user.uid);
        context.read<ProductService>().fetchMyProducts(user.uid);
        context.read<ProductService>().fetchProducts();
        context.read<WorkspaceService>().fetchActiveWorkspace(user.uid);
        context.read<WorkspaceService>().fetchAllWorkspaces(user.uid);
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _goToTab(int index) {
    Navigator.pushReplacementNamed(context, '/home', arguments: index);
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer4<
      AuthService,
      ScannerService,
      WorkspaceService,
      ProductService
    >(
      builder: (context, auth, scanner, workspace, products, _) {
        final UserModel? user = auth.currentUser;
        final photoUrl = FirebaseAuth.instance.currentUser?.photoURL;

        return Scaffold(
          backgroundColor: const Color(0xFFFAFAF4),
          extendBodyBehindAppBar: true,
          appBar: CustomAppBar(
            title: user?.displayName ?? 'Sirkulara User',
            subtitle: _getGreeting(),
            isScrolled: _isScrolled,
            onNotificationPressed: () {},
          ),
          body: Stack(
            children: [
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
                      colors: [Color(0xFFCCEA9D), Color(0xFFFAFAF4)],
                    ),
                  ),
                ),
              ),
              SafeArea(
                bottom: false,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (workspace.activeWorkspaceId != null)
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF1D6940,
                                ).withOpacity(0.05), // Fixed withValues
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Active Workspace',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF404941),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          workspace.activeProductName ??
                                              'Upcycled Sachet Bag',
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
                              Builder(
                                builder: (context) {
                                  final totalSteps = workspace.steps.isNotEmpty
                                      ? workspace.steps.length
                                      : 1;
                                  final currentStep = workspace.steps.isNotEmpty
                                      ? workspace.currentStepIndex + 1
                                      : 1;
                                  final percentage = (currentStep / totalSteps);
                                  final percentageString =
                                      '${(percentage * 100).toInt()}%';

                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Step $currentStep of $totalSteps',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: Color(0xFF404941),
                                            ),
                                          ),
                                          Text(
                                            percentageString,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: Color(0xFF404941),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                        child: LinearProgressIndicator(
                                          value: percentage,
                                          backgroundColor: const Color(
                                            0xFFEEEEE9,
                                          ),
                                          valueColor:
                                              const AlwaysStoppedAnimation<
                                                Color
                                              >(Color(0xFF1D6940)),
                                          minHeight: 8,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/workspace-step',
                                    );
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
                                    'Continue Project',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF1D6940,
                                ).withOpacity(0.05), // Fixed withValues
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: const [
                                        Text(
                                          'Active Workspace',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF404941),
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'No Active Project',
                                          style: TextStyle(
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
                                      color: Color(0xFFEEEEE9),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.build_outlined,
                                      color: Color(0xFF404941),
                                      size: 24,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Mulai buat kerajinan daur ulang pertamamu sekarang dengan memindai sampah plastik Anda!',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF404941),
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: () => _goToTab(1),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1D6940),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: const Text(
                                    'Scan Sampah Baru',
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

                      ImpactSummaryCard(
                        user: user,
                        workspaces: workspace.allWorkspaces,
                        myProducts: products.myProducts,
                      ),
                      const Gap(24),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Marketplace',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1A1C19),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  '/marketplace',
                                ),
                                child: const Text(
                                  'Explore all',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF1D6940),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          Builder(
                            builder: (context) {
                              final List<ProductModel> displayList = List.from(
                                products.products,
                              );

                              if (displayList.isEmpty) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 32),
                                    child: Text(
                                      'Belum ada produk di marketplace',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                );
                              }

                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 16,
                                      mainAxisSpacing: 16,
                                      childAspectRatio: 0.55,
                                    ),
                                itemCount: displayList.length.clamp(0, 4),
                                itemBuilder: (context, index) {
                                  final product = displayList[index];
                                  return _buildMarketplaceCard(
                                    context,
                                    product,
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
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

  Widget _buildMarketplaceCard(BuildContext context, ProductModel product) {
    final priceFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    String savedText = '';
    if (product.materialType.toLowerCase().contains('sachet')) {
      final items = (product.weightGrams / 6.0).round().clamp(1, 999);
      savedText = '$items sachet diselamatkan';
    } else if (product.materialType.toLowerCase().contains('plastik') ||
        product.materialType.toLowerCase().contains('pet')) {
      final items = (product.weightGrams / 25.0).round().clamp(1, 999);
      savedText = '$items botol plastik diselamatkan';
    } else if (product.materialType.toLowerCase().contains('kertas') ||
        product.materialType.toLowerCase().contains('karton')) {
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
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05), // Fixed withValues
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: product.imageUrls.isNotEmpty
                        ? product.imageUrls[0]
                        : 'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?auto=format&fit=crop&w=900&q=60',
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF1D6940),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: const Color(0xFFEEEEE9),
                      child: const Icon(
                        Icons.image_not_supported,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  if (product.isVerified)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A5335),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFA8F3BF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.recycling, color: Color(0xFF1D6940), size: 14),
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
          Text(
            priceFormatter.format(product.price),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D6940),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'oleh ${product.creatorName.isNotEmpty ? product.creatorName : "Arta Kreatif"}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF404941)),
          ),
        ],
      ),
    );
  }
}
