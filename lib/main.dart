import 'dart:async';
import 'dart:io';

import 'screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'config/api_config.dart';
import 'services/fcm_service.dart';

// Flutter Local Notifications plugin instance
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Android notification channel
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel', // id - must match AndroidManifest
  'High Importance Notifications', // title
  description: 'This channel is used for important notifications.',
  importance: Importance.high,
  playSound: true,
);

// Handle background notifications
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('📬 Background notification received:');
  print('   Title: ${message.notification?.title}');
  print('   Body: ${message.notification?.body}');
  print('   Data: ${message.data}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (with error handling)
  try {
    await Firebase.initializeApp();
    print('✅ Firebase initialized successfully');
  } catch (e) {
    print('⚠️ Firebase initialization failed: $e');
    // Continue app execution even if Firebase fails
  }

  // Initialize Flutter Local Notifications
  try {
    // Create Android notification channel
    if (Platform.isAndroid) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
      print('✅ Android notification channel created');
    }

    // Initialize local notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
    print('✅ Flutter Local Notifications initialized');
  } catch (e) {
    print('⚠️ Failed to initialize local notifications: $e');
  }

  // Set up background notification handler
  try {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    print('✅ Background notification handler registered');
  } catch (e) {
    print('⚠️ Failed to register background handler: $e');
  }

  // Request notification permissions and log FCM token
  try {
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    print('📱 Notification permission status: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      final token = await messaging.getToken();
      print('📲 FCM TOKEN: ${token ?? 'unavailable'}');

      // Set foreground notification presentation options
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
      print('✅ Foreground notification options set');
    } else {
      print('⚠️ Notifications denied. Skipping FCM token retrieval.');
    }
  } catch (e) {
    print('⚠️ Failed to fetch FCM token: $e');
  }

  // Lock app to portrait orientation only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Log API configuration at startup
  ApiConfig.logConfiguration();

  // Show detailed configuration for debugging
  print('🎯 CURRENT API BASE URL: ${ApiConfig.baseUrl}');
  print('🌍 ENVIRONMENT: ${ApiConfig.environmentName}');

  runApp(const ThinkCyberApp());
}

class ThinkCyberApp extends StatefulWidget {
  const ThinkCyberApp({super.key});

  @override
  State<ThinkCyberApp> createState() => _ThinkCyberAppState();
}

class _ThinkCyberAppState extends State<ThinkCyberApp> {
  final _fcmService = FcmService();

  @override
  void initState() {
    super.initState();
    _setupForegroundNotificationHandler();
    _registerFcmToken();
  }

  /// Register FCM token with server and set up refresh listener
  Future<void> _registerFcmToken() async {
    // Set up token refresh listener
    _fcmService.setupTokenRefreshListener();
    
    // Register current token with server (will only work if user is logged in)
    await _fcmService.registerTokenWithServer();
  }

  void _setupForegroundNotificationHandler() {
    // Handle foreground notifications - show local notification
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('═══════════════════════════════════════════');
      print('📨 FOREGROUND NOTIFICATION RECEIVED:');
      print('   Title: ${message.notification?.title}');
      print('   Body: ${message.notification?.body}');
      print('   Data: ${message.data}');
      print('═══════════════════════════════════════════');

      final notification = message.notification;

      // Show local notification when app is in foreground
      if (notification != null) {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
              playSound: true,
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          payload: message.data.toString(),
        );
        print('✅ Local notification displayed');
      }
    });

    // Handle notification taps (when app is in background and user taps)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('═══════════════════════════════════════════');
      print('🎯 NOTIFICATION TAPPED:');
      print('   Title: ${message.notification?.title}');
      print('   Body: ${message.notification?.body}');
      print('   Data: ${message.data}');
      print('═══════════════════════════════════════════');
      // Handle navigation based on notification data
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ThinkCyber LMS',
      theme: _buildTheme(),
      home: const SplashScreen(),
    );
  }

  ThemeData _buildTheme() {
    const primaryBlue = Color(0xFF0D6EFD);
    const deepNavy = Color(0xFF00163A);
    const slate = Color(0xFF1E293B);
    const background = Color(0xFFF5F7FD);

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: background,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        brightness: Brightness.light,
        secondary: const Color(0xFF3B82F6),
      ),
    );

    final textTheme = base.textTheme.copyWith(
      headlineLarge: base.textTheme.headlineLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: deepNavy,
        letterSpacing: -0.2,
      ),
      headlineMedium: base.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: deepNavy,
        letterSpacing: -0.15,
      ),
      headlineSmall: base.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: deepNavy,
        letterSpacing: -0.1,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: slate,
        letterSpacing: 0.1,
      ),
      bodyLarge: base.textTheme.bodyLarge?.copyWith(
        color: slate.withValues(alpha: 0.85),
        height: 1.5,
      ),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(
        color: slate.withValues(alpha: 0.9),
        height: 1.5,
      ),
      bodySmall: base.textTheme.bodySmall?.copyWith(
        color: slate.withValues(alpha: 0.75),
        height: 1.45,
      ),
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: deepNavy,
      ),
      textTheme: textTheme,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 3,
          shadowColor: primaryBlue.withValues(alpha: 0.35),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryBlue,
          side: BorderSide(
            color: primaryBlue.withValues(alpha: 0.35),
            width: 1.2,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryBlue,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 22,
          vertical: 18,
        ),
        labelStyle: TextStyle(color: slate.withValues(alpha: 0.7)),
        hintStyle: TextStyle(color: slate.withValues(alpha: 0.45)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: slate.withValues(alpha: 0.12)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: slate.withValues(alpha: 0.16)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: primaryBlue, width: 1.6),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        margin: EdgeInsets.zero,
        elevation: 0,
      ),
      dividerTheme: DividerThemeData(
        thickness: 1,
        space: 1,
        color: slate.withValues(alpha: 0.1),
      ),
    );
  }
}
