import 'package:flutter/material.dart';

import '../widgets/app_bottom_nav.dart';
import '../widgets/translated_text.dart';
import 'all_courses_screen.dart';
import 'chatbot_screen.dart';
import 'dashboard_screen.dart';
import 'quiz_screen.dart';
import 'wishlist_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    // Updated navigation: Quiz replaced Account in bottom tab
    _pages = [
      Dashboard(onSeeAllCourses: () => _setIndex(1)), // Home tab
      const AllCoursesScreen(),                       // My Topics tab
      const WishlistScreen(),                         // Wishlist tab
      QuizScreen(onNavigateHome: () => _setIndex(0)), // Quiz tab (was Account)
    ];
  }

  void _setIndex(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: AppBottomNavigationBar(
        currentIndex: _currentIndex,
        onItemSelected: _setIndex,
        onChatPressed: _openChatbot,
      ),
    );
  }

  void _openChatbot() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ChatbotScreen(),
      ),
    );
  }


}
