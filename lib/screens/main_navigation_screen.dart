import 'package:flutter/material.dart';

import '../widgets/app_bottom_nav.dart';
import '../widgets/translated_text.dart';
import 'all_courses_screen.dart';
import 'chatbot_screen.dart';
import 'dashboard_screen.dart';
import 'features_screen.dart';
import 'contact_us_screen.dart';
import 'account_screen.dart';
import 'wishlist_screen.dart';

/// Wrapper widget that listens to tab change notifications
class AllCoursesScreenWrapper extends StatefulWidget {
  const AllCoursesScreenWrapper({
    super.key,
    required this.tabNotifier,
    required this.categoryFilterNotifier,
  });

  final ValueNotifier<int> tabNotifier;
  final ValueNotifier<String?> categoryFilterNotifier;

  @override
  State<AllCoursesScreenWrapper> createState() => _AllCoursesScreenWrapperState();
}

class _AllCoursesScreenWrapperState extends State<AllCoursesScreenWrapper> {
  final AllCoursesController _coursesController = AllCoursesController();

  @override
  void initState() {
    super.initState();
    widget.tabNotifier.addListener(_onTabChangeRequested);
    widget.categoryFilterNotifier.addListener(_onFilterChangeRequested);
  }

  @override
  void dispose() {
    widget.tabNotifier.removeListener(_onTabChangeRequested);
    widget.categoryFilterNotifier.removeListener(_onFilterChangeRequested);
    super.dispose();
  }

  void _onTabChangeRequested() {
    final targetTab = widget.tabNotifier.value;
    // Small delay to ensure the widget is fully built
    Future.delayed(const Duration(milliseconds: 50), () {
      _coursesController.switchToTab(targetTab);
    });
  }

  void _onFilterChangeRequested() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AllCoursesScreen(
      controller: _coursesController,
      initialCategoryName: widget.categoryFilterNotifier.value,
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  late final List<Widget> _pages;
  final ValueNotifier<int> _coursesTabNotifier = ValueNotifier<int>(0);
  final ValueNotifier<String?> _categoryFilterNotifier = ValueNotifier<String?>(null);

  @override
  void initState() {
    super.initState();
    // Navigation: Home, My Topics, Features, Contact Us
    _pages = [
      Dashboard(
        onSeeAllCourses: (category) => _navigateToCourses(category), 
        onSeeAllPaidCourses: () => _navigateToPaidTab(),
      ), // Home tab (index 0)
      AllCoursesScreenWrapper(
        tabNotifier: _coursesTabNotifier,
        categoryFilterNotifier: _categoryFilterNotifier,
      ),  // My Topics tab (index 1)
      const FeaturesScreen(),                                      // Features tab (index 2)
      const ContactUsScreen(),                                     // Contact Us tab (index 3)
    ];
  }

  @override
  void dispose() {
    _coursesTabNotifier.dispose();
    _categoryFilterNotifier.dispose();
    super.dispose();
  }

  void _setIndex(int index) {
    if (index == 1 && _currentIndex != 1 && _categoryFilterNotifier.value != null) {
      _categoryFilterNotifier.value = null;
    }
    setState(() => _currentIndex = index);
  }

  void _navigateToPaidTab() {
    _categoryFilterNotifier.value = null;
    _coursesTabNotifier.value = 1; // Set to paid tab (index 1)
    setState(() => _currentIndex = 1);
  }

  void _navigateToCourses(String? category) {
    _categoryFilterNotifier.value = category;
    setState(() => _currentIndex = 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: AppBottomNavigationBar(
        currentIndex: _currentIndex,
        onItemSelected: _setIndex,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openChatbot,
        backgroundColor: Colors.white,
        elevation: 4,
        shape: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset(
            'Asset/chatbot.png',
            fit: BoxFit.contain,
          ),
        ),
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
