import 'package:flutter/material.dart';

import '../dashboard/dashboard_screen.dart';
import '../scanner/scanner_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final int initialIndex;

  const HomeScreen({super.key, this.initialIndex = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _currentIndex;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    // Clamp the initial index to be within 0 and 2
    _currentIndex = widget.initialIndex.clamp(0, 2);
    _screens = const [
      DashboardScreen(),
      ScannerScreen(),
      ProfileScreen(),
    ];
  }

  void _setIndex(int index) {
    setState(() => _currentIndex = index.clamp(0, 2));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF4),
      body: Stack(
        children: [
          // Content Area
          Positioned.fill(
            child: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
          ),
          
          // Custom Bottom Navigation Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 104, // Height to fit the overlapping prominent Scan FAB
              color: Colors.transparent,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Bottom bar background container
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 20,
                            offset: const Offset(0, -4),
                          ),
                        ],
                        border: const Border(
                          top: BorderSide(
                            color: Color(0xFFBFC9BF), // outline-variant color
                            width: 0.5,
                          ),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Tab 0: Dashboard
                          _buildNavItem(
                            index: 0,
                            activeIcon: Icons.dashboard,
                            inactiveIcon: Icons.dashboard_outlined,
                            label: 'Dashboard',
                          ),
                          
                          // Spacing for centered Scan button
                          const SizedBox(width: 64),
                          
                          // Tab 2: Profile
                          _buildNavItem(
                            index: 2,
                            activeIcon: Icons.account_circle,
                            inactiveIcon: Icons.account_circle_outlined,
                            label: 'Profile',
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Prominent centered floating Scan button
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: () => _setIndex(1),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1D6940), // primary color (#1d6940)
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF1D6940).withValues(alpha: 0.2),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.photo_camera,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Scan',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: _currentIndex == 1 ? FontWeight.w600 : FontWeight.w500,
                                color: _currentIndex == 1 ? const Color(0xFF1D6940) : const Color(0xFF404941),
                              ),
                            ),
                          ],
                        ),
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
  }

  Widget _buildNavItem({
    required int index,
    required IconData activeIcon,
    required IconData inactiveIcon,
    required String label,
  }) {
    final isActive = _currentIndex == index;
    
    return InkWell(
      onTap: () => _setIndex(index),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 32,
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFFCCEA9D) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                isActive ? activeIcon : inactiveIcon,
                color: isActive ? const Color(0xFF516A2C) : const Color(0xFF404941),
                size: 20,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? const Color(0xFF516A2C) : const Color(0xFF404941),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
