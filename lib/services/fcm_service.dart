import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import 'api_client.dart';
import 'session_service.dart';

/// Service to manage FCM token registration and updates
class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  final _api = ThinkCyberApi();
  String? _cachedFcmToken;

  /// Get the current FCM token
  Future<String?> getToken() async {
    try {
      final messaging = FirebaseMessaging.instance;
      _cachedFcmToken = await messaging.getToken();
      return _cachedFcmToken;
    } catch (e) {
      debugPrint('⚠️ FcmService: Failed to get FCM token: $e');
      return null;
    }
  }

  /// Register FCM token with the server
  /// Call this after user login and when token refreshes
  Future<bool> registerTokenWithServer() async {
    try {
      final userId = await SessionService.getUserId();
      if (userId == null) {
        debugPrint('⚠️ FcmService: No user logged in, skipping token registration');
        return false;
      }

      final fcmToken = await getToken();
      if (fcmToken == null) {
        debugPrint('⚠️ FcmService: No FCM token available');
        return false;
      }

      // Get device info
      final deviceInfo = await _getDeviceInfo();

      debugPrint('📲 FcmService: Registering FCM token with server...');
      debugPrint('   UserId: $userId');
      debugPrint('   Token: ${fcmToken.substring(0, 20)}...');

      final response = await _api.updateFcmToken(
        userId: userId,
        fcmToken: fcmToken,
        deviceId: deviceInfo['deviceId'],
        deviceName: deviceInfo['deviceName'],
      );

      if (response.success) {
        debugPrint('✅ FcmService: FCM token registered successfully');
        return true;
      } else {
        debugPrint('⚠️ FcmService: Failed to register token: ${response.message}');
        return false;
      }
    } catch (e) {
      debugPrint('⚠️ FcmService: Error registering FCM token: $e');
      return false;
    }
  }

  /// Set up token refresh listener
  void setupTokenRefreshListener() {
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      debugPrint('📲 FcmService: FCM token refreshed');
      _cachedFcmToken = newToken;
      await registerTokenWithServer();
    });
  }

  /// Get device information
  Future<Map<String, String?>> _getDeviceInfo() async {
    try {
      final deviceInfoPlugin = DeviceInfoPlugin();
      
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        return {
          'deviceId': androidInfo.id,
          'deviceName': '${androidInfo.brand} ${androidInfo.model}',
        };
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        return {
          'deviceId': iosInfo.identifierForVendor,
          'deviceName': iosInfo.name,
        };
      }
    } catch (e) {
      debugPrint('⚠️ FcmService: Failed to get device info: $e');
    }
    
    return {'deviceId': null, 'deviceName': null};
  }

  void dispose() {
    _api.dispose();
  }
}
