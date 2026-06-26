import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/marketplace/product_detail_screen.dart';
import 'screens/marketplace/marketplace_screen.dart';
import 'screens/profile/recent_scans_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/scanner/scan_result_screen.dart';
import 'screens/workspace/sell_product_screen.dart';
import 'screens/workspace/workspace_complete_screen.dart';
import 'screens/workspace/workspace_step_screen.dart';
import 'screens/workspace/workspace_list_screen.dart';
import 'screens/workspace/project_overview_screen.dart';
import 'services/auth_service.dart';
import 'services/product_service.dart';
import 'services/scanner_service.dart';
import 'services/workspace_service.dart';
import 'services/weaving_validation_service.dart';
import 'services/visual_validation_service.dart';

import 'services/catalog_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await CatalogService().loadCatalog();
  runApp(const SirkularaApp());
}

class SirkularaApp extends StatelessWidget {
  const SirkularaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => ScannerService()),
        ChangeNotifierProvider(create: (_) => WorkspaceService()),
        ChangeNotifierProvider(create: (_) => ProductService()),
        ChangeNotifierProvider(create: (_) => WeavingValidationService()),
        ChangeNotifierProvider(create: (_) => VisualValidationService()),
      ],
      child: MaterialApp(
        title: 'Sirkulara',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: '/splash',
        routes: {
          '/splash': (_) => const SplashScreen(),
          '/login': (_) => const LoginScreen(),
          '/register': (_) => const RegisterScreen(),
          '/home': (context) {
            final index = ModalRoute.of(context)?.settings.arguments;
            return HomeScreen(initialIndex: index is int ? index : 0);
          },
          '/scan-result': (_) => const ScanResultScreen(),
          '/workspace-step': (_) => const WorkspaceStepScreen(),
          '/workspace-complete': (_) => const WorkspaceCompleteScreen(),
          '/product-detail': (_) => const ProductDetailScreen(),
          '/profile': (_) => const ProfileScreen(),
          '/marketplace': (_) => const MarketplaceScreen(),
          '/workspace-list': (_) => const WorkspaceListScreen(),
          '/project-overview': (_) => const ProjectOverviewScreen(),
          '/recent-scans': (_) => const RecentScansScreen(),
          '/sell-product': (_) => const SellProductScreen(),
        },
      ),
    );
  }
}
