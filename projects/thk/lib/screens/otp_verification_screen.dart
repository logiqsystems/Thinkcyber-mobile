import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';

import '../services/api_client.dart';
import '../services/translation_service.dart';
import '../services/localization_service.dart';
import '../services/session_service.dart';
import '../widgets/translated_text.dart';

enum OtpFlowType { signup, login }

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({
    super.key,
    required this.email,
    required this.flow,
  });

  final String email;
  final OtpFlowType flow;

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  final _otpFocusNode = FocusNode();
  final _api = ThinkCyberApi();

  bool _isSubmitting = false;
  bool _isResending = false;
  final Map<String, String> _translations = {};
  
  // Timer variables
  Timer? _timer;
  int _resendTimer = 120; // 2 minutes in seconds
  bool _canResend = false;

  // Animation controllers
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _otpController.dispose();
    _otpFocusNode.dispose();
    _fadeController.dispose();
    _api.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    debugPrint('📱 OTP Screen - App lifecycle changed to: $state');
    
    // When app resumes (user comes back from checking email), restore focus
    if (state == AppLifecycleState.resumed) {
      if (mounted && _otpController.text.length < 6) {
        debugPrint('🔍 OTP Screen - App resumed, current OTP length: ${_otpController.text.length}');
        // Ensure system keyboard is shown
        SystemChannels.textInput.invokeMethod('TextInput.show');
        
        // Multiple delayed attempts to ensure focus is restored
        Future.delayed(const Duration(milliseconds: 50), () {
          if (mounted) {
            debugPrint('🎯 OTP Screen - First focus attempt');
            FocusScope.of(context).requestFocus(_otpFocusNode);
            SystemChannels.textInput.invokeMethod('TextInput.show');
          }
        });
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && !_otpFocusNode.hasFocus) {
            debugPrint('🎯 OTP Screen - Second focus attempt (backup)');
            FocusScope.of(context).requestFocus(_otpFocusNode);
            SystemChannels.textInput.invokeMethod('TextInput.show');
          }
        });
      }
    } else if (state == AppLifecycleState.paused) {
      debugPrint('⏸️ OTP Screen - App paused');
    } else if (state == AppLifecycleState.inactive) {
      debugPrint('⏸️ OTP Screen - App inactive');
    }
  }

  String _translateSync(String text) {
    return _translations[text] ?? text;
  }

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _fadeController.forward();
    
    _preloadTranslations();
    _startResendTimer();
    
    // Add lifecycle observer
    WidgetsBinding.instance.addObserver(this);
    
    // Request focus after frame is built and show keyboard
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          debugPrint('🎯 OTP Screen - Initial focus request on initState');
          FocusScope.of(context).requestFocus(_otpFocusNode);
          SystemChannels.textInput.invokeMethod('TextInput.show');
        }
      });
    });
  }

  void _startResendTimer() {
    _timer?.cancel();
    
    setState(() {
      _resendTimer = 120;
      _canResend = false;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimer > 0) {
        setState(() {
          _resendTimer--;
        });
      } else {
        timer.cancel();
        setState(() {
          _canResend = true;
        });
      }
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _preloadTranslations() async {
    final service = TranslationService();
    final localization = LocalizationService();
    final targetLang = localization.languageCode;
    
    final texts = [
      'OTP code',
      'Enter your code',
      'Code should be 6 digits',
      'Something went wrong. Try again.',
      'Could not resend OTP. Try again.',
    ];
    
    for (final text in texts) {
      _translations[text] = await service.translate(text, 'en', targetLang);
    }
    
    if (mounted) setState(() {});
  }

  String _maskEmail(String email) {
    if (!email.contains('@')) return email;
    final parts = email.split('@');
    final localPart = parts[0];
    final domain = parts[1];
    
    if (localPart.length <= 2) return email;
    
    final visibleStart = localPart.substring(0, 2);
    final maskedPart = '*' * (localPart.length - 2);
    return '$visibleStart$maskedPart@$domain';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF3B83FF),
              Color(0xFFF5F7FA),
            ],
            stops: [0.0, 0.35],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                // Custom App Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                      const Expanded(
                        child: Text(
                          'Verify Email',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 48), // Balance the back button
                    ],
                  ),
                ),
                
                // Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                      left: 20,
                      right: 20,
                      top: 16,
                      bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                    ),
                    child: Column(
                      children: [
                        // Header Card with Logo
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // THK Logo
                              Image.asset(
                                'Asset/thk.png',
                                width: 120,
                                height: 80,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(height: 12),
                              
                              // Title
                              const Text(
                                'Email Verification',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1F2937),
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Enter the verification code sent to your email',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF6B7280),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // OTP Form Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Email display with edit button
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFE5E7EB),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.email_outlined,
                                      size: 18,
                                      color: Color(0xFF3B83FF),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        _maskEmail(widget.email),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF1F2937),
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () => Navigator.of(context).pop(),
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF3B83FF).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Icon(
                                          Icons.edit,
                                          size: 14,
                                          color: Color(0xFF3B83FF),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 24),
                              
                              // OTP Input Section
                              Form(
                                key: _formKey,
                                child: Column(
                                  children: [
                                    // OTP boxes
                                    GestureDetector(
                                      onTap: () {
                                        FocusScope.of(context).requestFocus(_otpFocusNode);
                                      },
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                        children: List.generate(6, (index) {
                                          return _OtpBox(
                                            controller: _otpController,
                                            index: index,
                                          );
                                        }),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    // Hidden TextField for keyboard input
                                    SizedBox(
                                      height: 0,
                                      child: IgnorePointer(
                                        ignoring: false,
                                        child: TextField(
                                          controller: _otpController,
                                          focusNode: _otpFocusNode,
                                          keyboardType: TextInputType.number,
                                          textInputAction: TextInputAction.done,
                                          maxLength: 6,
                                          autofocus: false,
                                          enableInteractiveSelection: false,
                                          showCursor: false,
                                          decoration: const InputDecoration(
                                            border: InputBorder.none,
                                            counterText: '',
                                            contentPadding: EdgeInsets.zero,
                                            isDense: true,
                                          ),
                                          style: const TextStyle(
                                            color: Colors.transparent,
                                            fontSize: 1,
                                          ),
                                          inputFormatters: [
                                            FilteringTextInputFormatter.digitsOnly,
                                            LengthLimitingTextInputFormatter(6),
                                          ],
                                          onChanged: (value) {
                                            debugPrint('📝 OTP input changed: ${value.length}/6');
                                            if (mounted) {
                                              setState(() {});
                                              if (value.length == 6) {
                                                FocusScope.of(context).unfocus();
                                              }
                                            }
                                          },
                                          onTap: () {
                                            debugPrint('👆 OTP TextField tapped');
                                            _otpController.selection = TextSelection.fromPosition(
                                              TextPosition(offset: _otpController.text.length),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 20),
                              
                              // Resend timer/button
                              Center(
                                child: _isResending
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B83FF)),
                                        ),
                                      )
                                    : _canResend
                                        ? TextButton(
                                            onPressed: _isSubmitting ? null : _resendOtp,
                                            style: TextButton.styleFrom(
                                              foregroundColor: const Color(0xFF3B83FF),
                                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.refresh_rounded, size: 18),
                                                SizedBox(width: 8),
                                                TranslatedText(
                                                  'Resend OTP',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        : Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF3F4F6),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: const Color(0xFFE5E7EB),
                                                width: 1,
                                              ),
                                            ),
                                            child: RichText(
                                              text: TextSpan(
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                  color: Color(0xFF6B7280),
                                                ),
                                                children: [
                                                  const TextSpan(
                                                    text: 'Resend available in ',
                                                  ),
                                                  TextSpan(
                                                    text: _formatTime(_resendTimer),
                                                    style: const TextStyle(
                                                      color: Color(0xFF3B83FF),
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                              ),
                              
                              const SizedBox(height: 24),
                              
                              // Verify Button with gradient
                              Container(
                                width: double.infinity,
                                height: 52,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF3B83FF), Color(0xFF60A5FA)],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF3B83FF).withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: _isSubmitting ? null : _handleSubmit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                  child: _isSubmitting
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            TranslatedText(
                                              'Verify Code',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: 0.3,
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Icon(Icons.verified_rounded, size: 20),
                                          ],
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Didn't receive code hint
                        Text(
                          'Didn\'t receive the code? Check your spam folder',
                          style: TextStyle(
                            fontSize: 12,
                            color: const Color(0xFF6B7280).withOpacity(0.8),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    // Validate OTP length
    if (_otpController.text.trim().length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: TranslatedText(_translateSync('Code should be 6 digits')),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (widget.flow == OtpFlowType.signup) {
        final response = await _api.verifySignupOtp(
          email: widget.email,
          otp: _otpController.text.trim(),
        );
        if (!mounted) return;
        messenger.showSnackBar(SnackBar(content: Text(response.message)));

        if (response.success) {
          Navigator.of(context).pop(true);
        }
      } else {
        final fcmToken = await _fetchFcmToken();
        final deviceId = await _fetchDeviceId();
        final deviceName = await _fetchDeviceName();
        
        // Debug logging - showing what will be sent
        debugPrint('═══════════════════════════════════════════');
        debugPrint('🔐 OTP Login Verification Data:');
        debugPrint('   Email: ${widget.email}');
        debugPrint('   OTP: ${_otpController.text.trim()}');
        debugPrint('   FCM Token: ${fcmToken ?? '❌ NULL (notifications disabled?)'}');
        debugPrint('   Device ID: ${deviceId ?? '❌ NULL'}');
        debugPrint('   Device Name: ${deviceName ?? '❌ NULL'}');
        debugPrint('═══════════════════════════════════════════');
        
        final response = await _api.verifyLoginOtp(
          email: widget.email,
          otp: _otpController.text.trim(),
          fcmToken: fcmToken,
          deviceId: deviceId,
          deviceName: deviceName,
        );

        // Debug logging - API response
        debugPrint('═══════════════════════════════════════════');
        debugPrint('📥 OTP Verification API Response:');
        debugPrint('   Success: ${response.success}');
        debugPrint('   Message: ${response.message}');
        debugPrint('   User ID: ${response.user?.id ?? 'N/A'}');
        debugPrint('   User Name: ${response.user?.name ?? 'N/A'}');
        debugPrint('   User Email: ${response.user?.email ?? 'N/A'}');
        debugPrint('   Session Token: ${response.sessionToken != null ? '✅ Received (${response.sessionToken!.length} chars)' : '❌ NULL'}');
        debugPrint('═══════════════════════════════════════════');
        debugPrint('🔔 Welcome notification should be triggered by backend if FCM token was sent');
        debugPrint('   FCM Token sent: ${fcmToken != null ? '✅ YES' : '❌ NO'}');
        debugPrint('═══════════════════════════════════════════');

        if (!mounted) return;
        messenger.showSnackBar(SnackBar(content: Text(response.message)));

        if (response.success) {
          await SessionService.saveSession(email: widget.email, response: response);
          if (!mounted) return;
          Navigator.of(context).pop(true);
        }
      }
    } on ApiException catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: TranslatedText(_translateSync('Something went wrong. Try again.'))),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _resendOtp() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isResending = true);
    try {
      final response = await _api.resendOtp(email: widget.email);
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(response.message)));
      
      // Restart the timer after successful resend
      _startResendTimer();
    } on ApiException catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: TranslatedText(_translateSync('Could not resend OTP. Try again.'))),
      );
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  Future<String?> _fetchFcmToken() async {
    try {
      final messaging = FirebaseMessaging.instance;
      
      // Request permission
      final settings = await messaging.requestPermission(
        alert: true,
        announcement: true,
        badge: true,
        sound: true,
      );
      
      debugPrint('📱 Notification permission status: ${settings.authorizationStatus}');
      
      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        debugPrint('⚠️ Notifications not authorized. Status: ${settings.authorizationStatus}');
        return null;
      }
      
      final token = await messaging.getToken();
      if (token != null) {
        debugPrint('✅ FCM TOKEN OBTAINED: $token');
      } else {
        debugPrint('❌ FCM TOKEN IS NULL');
      }
      return token;
    } catch (e) {
      debugPrint('❌ Failed to fetch FCM token: $e');
      return null;
    }
  }

  Future<String?> _fetchDeviceId() async {
    try {
      final info = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await info.androidInfo;
        debugPrint('✅ Android Device ID: ${androidInfo.id}');
        return androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await info.iosInfo;
        final vendorId = iosInfo.identifierForVendor;
        debugPrint('✅ iOS Device ID: $vendorId');
        return vendorId;
      }
      debugPrint('⚠️ Unsupported platform for device ID');
      return null;
    } catch (e) {
      debugPrint('❌ Failed to fetch device ID: $e');
      return null;
    }
  }

  Future<String?> _fetchDeviceName() async {
    try {
      final info = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await info.androidInfo;
        final deviceName = '${androidInfo.brand} ${androidInfo.model}';
        debugPrint('✅ Android Device Name: $deviceName');
        return deviceName;
      } else if (Platform.isIOS) {
        final iosInfo = await info.iosInfo;
        final deviceName = iosInfo.utsname.machine;
        debugPrint('✅ iOS Device Name: $deviceName');
        return deviceName;
      }
      debugPrint('⚠️ Unsupported platform for device name');
      return null;
    } catch (e) {
      debugPrint('❌ Failed to fetch device name: $e');
      return null;
    }
  }


}

class _OtpBox extends StatefulWidget {
  final TextEditingController controller;
  final int index;

  const _OtpBox({
    required this.controller,
    required this.index,
  });

  @override
  State<_OtpBox> createState() => _OtpBoxState();
}

class _OtpBoxState extends State<_OtpBox> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.controller.text;
    final char = widget.index < text.length ? text[widget.index] : '';
    final hasValue = char.isNotEmpty;

    return Container(
      width: 48,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasValue ? const Color(0xFF3B83FF) : const Color(0xFFE5E7EB),
          width: hasValue ? 2 : 1,
        ),
        boxShadow: hasValue
            ? [
                BoxShadow(
                  color: const Color(0xFF3B83FF).withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Center(
        child: Text(
          char,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: hasValue ? const Color(0xFF1F2937) : const Color(0xFF9CA3AF),
          ),
        ),
      ),
    );
  }
}
