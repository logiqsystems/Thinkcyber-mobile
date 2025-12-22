# API Configuration System

This document describes the centralized API configuration system implemented in the ThinkCyber Flutter application.

## Overview

The API configuration system provides a centralized way to manage all API endpoints, environment settings, and network configurations. This makes it easy to switch between different environments (development, staging, production) and maintain consistency across the application.

## Key Features

- ✅ **Centralized endpoint management** - All API endpoints in one place
- ✅ **Environment-based configuration** - Easy switching between dev/staging/production
- ✅ **Enhanced error handling** - Comprehensive error types and handling
- ✅ **Automatic timeout management** - Environment-specific timeout configurations
- ✅ **Logging control** - Enable/disable logging per environment
- ✅ **Type-safe responses** - Strongly typed API responses with proper error handling
- ✅ **Authentication token management** - Automatic header injection

## File Structure

```
lib/
├── config/
│   └── api_config.dart          # Main API configuration
├── services/
│   ├── api_client.dart          # Updated existing API client
│   └── enhanced_api_service.dart # New enhanced API service
├── examples/
│   └── api_usage_example.dart   # Usage examples and documentation
└── test/
    └── api_config_test.dart     # API configuration tests
```

## Quick Start

### 1. Change Environment

To switch between environments, edit `lib/config/api_config.dart`:

```dart
// Change this line to switch environments
static const ApiEnvironment currentEnvironment = ApiEnvironment.development; // or staging, production
```

### 2. Use Existing API Client (Recommended for existing code)

The existing `ThinkCyberApi` class has been updated to use the new configuration:

```dart
final api = ThinkCyberApi();

// All existing methods now use centralized endpoints
final topics = await api.fetchTopics(userId: 123);
final loginResponse = await api.sendLoginOtp(email: 'user@example.com');

api.dispose();
```

### 3. Use Enhanced API Service (Recommended for new code)

For new features, use the enhanced service with better error handling:

```dart
final apiService = EnhancedApiService();
apiService.setAuthToken('your_jwt_token');

final response = await apiService.get<TopicResponse>(
  ApiConfig.Topics.listWithUser(123),
  parser: (json) => TopicResponse.fromJson(json),
);

if (response.isSuccess) {
  print('Success: ${response.data!.topics.length} topics');
} else {
  print('Error: ${response.error!.message}');
}

apiService.dispose();
```

## Environment Configuration

### Development Environment
- **Base URL**: `http://103.174.226.196/ThinkCyber/server/api`
- **Timeout**: 30 seconds
- **Logging**: Enabled

### Staging Environment
- **Base URL**: `https://staging.thinkcyber.com/api`
- **Timeout**: 25 seconds
- **Logging**: Enabled

### Production Environment
- **Base URL**: `https://api.thinkcyber.com/v1`
- **Timeout**: 20 seconds
- **Logging**: Disabled

## Available Endpoints

### Authentication
- `ApiConfig.Auth.signup` - `/auth/signup`
- `ApiConfig.Auth.sendLoginOtp` - `/auth/send-otp`
- `ApiConfig.Auth.verifyLoginOtp` - `/auth/verify-otp`
- `ApiConfig.Auth.verifySignupOtp` - `/auth/verify-signup-otp`
- `ApiConfig.Auth.resendOtp` - `/auth/resend-otp`

### Topics/Courses
- `ApiConfig.Topics.list` - `/topics`
- `ApiConfig.Topics.listWithUser(userId)` - `/topics?userId={userId}`
- `ApiConfig.Topics.detailWithId(id)` - `/topics/{id}`
- `ApiConfig.Topics.detailWithId(id, userId: userId)` - `/topics/{id}?userId={userId}`

### Enrollments
- `ApiConfig.Enrollments.mobileEnroll` - `/enrollments/mobile-enroll`
- `ApiConfig.Enrollments.enrollFree` - `/enrollments/enroll-free`
- `ApiConfig.Enrollments.userEnrollmentsWithId(userId)` - `/enrollments/user/{userId}`

## Error Handling

The enhanced API service provides comprehensive error handling:

```dart
final response = await apiService.get<TopicResponse>(...);

if (response.isFailure) {
  switch (response.error.runtimeType) {
    case ApiNetworkException:
      // Handle network connectivity issues
      showSnackBar('Please check your internet connection');
      break;
    case ApiServerException:
      final error = response.error as ApiServerException;
      showSnackBar('Server error: ${error.message}');
      break;
    case ApiTimeoutException:
      // Handle request timeouts
      showSnackBar('Request timed out. Please try again.');
      break;
    case ApiParsingException:
      // Handle JSON parsing errors
      showSnackBar('Invalid response from server');
      break;
    default:
      showSnackBar('An unexpected error occurred');
  }
}
```

## Adding New Endpoints

1. Open `lib/config/api_config.dart`
2. Add your endpoint to the appropriate class:

```dart
class User {
  static const String profile = '/user/profile';
  static const String updateAvatar = '/user/avatar';  // New endpoint
  
  // For dynamic endpoints
  static String getProfile(int userId) => '/user/$userId/profile';
}
```

3. Use in your code:

```dart
final response = await apiService.get(ApiConfig.User.profile);
final profileResponse = await apiService.get(ApiConfig.User.getProfile(123));
```

## Adding New Environments

1. Add new environment to the enum in `api_config.dart`:

```dart
enum ApiEnvironment {
  development,
  staging,
  production,
  testing,  // New environment
}
```

2. Add configuration:

```dart
static const Map<ApiEnvironment, EnvironmentConfig> _environments = {
  // ... existing environments
  ApiEnvironment.testing: EnvironmentConfig(
    name: 'Testing',
    baseUrl: 'http://localhost:3000/api',
    timeout: Duration(seconds: 10),
    enableLogging: true,
  ),
};
```

## Best Practices

### 1. Use the Enhanced Service for New Code
```dart
// ✅ Good - New code should use enhanced service
final apiService = EnhancedApiService();
final response = await apiService.get<MyModel>(...);

// ✅ Also good - Existing code can keep using ThinkCyberApi
final api = ThinkCyberApi();
final data = await api.fetchTopics();
```

### 2. Always Handle Errors
```dart
// ✅ Good - Handle both success and error cases
if (response.isSuccess) {
  updateUI(response.data!);
} else {
  showError(response.error!.message);
}

// ❌ Bad - Don't ignore errors
final data = response.dataOrThrow; // This will throw on error
```

### 3. Dispose Services Properly
```dart
class MyWidget extends StatefulWidget {
  @override
  _MyWidgetState createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  final _apiService = EnhancedApiService();

  @override
  void dispose() {
    _apiService.dispose(); // ✅ Always dispose
    super.dispose();
  }
}
```

### 4. Use Appropriate Parsers
```dart
// ✅ Good - Use specific parsers for type safety
final response = await apiService.get<List<CourseTopic>>(
  endpoint,
  parser: (json) => (json['data'] as List)
      .map((item) => CourseTopic.fromJson(item))
      .toList(),
);

// ❌ Bad - Don't cast without parsing
final data = response.data as List<CourseTopic>; // Unsafe cast
```

## Migration Guide

### From Hardcoded URLs
```dart
// ❌ Old way - hardcoded URLs
final url = 'http://103.174.226.196/ThinkCyber/server/api/topics';

// ✅ New way - use configuration
final url = ApiConfig.buildUrl(ApiConfig.Topics.list);
```

### From Manual Error Handling
```dart
// ❌ Old way - manual error handling
try {
  final response = await http.get(uri);
  if (response.statusCode == 200) {
    // Handle success
  } else {
    // Handle error
  }
} catch (e) {
  // Handle exception
}

// ✅ New way - structured error handling
final response = await apiService.get<MyModel>(...);
if (response.isSuccess) {
  // Handle success
} else {
  // Handle specific error types
}
```

## Troubleshooting

### Common Issues

1. **Import Error**: Make sure to import the config file:
   ```dart
   import '../config/api_config.dart';
   ```

2. **Wrong Environment**: Check the `currentEnvironment` setting in `api_config.dart`

3. **Network Errors**: Verify the base URL is correct for your environment

4. **Timeout Issues**: Adjust timeout settings in the environment configuration

### Debug Information

To see current configuration:
```dart
print('Environment: ${ApiConfig.environmentName}');
print('Base URL: ${ApiConfig.baseUrl}');
print('Timeout: ${ApiConfig.timeout}');
print('Logging: ${ApiConfig.isLoggingEnabled}');
```

## Security Considerations

- ✅ **API keys**: Store sensitive keys in environment variables, not in code
- ✅ **HTTPS**: Use HTTPS URLs for staging and production
- ✅ **Token storage**: Use secure storage for authentication tokens
- ✅ **Logging**: Disable logging in production to avoid exposing sensitive data

## Testing

Run the API configuration tests:
```bash
flutter test test/api_config_test.dart
```

The tests verify:
- Environment configurations are valid
- Endpoint URL building works correctly
- Headers are properly formatted
- Google Translate API integration

## Support

For questions or issues with the API configuration system, please:

1. Check this documentation first
2. Review the example files in `lib/examples/`
3. Look at existing usage in the codebase
4. Run the tests to verify your configuration

---

**Last Updated**: November 7, 2025  
**Version**: 1.0.0