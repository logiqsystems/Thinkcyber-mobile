import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/session_service.dart';
import 'login_screen.dart';
import 'main_navigation_screen.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _backgroundController;
  late final AnimationController _logoController;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;

  Widget? _destination;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);

    final logoCurve = CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeInOut,
    );
    _logoOpacity = Tween<double>(begin: 0.75, end: 1).animate(logoCurve);
    _logoScale = Tween<double>(begin: 0.94, end: 1.05).animate(logoCurve);

    _prepareNavigation();
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _logoController.dispose();
    super.dispose();
  }

  Future<void> _prepareNavigation() async {
    final isAuthenticated = await SessionService.isAuthenticated();
    final hasOnboarded = await SessionService.hasOnboarded();

    // If session expired, clear it automatically
    if (!isAuthenticated && await SessionService.isSessionValid() == false) {
      await SessionService.clearSession();
    }

    final Widget destination = isAuthenticated
        ? const MainNavigationScreen()
        : hasOnboarded
            ? const LoginScreen()
            : const OnboardingScreen();

    if (!mounted) return;

    setState(() => _destination = destination);

    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted || _navigated) return;
    _navigate(destination);
  }

  void _navigate(Widget destination) {
    if (_navigated || !mounted) {
      return;
    }
    _navigated = true;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 700),
        pageBuilder: (_, animation, __) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
          child: destination,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6366F1), // Indigo
              Color(0xFF4F46E5), // Indigo darker
              Color(0xFF2563EB), // Blue
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Animated background circles
            Positioned(
              top: -100,
              right: -100,
              child: AnimatedBuilder(
                animation: _backgroundController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _backgroundController.value * 2 * math.pi,
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              bottom: -80,
              left: -80,
              child: AnimatedBuilder(
                animation: _backgroundController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: -_backgroundController.value * 2 * math.pi,
                    child: Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.03),
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                },
              ),
            ),
            // Main content
            Center(
              child: FadeTransition(
                opacity: _logoOpacity,
                child: ScaleTransition(
                  scale: _logoScale,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo with contrasting background
                      Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.95),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Image.asset(
                            'Asset/thk.png',
                            width: 120,
                            height: 120,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      // App title with modern styling
                      const Text(
                        'ThinkCyber',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Tagline
                      const Text(
                        'Learn • Secure • Empower',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 50),
                      // Loading indicator with modern design
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.2),
                              Colors.white.withOpacity(0.05),
                            ],
                          ),
                        ),
                        child: Center(
                          child: SizedBox(
                            width: 30,
                            height: 30,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                              backgroundColor: Colors.white.withOpacity(0.2),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Bottom accent line
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.white.withOpacity(0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
