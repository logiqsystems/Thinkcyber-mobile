# Bundle Purchase Business Logic - Implementation Guide

## ✅ Completed

### 1. Data Models Created
- **EnrollmentService** (`lib/services/enrollment_service.dart`)
  - `EnrollmentRecord` class with purchase type tracking
  - `PurchaseType` enum (free, bundle, individual)
  - Core enrollment service methods

### 2. API Methods Added
- `purcheBundle()` - Purchase category bundle
- `purchaseIndividualTopic()` - Purchase individual topic

### 3. Access Validator Utility
- **TopicAccessValidator** (`lib/utils/topic_access_validator.dart`)
  - `canAccessTopic()` - Check access with business logic
  - `getAccessStatus()` - Get detailed access reason
  - `getPurchaseOptions()` - Get available purchase options
  - `canPurchaseBundle()` - Validate bundle eligibility

---

## 📋 Integration Steps for Dashboard Screen

### Step 1: Import the new services
```dart
import '../services/enrollment_service.dart';
import '../utils/topic_access_validator.dart';
```

### Step 2: Add to _DashboardState
```dart
class _DashboardState extends State<Dashboard> {
  // ... existing code ...
  
  final _enrollmentService = EnrollmentService();
  final _accessValidator = TopicAccessValidator();
  late List<EnrollmentRecord> _userEnrollments = [];
  
  @override
  void initState() {
    super.initState();
    // ... existing code ...
    _loadUserEnrollments(); // Add this
  }
  
  Future<void> _loadUserEnrollments() async {
    if (!mounted) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('thinkcyber_user_id');
      
      if (userId != null) {
        final enrollments = await _api.fetchUserEnrollments(userId: userId);
        if (mounted) {
          setState(() {
            _userEnrollments = enrollments.map((e) {
              return EnrollmentRecord.fromJson(e.toJson());
            }).toList();
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading enrollments: $e');
    }
  }
}
```

### Step 3: Update topic card display
```dart
Widget _buildModernTopicCard(CourseTopic topic) {
  final accessStatus = _accessValidator.getAccessStatus(
    topic: topic,
    enrollments: _userEnrollments,
  );
  
  return GestureDetector(
    onTap: () {
      if (accessStatus.hasAccess) {
        _navigateToTopic(topic);
      } else {
        // Show purchase options
        _showPurchaseOptions(topic);
      }
    },
    child: Container(
      // ... existing styling ...
      child: Column(
        children: [
          // ... existing image section ...
          
          // Card Content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TranslatedText(
                  topic.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _text,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                TranslatedText(
                  topic.categoryName,
                  style: const TextStyle(
                    fontSize: 11,
                    color: _muted,
                  ),
                ),
                const SizedBox(height: 8),
                
                // NEW: Show enrollment status
                if (accessStatus.hasAccess)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: TranslatedText(
                      accessStatus.enrollmentType == 'bundle'
                          ? 'Bundle Access'
                          : 'Purchased',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B6B).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: TranslatedText(
                      'Not Purchased',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFFF6B6B),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
```

### Step 4: Implement purchase sheet
```dart
void _showPurchaseOptions(CourseTopic topic) {
  final options = _accessValidator.getPurchaseOptions(
    topic: topic,
    bundlePrice: topic.price * 2, // Example calculation
  );
  
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TranslatedText(
            'Get Access to ${topic.title}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          ...options.map((option) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildPurchaseOptionCard(topic, option),
            );
          }).toList(),
        ],
      ),
    ),
  );
}

Widget _buildPurchaseOptionCard(CourseTopic topic, PurchaseOption option) {
  return GestureDetector(
    onTap: () => _handlePurchase(topic, option),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TranslatedText(
                  option.label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                TranslatedText(
                  option.description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          TranslatedText(
            option.isFree ? 'Free' : '₹${option.price.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2E7DFF),
            ),
          ),
        ],
      ),
    ),
  );
}

Future<void> _handlePurchase(CourseTopic topic, PurchaseOption option) async {
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getInt('thinkcyber_user_id');
  final email = prefs.getString('thinkcyber_email');
  
  if (userId == null || email == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please login first')),
    );
    return;
  }
  
  Navigator.pop(context);
  
  switch (option.type) {
    case 'enroll_free':
      await _enrollFree(userId, topic.id, email);
      break;
    case 'individual':
      await _handleIndividualPurchase(userId, topic.id, email);
      break;
    case 'bundle':
      await _handleBundlePurchase(userId, topic.categoryId, email);
      break;
  }
}

Future<void> _enrollFree(int userId, int topicId, String email) async {
  try {
    final response = await _api.enrollFreeCourse(
      userId: userId,
      topicId: topicId,
      email: email,
    );
    
    if (response.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Successfully enrolled in course!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
      await _loadUserEnrollments();
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Error enrolling in course')),
    );
  }
}

Future<void> _handleIndividualPurchase(
  int userId,
  int topicId,
  String email,
) async {
  try {
    final success = await _enrollmentService.purchaseIndividualTopic(
      userId: userId,
      topicId: topicId,
      email: email,
    );
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Topic purchased successfully!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
      await _loadUserEnrollments();
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Error purchasing topic')),
    );
  }
}

Future<void> _handleBundlePurchase(
  int userId,
  int categoryId,
  String email,
) async {
  try {
    final success = await _enrollmentService.purchaseBundle(
      userId: userId,
      categoryId: categoryId,
      email: email,
    );
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bundle purchased successfully!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
      await _loadUserEnrollments();
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Error purchasing bundle')),
    );
  }
}
```

---

## 🔧 Backend Requirements

Your backend must implement these endpoints:

### 1. Purchase Bundle
```
POST /api/enrollments/purchase-bundle
{
  "userId": 10,
  "categoryId": 3,
  "email": "user@example.com"
}

Response:
{
  "success": true,
  "message": "Bundle purchased successfully",
  "enrollmentIds": [1, 2, 3, 4, 5]
}
```

### 2. Purchase Individual Topic
```
POST /api/enrollments/purchase-individual
{
  "userId": 10,
  "topicId": 5,
  "email": "user@example.com"
}

Response:
{
  "success": true,
  "message": "Topic purchased successfully"
}
```

### 3. Update Enrollment Response
Add these fields to enrollment responses:
```json
{
  "id": 1,
  "topic_id": 5,
  "purchase_type": "bundle",
  "category_id": 3,
  "include_future_topics": true,
  "enrolled_at": "2024-12-21T10:30:00Z",
  "topic_created_at": "2024-12-20T00:00:00Z"
}
```

---

## 🧪 Testing Logic

### Test 1: Bundle Purchase with Future Topics
```dart
// User purchases bundle for category "Security"
final enrollment = EnrollmentRecord(
  purchaseType: PurchaseType.bundle,
  categoryId: 3,
  includeFutureTopics: true,
  enrolledAt: DateTime.now(),
);

// Old topic (created before purchase)
final oldTopic = CourseTopic(
  categoryId: 3,
  // ... other fields
);

// New topic (created after purchase)
final newTopic = CourseTopic(
  categoryId: 3,
  // ... other fields
);

// Both should be accessible
assert(_enrollmentService.hasAccessToTopic(topic: oldTopic, enrollments: [enrollment]));
assert(_enrollmentService.hasAccessToTopic(topic: newTopic, enrollments: [enrollment]));
```

### Test 2: Individual Purchase (No Future Topics)
```dart
// User purchases individual topic
final enrollment = EnrollmentRecord(
  purchaseType: PurchaseType.individual,
  topicId: 5,
  includeFutureTopics: false,
);

// Purchased topic
final purchasedTopic = CourseTopic(id: 5);

// Other topic in same category
final otherTopic = CourseTopic(id: 6, categoryId: 3);

assert(_enrollmentService.hasAccessToTopic(topic: purchasedTopic, enrollments: [enrollment]));
assert(!_enrollmentService.hasAccessToTopic(topic: otherTopic, enrollments: [enrollment]));
```

---

## 📝 Summary

The bundle purchase logic is now fully implemented with:
- ✅ Purchase type tracking (bundle, individual, free)
- ✅ Future topics inclusion logic
- ✅ Category-based bundle purchases
- ✅ Individual topic purchases
- ✅ Access validation with detailed reasons
- ✅ Purchase options generation
- ✅ API methods for both purchase types

Next steps:
1. Implement backend endpoints
2. Integrate into dashboard screen (code provided above)
3. Test with real data
4. Add analytics tracking for purchases
