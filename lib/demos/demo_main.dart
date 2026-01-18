import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'screens/scroll_scaling_demo.dart';
import 'screens/smooth_scrolling_demo.dart';
import 'screens/animated_transitions_demo.dart';
import 'screens/floating_search_demo.dart';
import 'screens/modal_sheet_demo.dart';
import 'screens/page_transitions_demo.dart';

void main() {
  runApp(DemoApp());
}

class DemoApp extends StatelessWidget {
  DemoApp({super.key});

  final GoRouter _router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const DemoHomePage(),
      ),
      GoRoute(
        path: '/scroll-scaling',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const ScrollScalingDemo(),
          transitionDuration: const Duration(milliseconds: 800),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOutCubic,
              )),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: '/smooth-scrolling',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const SmoothScrollingDemo(),
          transitionDuration: const Duration(milliseconds: 600),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return ScaleTransition(
              scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
              ),
              child: FadeTransition(opacity: animation, child: child),
            );
          },
        ),
      ),
      GoRoute(
        path: '/animated-transitions',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const AnimatedTransitionsDemo(),
          transitionDuration: const Duration(milliseconds: 900),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return RotationTransition(
              turns: Tween<double>(begin: 0.1, end: 0.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.elasticOut),
              ),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 1.0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
        ),
      ),
      GoRoute(
        path: '/floating-search',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const FloatingSearchDemo(),
          transitionDuration: const Duration(milliseconds: 700),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: Transform.scale(
                scale: 0.8 + (0.2 * animation.value),
                child: child,
              ),
            );
          },
        ),
      ),
      GoRoute(
        path: '/modal-sheet',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const ModalSheetDemo(),
          transitionDuration: const Duration(milliseconds: 500),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, -1.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              )),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: '/page-transitions',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const PageTransitionsDemo(),
          transitionDuration: const Duration(milliseconds: 1000),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.ease;

            var tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );

            return SlideTransition(
              position: animation.drive(tween),
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Flutter Animation Demos',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}

class DemoHomePage extends StatelessWidget {
  const DemoHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final demoItems = [
      DemoItem(
        title: 'Scroll-based Card Scaling',
        subtitle: 'NotificationListener + Transform.scale',
        icon: Icons.zoom_in,
        route: '/scroll-scaling',
        color: Colors.blue,
      ),
      DemoItem(
        title: 'Smooth List Scrolling',
        subtitle: 'CustomScrollView + SliverList',
        icon: Icons.view_list,
        route: '/smooth-scrolling',
        color: Colors.green,
      ),
      DemoItem(
        title: 'Animated Card Transitions',
        subtitle: 'Hero widget animations',
        icon: Icons.animation,
        route: '/animated-transitions',
        color: Colors.purple,
      ),
      DemoItem(
        title: 'Floating Search Bar',
        subtitle: 'AnimatedPositioned + SliverAppBar',
        icon: Icons.search,
        route: '/floating-search',
        color: Colors.orange,
      ),
      DemoItem(
        title: 'Modal Bottom Sheet',
        subtitle: 'showModalBottomSheet with blur',
        icon: Icons.layers,
        route: '/modal-sheet',
        color: Colors.red,
      ),
      DemoItem(
        title: 'Page Transitions',
        subtitle: 'PageRouteBuilder + go_router',
        icon: Icons.swap_horiz,
        route: '/page-transitions',
        color: Colors.teal,
      ),
    ];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'Flutter Animation Demos',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: demoItems.length,
                  itemBuilder: (context, index) {
                    final item = demoItems[index];
                    return TweenAnimationBuilder<double>(
                      duration: Duration(milliseconds: 600 + (index * 100)),
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(0, 50 * (1 - value)),
                          child: Opacity(
                            opacity: value,
                            child: child,
                          ),
                        );
                      },
                      child: Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => context.go(item.route),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: LinearGradient(
                                colors: [
                                  item.color.withOpacity(0.1),
                                  item.color.withOpacity(0.05),
                                ],
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: item.color,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    item.icon,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item.subtitle,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.grey[400],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DemoItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
  final Color color;

  DemoItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
    required this.color,
  });
}