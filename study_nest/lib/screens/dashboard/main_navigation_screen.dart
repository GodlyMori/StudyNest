import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import 'home_screen.dart';
import '../quiz/topics_quizzes_screen.dart';
import '../groups/study_groups_screen.dart';
import '../profile/profile_screen.dart';
import '../owl_chat/owl_chat_screen.dart';
import '../../constants/app_assets.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomeScreen(onNavigateTab: _onTabSelected),
      const TopicsQuizzesScreen(),
      const StudyGroupsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      floatingActionButton: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const OwlChatScreen()),
          );
        },
        child: SizedBox(
          width: 60,
          height: 60,
          child: Image.asset(
            AppAssets.owlThinking,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const SizedBox(),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        height: 74,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, 'Home', Icons.home_filled),
            _buildNavItem(1, 'Quizzes', Icons.quiz_outlined),
            _buildNavItem(2, 'Groups', Icons.groups_outlined),
            _buildNavItem(3, 'Profile', Icons.person_outline),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, String label, IconData icon) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _onTabSelected(index),
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Active indicator bar from Figma
            Container(
              width: 20,
              height: 4,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 6),
            Icon(
              icon,
              size: 20,
              color: isSelected ? AppColors.textDark : AppColors.textSecondary,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.textDark : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
