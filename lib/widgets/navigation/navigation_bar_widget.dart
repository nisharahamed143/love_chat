import 'package:flutter/material.dart';

class NavigationBarWidget extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const NavigationBarWidget({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 50),
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.cyan.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            icon: Icons.chat_bubble_rounded,
            label: 'Chats',
            index: 0,
          ),
          _buildNavItem(
            icon: Icons.call_rounded,
            label: 'Calls',
            index: 1,
          ),
          _buildNavItem(
            icon: Icons.video_collection_rounded,
            label: 'Reels',
            index: 2,
          ),
          _buildNavItem(
            icon: Icons.person_rounded,
            label: 'Profile',
            index: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = currentIndex == index;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
        decoration: BoxDecoration(
          color: isSelected
              ? Color(0xFF00B4DB).withOpacity(0.35)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        // ✅ শুধুমাত্র Column ব্যবহার করা হয়েছে
        child: Column(
          mainAxisSize: MainAxisSize.min, // ওভারফ্লো বন্ধ রাখার জন্য প্রয়োজনীয়
          children: [
            Icon(
              icon,
              color: isSelected ? Color(0xFF0083B0) : Colors.grey.shade600,
              size: 25,
            ),
            const SizedBox(height: 4), // আইকন ও টেক্সটের মধ্যকার দূরত্ব
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Color(0xFF0083B0) : Colors.grey.shade600,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}