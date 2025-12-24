import 'dart:async';
import 'dart:math' as math;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/session_service.dart';
import '../services/api_client.dart';
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
    try {
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

      final canProceed = await _checkVersionAndMaybePrompt();
      if (!canProceed || !mounted) return;

      await Future.delayed(const Duration(milliseconds: 2200));
      if (!mounted || _navigated) return;
      _navigate(destination);
    } catch (e) {
      debugPrint('⚠️ Navigation preparation failed: $e');
      // Fallback to onboarding screen on error
      if (mounted && !_navigated) {
        _navigate(const OnboardingScreen());
      }
    }
  }

  Future<bool> _checkVersionAndMaybePrompt() async {
    ThinkCyberApi? api;
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentCode = int.tryParse(packageInfo.buildNumber) ?? 1;

      api = ThinkCyberApi();
      final response = await api.checkAppVersion(
        currentVersionCode: currentCode,
        platform: Platform.isIOS ? 'ios' : 'android',
      );

      if (!mounted) return false;
      final info = response.data;
      if (response.success != true || info == null) {
        return true;
      }

      final hasUpdate = info.latestVersionCode > currentCode;
      final shouldForce = info.forceUpdate || info.updateRequired || hasUpdate;

      if (!hasUpdate) {
        return true;
      }

      await _showUpdateDialog(info, packageInfo.appName, force: shouldForce);
      return !shouldForce;
    } catch (e) {
      debugPrint('⚠️ Version check failed: $e');
      return true;
    } finally {
      api?.dispose();
    }
  }

  Future<void> _showUpdateDialog(
      AppVersionInfo info,
      String appName, {
        required bool force,
      }) async {
    if (!mounted) return;

    final titleText = (appName.trim().isNotEmpty) ? appName.trim() : 'Update Available';
    final messageText = info.message.trim().isNotEmpty
        ? info.message.trim()
        : "We've improved performance and fixed bugs. Update now for the best experience.";

    // Track expanded state for What's New section
    bool isExpanded = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: !force,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return PopScope(
              canPop: !force,
              child: Dialog(
                insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                elevation: 0,
                backgroundColor: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2E7DFF).withOpacity(0.15),
                        blurRadius: 32,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Modern Gradient Header
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                const Color(0xFF2E7DFF),
                                const Color(0xFF2E7DFF).withOpacity(0.85),
                              ],
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // App Icon Container
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.asset(
                                    'Asset/appIcon.png',
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Title
                              Text(
                                'Update Available',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              // Subtitle
                              Text(
                                force
                                    ? 'This update is required to continue using the app'
                                    : 'Stay updated with the latest features and improvements',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w500,
                                  height: 1.4,
                                ),
                              ),
                              if (info.latestVersionName != null &&
                                  info.latestVersionName!.trim().isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.25),
                                    ),
                                  ),
                                  child: Text(
                                    'Version ${info.latestVersionName}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        
                        // Body Content
                        Container(
                          color: Colors.white,
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Always show "What's New" button first (collapsed state)
                              if (!isExpanded) ...[
                                // What's New Button - tap to see message
                                GestureDetector(
                                  onTap: () {
                                    isExpanded = true;
                                    setDialogState(() {});
                                  },
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2E7DFF).withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFF2E7DFF).withOpacity(0.2),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF2E7DFF).withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Icon(
                                            Icons.featured_play_list_outlined,
                                            color: const Color(0xFF2E7DFF),
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "What's New",
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                  color: const Color(0xFF1F2937),
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'Tap to see update details',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: const Color(0xFF6B7280),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          color: const Color(0xFF2E7DFF),
                                          size: 24,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ] else ...[
                                // Expanded - Show full message
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF9FAFB),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFFE5E7EB),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.new_releases_outlined,
                                            color: const Color(0xFF2E7DFF),
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            "What's New",
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFF1F2937),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      // Features List
                                      Container(
                                        constraints: BoxConstraints(maxHeight: 150),
                                        child: SingleChildScrollView(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: messageText.split('\n').map((line) {
                                              final trimmedLine = line.trim();
                                              if (trimmedLine.isEmpty) return const SizedBox(height: 6);
                                              
                                              // Check if line starts with bullet or dash
                                              final isBullet = trimmedLine.startsWith('•') ||
                                                  trimmedLine.startsWith('-') ||
                                                  trimmedLine.startsWith('*');
                                              final displayText = isBullet 
                                                  ? trimmedLine.substring(1).trim() 
                                                  : trimmedLine;
                                              
                                              return Padding(
                                                padding: const EdgeInsets.only(bottom: 8),
                                                child: Row(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Container(
                                                      margin: const EdgeInsets.only(top: 6),
                                                      width: 6,
                                                      height: 6,
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFF2E7DFF),
                                                        shape: BoxShape.circle,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 10),
                                                    Expanded(
                                                      child: Text(
                                                        displayText,
                                                        style: TextStyle(
                                                          fontSize: 13.5,
                                                          height: 1.5,
                                                          fontWeight: FontWeight.w500,
                                                          color: const Color(0xFF4B5563),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      // Show Less Button
                                      GestureDetector(
                                        onTap: () {
                                          isExpanded = false;
                                          setDialogState(() {});
                                        },
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.keyboard_arrow_up_rounded,
                                              color: const Color(0xFF6B7280),
                                              size: 18,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Show Less',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: const Color(0xFF6B7280),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              
                              const SizedBox(height: 16),

                              // Info Box
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2E7DFF).withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFF2E7DFF).withOpacity(0.15),
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2E7DFF).withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.info_outline_rounded,
                                        color: Color(0xFF2E7DFF),
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        force
                                            ? 'This is a mandatory security update'
                                            : 'Regular updates keep your app secure and fast',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1F2937),
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Action Buttons
                        Container(
                          color: Colors.white,
                          padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Primary Button
                              Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF2E7DFF),
                                      Color(0xFF2E5FB0),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF2E7DFF).withOpacity(0.25),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => _openStore(info),
                                    borderRadius: BorderRadius.circular(14),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                        horizontal: 16,
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.cloud_download_outlined,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          const Text(
                                            'Update Now',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              if (!force) ...[
                                const SizedBox(height: 10),
                                // Secondary Button (Later)
                                Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6B7280).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () => Navigator.of(context).pop(),
                                      borderRadius: BorderRadius.circular(14),
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 14,
                                          horizontal: 16,
                                        ),
                                        child: Center(
                                          child: Text(
                                            'Later',
                                            style: TextStyle(
                                              color: Color(0xFF374151),
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openStore(AppVersionInfo info) async {
    final String url;
    
    if (Platform.isIOS) {
      url = (info.iosStoreUrl?.isNotEmpty == true)
          ? info.iosStoreUrl!
          : 'https://apps.apple.com/app/thinkcyber/id123456789';
    } else {
      url = (info.androidStoreUrl?.isNotEmpty == true)
          ? info.androidStoreUrl!
          : 'https://play.google.com/store/apps/details?id=com.edu.thinkcyber';
    }
    
    debugPrint('🔗 Opening store URL: $url');
    debugPrint('📦 Android URL from API: ${info.androidStoreUrl}');
    debugPrint('🍎 iOS URL from API: ${info.iosStoreUrl}');
    
    final uri = Uri.tryParse(url);
    if (uri == null) {
      debugPrint('❌ Invalid URL: $url');
      return;
    }

    try {
      final canLaunch = await canLaunchUrl(uri);
      debugPrint('📱 Can launch URL: $canLaunch');
      
      if (canLaunch) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        debugPrint('✅ URL launched successfully');
      } else {
        // Fallback: try with platform default
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      debugPrint('❌ Error launching URL: $e');
      // Show error to user if context is available
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open store. Please update manually.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
              Color(0xFF3B83FF), // Indigo
              Color(0xFF2563EB), // Indigo darker
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
                      // App Icon Logo
                      Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Image.asset(
                          'Asset/appIcon.png',
                          fit: BoxFit.contain,
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
