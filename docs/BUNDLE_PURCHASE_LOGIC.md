# Bundle Purchase Business Logic Implementation

## Overview
This document outlines the business logic for bundle purchases, flexible plans, and individual purchases in the ThinkCyber app.

## Purchase Types

### 1. **Bundle Purchase** (Category-based)
- **When**: User purchases a bundle for an entire category
- **Access**: User gets access to ALL topics in that category
- **Future Topics**: ✅ YES - When admin adds new topics to the category, user automatically gets access
- **Data Model**: Need to track:
  - `purchaseType`: 'bundle' | 'individual' | 'free'
  - `categoryId`: The category bundle was purchased for
  - `purchaseDate`: When the bundle was purchased
  - `includeFutureTopics`: boolean (true for bundles)

### 2. **Flexible Plan - Individual Purchase**
- **When**: User buys a specific topic under flexible plan
- **Access**: User gets access ONLY to that specific topic
- **Future Topics**: ❌ NO - User does NOT get future topics added to category
- **Data Model**: Same as bundle but:
  - `purchaseType`: 'individual'
  - `categoryId`: null (not applicable)
  - `includeFutureTopics`: false

### 3. **Free Topics**
- **When**: Topic is marked as free
- **Access**: Always available to all users
- **Purchase Type**: 'free'

## Enrollment Logic

### Current Backend Response
```json
{
  "id": 1,
  "topic_id": 5,
  "user_id": 10,
  "enrolled_at": "2024-12-21T10:30:00Z",
  "purchase_type": "bundle",
  "category_id": 3,
  "include_future_topics": true
}
```

### Recommended Backend Changes
Add these fields to enrollment response:
```json
{
  "id": 1,
  "topic_id": 5,
  "user_id": 10,
  "enrolled_at": "2024-12-21T10:30:00Z",
  "purchase_type": "bundle",  // NEW: 'bundle' | 'individual' | 'free'
  "category_id": 3,           // NEW: null for individual/free
  "include_future_topics": true,  // NEW: true for bundles, false for individual
  "topic_created_at": "2024-12-20T00:00:00Z"  // NEW: When topic was created
}
```

## Access Check Logic (Mobile App)

### Current Logic
```dart
// Topics are accessible if user is enrolled
bool isAccessible = topic.isEnrolled;
```

### New Logic Required
```dart
bool hasAccess(CourseTopic topic, EnrollmentRecord enrollment) {
  // Free topics always accessible
  if (topic.isFree) return true;
  
  // If no enrollment record
  if (enrollment == null) return false;
  
  // If purchased as individual topic
  if (enrollment.purchaseType == 'individual') {
    // Access only if it's the exact topic
    return enrollment.topicId == topic.id;
  }
  
  // If purchased as bundle
  if (enrollment.purchaseType == 'bundle') {
    // Check if topic is in the same category
    if (enrollment.categoryId != topic.categoryId) {
      return false;
    }
    
    // If bundle includes future topics
    if (enrollment.includeFutureTopics) {
      // Access all topics in category (including new ones)
      return true;
    } else {
      // Access only topics that existed at time of purchase
      return topic.createdAt <= enrollment.enrollmentDate;
    }
  }
  
  return false;
}
```

## Data Model Changes

### 1. Update CourseTopic Model
Add:
```dart
final DateTime? createdAt;  // When topic was created
```

### 2. Create EnrollmentRecord Model
```dart
class EnrollmentRecord {
  final int id;
  final int topicId;
  final int userId;
  final DateTime enrolledAt;
  final String purchaseType;  // 'bundle' | 'individual' | 'free'
  final int? categoryId;      // Only for bundle
  final bool includeFutureTopics;  // True for bundle, false for individual
  
  EnrollmentRecord({...});
  
  factory EnrollmentRecord.fromJson(Map<String, dynamic> json) {...}
}
```

## API Endpoints Needed

### 1. Create Bundle Purchase
```
POST /enrollments/purchase-bundle
{
  "userId": 10,
  "categoryId": 3,
  "purchaseType": "bundle"
}

Response:
{
  "success": true,
  "message": "Bundle purchased successfully",
  "enrollmentIds": [1, 2, 3, 4, 5]  // All topic enrollments
}
```

### 2. Create Individual Purchase
```
POST /enrollments/purchase-individual
{
  "userId": 10,
  "topicId": 5,
  "purchaseType": "individual"
}

Response:
{
  "success": true,
  "enrollmentId": 1
}
```

### 3. Get User Enrollments with Details
```
GET /enrollments/user/:userId

Response: [
  {
    "id": 1,
    "topic_id": 5,
    "purchase_type": "bundle",
    "category_id": 3,
    "include_future_topics": true,
    "enrolled_at": "2024-12-21T10:30:00Z"
  },
  ...
]
```

## Mobile App Implementation Plan

### Phase 1: Data Models
- [ ] Update CourseTopic with `createdAt` field
- [ ] Create EnrollmentRecord model
- [ ] Update api_client.dart to parse new fields

### Phase 2: Access Logic
- [ ] Create `AccessValidator` service
- [ ] Implement `hasAccessToTopic(topic, enrollment)` method
- [ ] Add helper: `canAccessFutureTopics(enrollment)`

### Phase 3: Purchase Flow
- [ ] Update purchase endpoints in api_client.dart
- [ ] Create `BundlePurchaseService`
- [ ] Handle bundle purchase in topic detail screen
- [ ] Implement category-based bundle purchase

### Phase 4: UI Updates
- [ ] Show "Bundle" badge on topics purchased via bundle
- [ ] Show "Individual" badge on individually purchased topics
- [ ] Show purchase type in enrollment status

## Testing Scenarios

1. **Bundle Purchase Test**
   - Buy bundle for category X
   - Verify access to all topics in category X
   - Add new topic to category X
   - Verify automatic access to new topic

2. **Individual Purchase Test**
   - Buy individual topic from category X
   - Verify access only to that topic
   - Add new topic to category X
   - Verify NO access to new topic

3. **Mixed Purchases Test**
   - Buy bundle for category X
   - Buy individual topic from category Y
   - Verify correct access for each

4. **Free Topics Test**
   - Free topics always accessible
   - No enrollment needed
