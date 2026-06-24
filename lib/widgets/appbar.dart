import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onNotificationPressed;
  final bool isScrolled;

  const CustomAppBar({
    super.key,
    required this.title,
    this.subtitle = 'Sirkulara',
    this.onNotificationPressed,
    this.isScrolled = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: isScrolled ? Colors.white : Colors.transparent,
      surfaceTintColor: isScrolled ? Colors.white : Colors.transparent,
      forceMaterialTransparency: !isScrolled,
      elevation: isScrolled ? 2 : 0,
      scrolledUnderElevation: isScrolled ? 2 : 0,
      shadowColor: Colors.black.withOpacity(0.1),
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF404941),
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
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
                color: Colors.white.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.notifications_none,
                  size: 20,
                  color: Color(0xFF1A1C19),
                ),
                onPressed: onNotificationPressed,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
