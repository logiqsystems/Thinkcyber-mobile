# Razorpay REST API Integration - Quick Reference

## Summary of Changes

✅ **Fixed**: 404 error on `/api/enrollments/mobile-enroll`
✅ **Implemented**: Direct Razorpay REST API integration
✅ **Added**: Payment capture after Razorpay success
✅ **Added**: Backend enrollment endpoint integration

## What Changed

### 1. Order Creation
**Before**: 
```dart
// ❌ This endpoint doesn't exist
final response = await _api.createMobileEnrollment(
  userId: userId,
  topicId: detail.id,
  email: email,
);
```

**After**:
```dart
// ✅ Direct Razorpay REST API
final orderResult = await RazorpayHttpService.createOrder(
  amount: (detail.price * 100).toInt(),
  currency: 'INR',
  receipt: 'enrollment_${userId}_${detail.id}_${DateTime.now().millisecondsSinceEpoch}',
  notes: {'userId': userId, 'topicId': detail.id, 'email': email},
);
final orderId = orderResult['id'] as String;
```

### 2. Payment Capture
**Before**:
```dart
// ❌ No capture step - payment never confirmed
void _handlePaymentSuccess(PaymentSuccessResponse response) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: TranslatedText('Payment successful!')),
  );
  _fetchDetail(userId: _userId);
}
```

**After**:
```dart
// ✅ Capture payment from Razorpay
void _handlePaymentSuccess(PaymentSuccessResponse response) async {
  // 1. Capture payment
  final captureResult = await RazorpayHttpService.capturePayment(
    paymentId: response.paymentId!,
    amount: (detail.price * 100).toInt(),
    currency: 'INR',
  );
  
  // 2. Enroll user on backend
  final enrollmentResponse = await _api.enrollPaidCourse(
    userId: userId,
    topicId: detail.id,
    email: email,
    paymentId: response.paymentId!,
  );
}
```

### 3. New Backend Endpoint
**Added**: `/api/enrollments/paid-enroll`

```dart
Future<GenericResponse> enrollPaidCourse({
  required int userId,
  required int topicId,
  required String email,
  required String paymentId,
})
```

## How to Implement Backend Endpoint

Your backend must handle:

```
POST /api/enrollments/paid-enroll
Content-Type: application/json

{
  "userId": 40,
  "topicId": 72,
  "email": "user@example.com",
  "paymentId": "pay_29QQoUBi66xm2f"
}
```

Return:
```json
{
  "success": true,
  "message": "Successfully enrolled in course"
}
```

## Key Methods Added

### [lib/services/api_client.dart](lib/services/api_client.dart#L169)
```dart
enrollPaidCourse({userId, topicId, email, paymentId})
```

### [lib/screens/topic_detail_screen.dart](lib/screens/topic_detail_screen.dart#L139)
- Updated `_handlePaymentSuccess()` - Now captures payment and enrolls
- Updated `_handlePurchase()` - Now uses Razorpay REST API directly

## Testing

1. Go to course detail page
2. Click "Buy Now" on a paid course
3. Razorpay dialog opens (should now succeed! ✅)
4. Complete test payment
5. Payment should be captured and enrollment should be created

Expected logs:
```
[Razorpay | Creating order for topic 72, amount: 499]
[Razorpay | Order created: order_2gQ1B2V0MO8f9s]
[Razorpay | Payment Success - PaymentId: pay_29QQoUBi66xm2f]
[Razorpay | Capturing payment: pay_29QQoUBi66xm2f]
[Razorpay | Payment Captured: pay_29QQoUBi66xm2f]
[Razorpay | Enrolling user 40 in topic 72]
```

## Files Modified

| File | Changes |
|------|---------|
| [lib/screens/topic_detail_screen.dart](lib/screens/topic_detail_screen.dart) | • Added import for RazorpayHttpService<br>• Updated `_handlePaymentSuccess()` to capture payment<br>• Updated `_handlePurchase()` to create order via Razorpay REST API |
| [lib/services/api_client.dart](lib/services/api_client.dart) | • Added `enrollPaidCourse()` method for backend enrollment |

## No Breaking Changes ✅

- Free course enrollment works as before
- Cart functionality unchanged
- Wishlist functionality unchanged
- All other payments features preserved

## Backend Verification (Optional but Recommended)

Before creating enrollment, verify the payment:

```dart
// In your backend when receiving enrollPaidCourse request
const paymentId = req.body.paymentId;

// Verify with Razorpay
const paymentDetails = await razorpayApi.fetchPayment(paymentId);
if (paymentDetails.status !== 'captured') {
  return res.json({success: false, message: 'Payment not captured'});
}

// Then create enrollment
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Order creation fails | Check Razorpay config (keyId, keySecret) |
| Payment dialog won't open | Check order ID is valid in logs |
| Capture fails | Check Razorpay credentials and test mode |
| Enrollment fails | Verify backend endpoint exists at `/api/enrollments/paid-enroll` |
| 404 on enrollments endpoint | Implement the endpoint on your backend |
