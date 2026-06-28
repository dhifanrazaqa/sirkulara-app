import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/auth_service.dart';
import '../../services/product_service.dart';
import '../../services/scanner_service.dart';
import '../../services/workspace_service.dart';
import '../../widgets/impact_summary_card.dart';
import '../../models/user_model.dart';
import '../../widgets/appbar.dart';
import 'widgets/profile_header_info.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/scan_card.dart';
import '../../widgets/product_card.dart';
import '../../widgets/active_workspace_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
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
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    if (user != null && _loadedUserId != user.uid) {
      _loadedUserId = user.uid;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<ScannerService>().fetchScanHistory(user.uid);
        context.read<ProductService>().fetchMyProducts(user.uid);
        context.read<WorkspaceService>().fetchActiveWorkspace(user.uid);
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer4<
      AuthService,
      ScannerService,
      ProductService,
      WorkspaceService
    >(
      builder: (context, auth, scanner, products, workspace, _) {
        final UserModel? user = auth.currentUser;
        final photoUrl = FirebaseAuth.instance.currentUser?.photoURL;
        final displayName = user?.displayName ?? 'User';

        final scanCount = scanner.scanHistory.length;
        final rawPlastic = user?.totalPlasticDiverted ?? 0.0;
        final plasticWeightFormatted =
            '${(rawPlastic / 1000).toStringAsFixed(0)}kg';

        final double rawPoints = rawPlastic > 0 ? (rawPlastic / 1000 * 235) : 0;
        final pointsFormatted = rawPoints >= 1000
            ? '${(rawPoints / 1000).toStringAsFixed(1)}k'
            : rawPoints.toStringAsFixed(0);

        final level = rawPlastic > 0
            ? (rawPlastic / 2000).clamp(1.0, 99.0).toInt() + 1
            : 1;

        return Scaffold(
          backgroundColor: const Color(0xFFFAFAF4),
          extendBodyBehindAppBar: true,
          appBar: CustomAppBar(title: "Profile", isScrolled: _isScrolled),
          body: Stack(
            children: [
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
                      colors: [Color(0xFFCCEA9D), Color(0xFFFAFAF4)],
                    ),
                  ),
                ),
              ),
              SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 32,
                ),
                child: Column(
                  children: [
                    const Gap(48),
                    ProfileHeaderInfo(
                      displayName: displayName,
                      photoUrl: photoUrl,
                      level: level,
                    ),
                    const Gap(24),
                    Row(
                      children: [
                        Expanded(
                          child: StatCard(title: 'Scans', value: '$scanCount'),
                        ),
                        const Gap(16),
                        Expanded(
                          child: StatCard(
                            title: 'Points',
                            value: pointsFormatted,
                          ),
                        ),
                        const Gap(16),
                        Expanded(
                          child: StatCard(
                            title: 'Impact',
                            value: plasticWeightFormatted,
                          ),
                        ),
                      ],
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
                        SectionHeader(
                          title: 'Recent Scans',
                          actionText: 'See all',
                          onActionTap: () =>
                              Navigator.pushNamed(context, '/recent-scans'),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 200,
                          child: scanner.scanHistory.isEmpty
                              ? const Center(
                                  child: Text('Belum ada riwayat scan.'),
                                )
                              : ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: scanner.scanHistory.length,
                                  itemBuilder: (context, index) {
                                    final scan = scanner.scanHistory[index];
                                    return Padding(
                                      padding: EdgeInsets.only(
                                        right:
                                            index ==
                                                scanner.scanHistory.length - 1
                                            ? 0
                                            : 16,
                                      ),
                                      child: ScanCard(
                                        imageUrl: scan.imageUrl,
                                        materialType: scan.materialType,
                                        scannedAt: scan.scannedAt.toDate(),
                                        onTap: () {
                                          scanner.selectScanResult(scan);
                                          Navigator.pushNamed(
                                            context,
                                            '/scan-result',
                                          );
                                        },
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                    const Gap(24),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionHeader(
                          title: 'Recent Workspace',
                          actionText: 'See all',
                          onActionTap: () =>
                              Navigator.pushNamed(context, '/workspace-list'),
                        ),
                        const SizedBox(height: 12),
                        workspace.activeWorkspaceId != null
                            ? ActiveWorkspaceCard(
                                productName:
                                    workspace.activeProductName ??
                                    'Proyek Tanpa Nama',
                                currentStep: workspace.steps.isNotEmpty
                                    ? workspace.currentStepIndex + 1
                                    : 0,
                                totalSteps: workspace.steps.isNotEmpty
                                    ? workspace.steps.length
                                    : 0,
                                onContinue: () => Navigator.pushNamed(
                                  context,
                                  '/workspace-step',
                                ),
                              )
                            : const Center(
                                child: Text('Tidak ada proyek aktif saat ini.'),
                              ),
                      ],
                    ),
                    const Gap(24),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionHeader(
                          title: 'Produk Marketplace Anda',
                          actionText: 'Lihat semua',
                          onActionTap: () =>
                              Navigator.pushNamed(context, '/marketplace'),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 240,
                          child: products.myProducts.isEmpty
                              ? const Center(child: Text('Belum ada produk.'))
                              : ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: products.myProducts.length,
                                  itemBuilder: (context, index) {
                                    final product = products.myProducts[index];
                                    return Padding(
                                      padding: EdgeInsets.only(
                                        right:
                                            index ==
                                                products.myProducts.length - 1
                                            ? 0
                                            : 16,
                                      ),
                                      child: ProductCard(
                                        title: product.title,
                                        price: product.price,
                                        imageUrls: product.imageUrls,
                                        onTap: () {
                                          products.selectProduct(product);
                                          Navigator.pushNamed(
                                            context,
                                            '/product-detail',
                                            arguments: product,
                                          );
                                        },
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
