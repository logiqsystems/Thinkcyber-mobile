// lib/examples/api_usage_example.dart

/// This file demonstrates how to use the new centralized API configuration system.
/// 
/// IMPORTANT: This is an example file for documentation purposes.
/// You can delete this file after understanding the usage patterns.

import '../services/api_client.dart';
import '../services/enhanced_api_service.dart';
import '../config/api_config.dart';

class ApiUsageExample {
  
  // ==================== BASIC USAGE WITH EXISTING API CLIENT ====================
  
  /// Example: Using the existing ThinkCyberApi with new configuration
  Future<void> exampleWithExistingClient() async {
    final api = ThinkCyberApi();
    
    try {
      // The API client now automatically uses endpoints from ApiConfig
      final topics = await api.fetchTopics(userId: 123);
      print('✅ Loaded ${topics.topics.length} topics');
      
      final loginResponse = await api.sendLoginOtp(email: 'user@example.com');
      print('✅ OTP sent: ${loginResponse.message}');
      
    } catch (e) {
      print('❌ Error: $e');
    } finally {
      api.dispose();
    }
  }
  
  // ==================== ADVANCED USAGE WITH ENHANCED API SERVICE ====================
  
  /// Example: Using the new EnhancedApiService with better error handling
  Future<void> exampleWithEnhancedService() async {
    final apiService = EnhancedApiService();
    
    try {
      // Set authentication token if available
      apiService.setAuthToken('your_jwt_token_here');
      
      // Make a GET request with custom parser
      final topicsResponse = await apiService.get<TopicResponse>(
        ApiConfig.Topics.listWithUser(123),
        parser: (json) => TopicResponse.fromJson(json),
      );
      
      if (topicsResponse.isSuccess) {
        final topics = topicsResponse.data!;
        print('✅ Successfully loaded ${topics.topics.length} topics');
      } else {
        // Handle different types of errors
        final error = topicsResponse.error!;
        if (error is ApiNetworkException) {
          print('❌ Network error: Check your internet connection');
        } else if (error is ApiServerException) {
          print('❌ Server error: ${error.message}');
        } else if (error is ApiTimeoutException) {
          print('❌ Request timed out: Try again later');
        } else {
          print('❌ Unknown error: ${error.message}');
        }
      }
      
      // Make a POST request
      final signupResponse = await apiService.post<SignupResponse>(
        ApiConfig.Auth.signup,
        body: {
          'email': 'newuser@example.com',
          'firstname': 'John',
          'lastname': 'Doe',
        },
        parser: (json) => SignupResponse.fromJson(json),
      );
      
      if (signupResponse.isSuccess) {
        print('✅ User signed up successfully');
      } else {
        print('❌ Signup failed: ${signupResponse.error!.message}');
      }
      
    } finally {
      apiService.dispose();
    }
  }
  
  // ==================== ENVIRONMENT SWITCHING EXAMPLE ====================
  
  /// Example: How to check current environment and configuration
  void exampleEnvironmentInfo() {
    print('🌍 Current Environment: ${ApiConfig.environmentName}');
    print('🔗 Base URL: ${ApiConfig.baseUrl}');
    print('⏱️  Timeout: ${ApiConfig.timeout.inSeconds}s');
    print('📝 Logging: ${ApiConfig.isLoggingEnabled ? 'Enabled' : 'Disabled'}');
    
    // Check environment type
    if (ApiConfig.isProduction) {
      print('🔴 Running in PRODUCTION mode');
    } else if (ApiConfig.isStaging) {
      print('🟡 Running in STAGING mode');
    } else {
      print('🟢 Running in DEVELOPMENT mode');
    }
    
    // Build specific URLs
    final loginUrl = ApiConfig.buildUrl(ApiConfig.Auth.sendLoginOtp);
    final topicsUrl = ApiConfig.buildUrl(ApiConfig.Topics.listWithUser(456));
    
    print('🔐 Login URL: $loginUrl');
    print('📚 Topics URL: $topicsUrl');
  }
  
  // ==================== ERROR HANDLING PATTERNS ====================
  
  /// Example: Comprehensive error handling with the enhanced service
  Future<void> exampleErrorHandling() async {
    final apiService = EnhancedApiService();
    
    try {
      final response = await apiService.get<TopicResponse>(
        ApiConfig.Topics.list,
        parser: (json) => TopicResponse.fromJson(json),
      );
      
      if (response.isSuccess) {
        // Handle success
        final data = response.dataOrThrow;
        print('Success: ${data.topics.length} topics loaded');
      } else {
        // Handle specific error types
        switch (response.error.runtimeType) {
          case ApiNetworkException:
            _showNetworkError();
            break;
          case ApiServerException:
            final serverError = response.error as ApiServerException;
            _showServerError(serverError.message, serverError.statusCode);
            break;
          case ApiTimeoutException:
            _showTimeoutError();
            break;
          case ApiParsingException:
            _showParsingError();
            break;
          default:
            _showGenericError(response.error!.message);
        }
      }
    } finally {
      apiService.dispose();
    }
  }
  
  // Helper methods for error handling
  void _showNetworkError() {
    print('🌐 Please check your internet connection and try again.');
  }
  
  void _showServerError(String message, int? statusCode) {
    print('🔥 Server error ($statusCode): $message');
  }
  
  void _showTimeoutError() {
    print('⏰ Request timed out. Please try again.');
  }
  
  void _showParsingError() {
    print('📄 Failed to process server response.');
  }
  
  void _showGenericError(String message) {
    print('❓ An error occurred: $message');
  }
}

// ==================== USAGE IN WIDGETS ====================

/// Example: Using the API service in a Flutter widget
/// 
/// ```dart
/// class MyWidget extends StatefulWidget {
///   @override
///   _MyWidgetState createState() => _MyWidgetState();
/// }
/// 
/// class _MyWidgetState extends State<MyWidget> {
///   final _apiService = EnhancedApiService();
///   List<CourseTopic> _topics = [];
///   bool _isLoading = false;
///   String? _errorMessage;
/// 
///   @override
///   void initState() {
///     super.initState();
///     _loadTopics();
///   }
/// 
///   @override
///   void dispose() {
///     _apiService.dispose();
///     super.dispose();
///   }
/// 
///   Future<void> _loadTopics() async {
///     setState(() {
///       _isLoading = true;
///       _errorMessage = null;
///     });
/// 
///     final response = await _apiService.get<TopicResponse>(
///       ApiConfig.Topics.list,
///       parser: (json) => TopicResponse.fromJson(json),
///     );
/// 
///     if (mounted) {
///       setState(() {
///         _isLoading = false;
///         if (response.isSuccess) {
///           _topics = response.data!.topics;
///         } else {
///           _errorMessage = response.error!.message;
///         }
///       });
///     }
///   }
/// 
///   @override
///   Widget build(BuildContext context) {
///     return Scaffold(
///       body: _isLoading
///           ? Center(child: CircularProgressIndicator())
///           : _errorMessage != null
///               ? Center(child: Text('Error: $_errorMessage'))
///               : ListView.builder(
///                   itemCount: _topics.length,
///                   itemBuilder: (context, index) {
///                     return ListTile(
///                       title: Text(_topics[index].title),
///                     );
///                   },
///                 ),
///     );
///   }
/// }
/// ```

// ==================== ENVIRONMENT SWITCHING GUIDE ====================

/// HOW TO SWITCH ENVIRONMENTS:
/// 
/// 1. Open lib/config/api_config.dart
/// 2. Change the `currentEnvironment` variable:
/// 
///    For Development:
///    static const ApiEnvironment currentEnvironment = ApiEnvironment.development;
/// 
///    For Staging:
///    static const ApiEnvironment currentEnvironment = ApiEnvironment.staging;
/// 
///    For Production:
///    static const ApiEnvironment currentEnvironment = ApiEnvironment.production;
/// 
/// 3. Update the environment configurations in the `_environments` map as needed
/// 4. Rebuild your app - all API calls will now use the new environment

// ==================== ADDING NEW ENDPOINTS ====================

/// HOW TO ADD NEW API ENDPOINTS:
/// 
/// 1. Open lib/config/api_config.dart
/// 2. Add your new endpoint to the appropriate class:
/// 
///    class User {
///      static const String profile = '/user/profile';
///      static const String updateAvatar = '/user/avatar';  // New endpoint
///    }
/// 
/// 3. Use in your code:
/// 
///    final response = await apiService.post(
///      ApiConfig.User.updateAvatar,
///      body: {'avatar': base64Image},
///    );
