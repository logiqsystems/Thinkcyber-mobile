# Razorpay Payment Integration Guide

## Overview
This document provides a complete guide to the Razorpay payment integration in the ThinkCyber Flutter app.

## Files Added/Modified

### 1. **pubspec.yaml**
- Added `razorpay_flutter: ^1.4.0` dependency

### 2. **lib/config/razorpay_config.dart** (NEW)
Configuration file containing:
- Razorpay Key ID
- Razorpay Key Secret
- Merchant information
- Supported payment methods

### 3. **lib/services/razorpay_service.dart** (NEW)
Singleton service class that handles:
- Razorpay initialization
- Payment dialog management
- Event listeners for success, failure, and external wallet
- Payment options setup

### 4. **lib/screens/topic_detail_screen.dart** (MODIFIED)
Integration points:
- Razorpay import added
- Razorpay service initialization in `initState()`
- Razorpay cleanup in `dispose()`
- Payment success, failure, and external wallet handlers
- Modified `_handlePurchase()` to use Razorpay instead of Stripe

## Setup Instructions

### Step 1: Get Razorpay Credentials
1. Create a Razorpay account at https://razorpay.com
2. Go to Razorpay Dashboard: https://dashboard.razorpay.com
3. Navigate to Settings → API Keys
4. Copy your Key ID and Key Secret

### Step 2: Configure Keys
Update `lib/config/razorpay_config.dart`:

```dart
class RazorpayConfig {
  static const String keyId = 'YOUR_ACTUAL_KEY_ID';
  static const String keySecret = 'YOUR_ACTUAL_KEY_SECRET';
  // ... rest of config
}
```

**⚠️ SECURITY WARNING**: Never commit actual API keys to version control. Consider using:
- Environment variables
- Secure configuration management (like flutter_dotenv)
- Encrypted storage

### Step 3: Android Configuration
Add the following to `android/app/build.gradle`:

```gradle
dependencies {
    implementation 'com.razorpay:checkout:1.6.40'
}
```

Also ensure your `android/app/AndroidManifest.xml` has:
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

### Step 4: iOS Configuration
No additional configuration required for iOS. The `razorpay_flutter` package handles it automatically.

### Step 5: Install Dependencies
```bash
flutter pub get
```

## Usage

### Basic Payment Flow

```dart
final razorpayService = RazorpayService();

// Set up callbacks
razorpayService.onSuccess = (PaymentSuccessResponse response) {
  // Handle successful payment
  print('Payment successful: ${response.paymentId}');
};

razorpayService.onFailure = (PaymentFailureResponse response) {
  // Handle payment failure
  print('Payment failed: ${response.message}');
};

// Open payment dialog
razorpayService.openPayment(
  keyId: RazorpayConfig.keyId,
  amount: 499.0, // in INR
  orderId: 'order_1234567890',
  name: RazorpayConfig.merchantName,
  description: 'Course Payment',
  email: 'user@example.com',
  phone: '9876543210',
);
```

## Payment Response Handling

### Success Response
```json
{
  "razorpay_payment_id": "pay_xxxxxxxxxx",
  "razorpay_order_id": "order_xxxxxxxxxx",
  "razorpay_signature": "9b2a3e5c1d7f..."
}
```

### Error Response
```json
{
  "code": "PAYMENT_FAILED",
  "message": "Payment processing failed",
  "source": "razorpay"
}
```

## Testing

### Test Card Details
Use these test credentials in sandbox mode:

**Success Scenario:**
- Card Number: 4111 1111 1111 1111
- Expiry: Any future date (MM/YY)
- CVV: Any 3-digit number

**Failure Scenario:**
- Card Number: 4000 0000 0000 0002
- Expiry: Any future date
- CVV: Any 3-digit number

### Enable Test Mode
In `RazorpayConfig`, set test keys from your Razorpay dashboard under Settings → API Keys (Test Mode).

## API Integration Points

### Backend Requirements
Your backend API should:

1. **Create Order Endpoint**
   ```
   POST /api/payments/create-order
   {
     "amount": 49900,  // in paise
     "currency": "INR",
     "receipt": "receipt_1234",
     "notes": {
       "userId": 123,
       "courseId": 456
     }
   }
   ```
   Response:
   ```json
   {
     "id": "order_xxxxxxxxxx",
     "entity": "order",
     "amount": 49900
   }
   ```

2. **Verify Payment Endpoint**
   ```
   POST /api/payments/verify
   {
     "razorpay_order_id": "order_xxxxxxxxxx",
     "razorpay_payment_id": "pay_xxxxxxxxxx",
     "razorpay_signature": "9b2a3e5c1d7f..."
   }
   ```
   Response:
   ```json
   {
     "success": true,
     "message": "Payment verified successfully"
   }
   ```

## Transaction Flow

```
┌─────────────┐
│   User      │
└──────┬──────┘
       │
       ▼
┌─────────────────────────┐
│ Create Order (Backend)  │
└──────┬──────────────────┘
       │
       ▼
┌─────────────────────────┐
│ Open Payment Dialog     │
│ (Razorpay)              │
└──────┬──────────────────┘
       │
       ├─ Success ─────────────┐
       │                        │
       │                        ▼
       │                ┌──────────────┐
       │                │ Verify Order │
       │                │ (Backend)    │
       │                └──────┬───────┘
       │                       │
       │                       ▼
       │                ┌──────────────┐
       │                │ Enroll User  │
       │                └──────────────┘
       │
       ├─ Failure ───────┐
       │                 │
       │                 ▼
       │         ┌──────────────┐
       │         │ Show Error   │
       │         └──────────────┘
       │
       └─ Cancel ────────┘
```

## Error Handling

Common error codes:

| Code | Description | Action |
|------|-------------|--------|
| BAD_REQUEST_ERROR | Invalid request parameters | Check API parameters |
| GATEWAY_ERROR | Payment gateway error | Retry payment |
| PAYMENT_FAILED | Card declined or insufficient funds | Ask user to try another card |
| CANCELLED | User cancelled payment | No action needed |
| SERVER_ERROR | Backend server error | Contact support |

## Security Considerations

1. **Never expose Key Secret**: Only use in secure backend
2. **Validate signatures**: Always verify payment signatures on backend
3. **Use HTTPS**: All API calls should be over HTTPS
4. **Implement 3D Secure**: For enhanced card security
5. **Store payment data securely**: Encrypt transaction records

## Production Checklist

- [ ] Replace test keys with live keys
- [ ] Test with real test cards
- [ ] Implement signature verification on backend
- [ ] Add transaction logging
- [ ] Set up payment retry mechanism
- [ ] Configure webhook for async payment updates
- [ ] Test error scenarios
- [ ] Set up refund mechanism
- [ ] Add payment history to user account
- [ ] Implement analytics tracking

## Troubleshooting

### Issue: "Invalid Key ID"
**Solution**: Ensure you've copied the correct Key ID from Razorpay dashboard

### Issue: "Payment dialog not opening"
**Solution**: Check internet connection and verify keyId is configured

### Issue: "Payment successful but enrollment not updating"
**Solution**: Verify backend signature verification and enrollment endpoint

### Issue: Android build fails
**Solution**: Run `flutter clean` and `flutter pub get` again

## Additional Resources

- [Razorpay Documentation](https://razorpay.com/docs/)
- [Razorpay Flutter Package](https://pub.dev/packages/razorpay_flutter)
- [Razorpay Test Cards](https://razorpay.com/docs/payments/payments/payment-gateway/test-cards/)
- [Razorpay API Reference](https://razorpay.com/docs/api/)

## Support

For issues with Razorpay integration:
1. Check the [Razorpay documentation](https://razorpay.com/docs/)
2. Review logs in Android Studio / Xcode
3. Contact Razorpay support through dashboard

## Version History

- **v1.0** (2025-12-15): Initial Razorpay integration
  - Added Razorpay SDK
  - Created RazorpayService singleton
  - Integrated with payment flow in TopicDetailScreen
  - Added configuration management
  - Added comprehensive documentation

## Migration from Stripe

If migrating from Stripe:

1. Old Stripe payment code is still available as reference
2. The `_handlePurchase()` method now uses Razorpay
3. Stripe imports remain for backward compatibility (can be removed if needed)
4. Test both payment flows before full production rollout

---

**Last Updated**: December 15, 2025
**Maintainer**: ThinkCyber Development Team
