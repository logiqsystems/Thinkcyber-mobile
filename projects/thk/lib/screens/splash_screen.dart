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
      body: Stack(
        fit: StackFit.expand,
        children: [
          _AnimatedSplashBackground(controller: _backgroundController),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.35),
                  Colors.black.withOpacity(0.65),
                ],
              ),
            ),
          ),
          Center(
            child: FadeTransition(
              opacity: _logoOpacity,
              child: ScaleTransition(
                scale: _logoScale,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'Asset/thk.png',
                      width: 180,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'ThinkCyber',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Learn • Secure • Empower',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: _LoadingIndicator(),
          ),
        ],
      ),
    );
  }
}

class _AnimatedSplashBackground extends StatelessWidget {
  const _AnimatedSplashBackground({required this.controller});

  final Animation<double> controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final value = controller.value * 2 * math.pi;
        final sweepStops = [
          0.0,
          0.3 + 0.05 * math.sin(value),
          0.6 + 0.05 * math.sin(value + math.pi / 2),
          0.85 + 0.05 * math.sin(value + math.pi),
          1.0,
        ];
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: SweepGradient(
              startAngle: 0,
              endAngle: 2 * math.pi,
              colors: const [
                Color(0xFF030712),
                Color(0xFF2E026D),
                Color(0xFF7F1DFF),
                Color(0xFFFF5D8F),
                Color(0xFF030712),
              ],
              stops: sweepStops,
              center: Alignment(
                0.2 * math.sin(value * 0.7),
                0.2 * math.cos(value * 0.9),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LoadingIndicator extends StatefulWidget {
  const _LoadingIndicator();

  @override
  State<_LoadingIndicator> createState() => _LoadingIndicatorState();
}

class _LoadingIndicatorState extends State<_LoadingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 26,
        height: 26,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: _SpinnerPainter(progress: _controller.value),
            );
          },
        ),
      ),
    );
  }
}

class _SpinnerPainter extends CustomPainter {
  const _SpinnerPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 3.0;
    final rect = Offset.zero & size;
    final start = -math.pi / 2;
    final sweep = math.pi * 1.6 * progress.clamp(0.2, 1);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = const SweepGradient(
        colors: [
          Color(0xFFFFA5F3),
          Color(0xFF8B5CF6),
        ],
      ).createShader(rect);

    canvas.drawArc(
      Rect.fromLTWH(
        strokeWidth / 2,
        strokeWidth / 2,
        size.width - strokeWidth,
        size.height - strokeWidth,
      ),
      start,
      sweep,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _SpinnerPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
