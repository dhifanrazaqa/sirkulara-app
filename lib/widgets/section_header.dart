import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String actionText;
  final VoidCallback onActionTap;

  const SectionHeader({
    super.key,
    required this.title,
    required this.actionText,
    required this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1C19),
          ),
        ),
        GestureDetector(
          onTap: onActionTap,
          child: Text(
            actionText,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1D6940),
            ),
          ),
        ),
      ],
    );
  }
}