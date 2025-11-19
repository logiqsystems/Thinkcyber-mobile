import 'package:flutter/material.dart';
import '../widgets/translated_text.dart';

class AppBottomNavigationBar extends StatelessWidget {
  const AppBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onItemSelected,
    this.onChatPressed,
  });

  final int currentIndex;
  final ValueChanged<int> onItemSelected;
  final VoidCallback? onChatPressed;

  static const _items = [
    _NavItemData(icon: Icons.home_rounded, label: 'Home'),
    _NavItemData(icon: Icons.grid_view_rounded, label: 'My Topics'),
    _NavItemData(icon: Icons.smart_toy_rounded, label: 'Chat', isCenter: true),
    _NavItemData(icon: Icons.favorite_border_rounded, label: 'Wishlist'),
    _NavItemData(icon: Icons.quiz_outlined, label: 'Quiz'),
  ];

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var index = 0; index < _items.length; index++)
                    _items[index].isCenter
                        ? _CenterChatButton(onTap: onChatPressed ?? () {})
                        : _NavButton(
                            data: _items[index],
                            isActive: currentIndex == _getAdjustedIndex(index),
                            onTap: () => onItemSelected(_getAdjustedIndex(index)),
                          ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Adjust index to skip the center chat button
  int _getAdjustedIndex(int index) {
    return index > 2 ? index - 1 : index;
  }
}

class _CenterChatButton extends StatelessWidget {
  const _CenterChatButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Transform.translate(
        offset: const Offset(0, -25), // Move the entire button up significantly
        child: Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 10),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF2E7DFF),
                  Color(0xFF1E40AF),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.data,
    required this.isActive,
    required this.onTap,
  });

  final _NavItemData data;
  final bool isActive;
  final VoidCallback onTap;

  static const _activeColor = Color(0xFFFF5757);
  static const _mutedColor = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isActive)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color:  Color(0xFF2E7DFF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(data.icon, color: Colors.white, size: 22),
            )
          else
            Icon(
              data.icon,
              color: _mutedColor.withValues(alpha: 0.6),
              size: 24,
            ),
          const SizedBox(height: 6),
          TranslatedText(
            data.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              color: isActive
                  ? Colors.blue
                  : _mutedColor.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItemData {
  const _NavItemData({
    required this.icon, 
    required this.label, 
    this.isCenter = false,
  });

  final IconData icon;
  final String label;
  final bool isCenter;
}
