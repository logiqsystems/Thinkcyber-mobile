import 'package:flutter_test/flutter_test.dart';
import '../lib/services/api_client.dart';
import '../lib/services/enrollment_service.dart';
import '../lib/utils/topic_access_validator.dart';

void main() {
  group('Bundle Purchase Business Logic Tests', () {
    late EnrollmentService enrollmentService;
    late TopicAccessValidator accessValidator;

    setUp(() {
      enrollmentService = EnrollmentService();
      accessValidator = TopicAccessValidator();
    });

    group('Bundle Purchases with Future Topics', () {
      test('User can access existing topic in bundled category', () {
        // Arrange
        final purchaseDate = DateTime(2024, 12, 21);
        final topicCreateDate = DateTime(2024, 12, 20);

        final bundle = EnrollmentRecord(
          id: 1,
          topicId: 0, // Not used for bundles
          userId: 10,
          enrolledAt: purchaseDate,
          purchaseType: PurchaseType.bundle,
          categoryId: 3,
          includeFutureTopics: true,
          topicCreatedAt: null,
        );

        final topic = CourseTopic(
          id: 5,
          title: 'Authentication',
          description: 'Learn about auth',
          categoryId: 3,
          categoryName: 'Security',
          subcategoryId: null,
          subcategoryName: null,
          difficulty: 'Intermediate',
          status: 'published',
          isFree: false,
          isFeatured: false,
          price: 499,
          durationMinutes: 120,
          thumbnailUrl: 'https://example.com/image.jpg',
          isEnrolled: true,
        );

        // Act
        final canAccess =
            enrollmentService.hasAccessToTopic(
          topic: topic,
          enrollments: [bundle],
        );

        // Assert
        expect(canAccess, isTrue,
            reason:
                'User should access existing topic in bundled category');
      });

      test('User can access new topic added after bundle purchase', () {
        // Arrange
        final purchaseDate = DateTime(2024, 12, 21);
        final topicCreateDate = DateTime(2024, 12, 22); // Added AFTER purchase

        final bundle = EnrollmentRecord(
          id: 1,
          topicId: 0,
          userId: 10,
          enrolledAt: purchaseDate,
          purchaseType: PurchaseType.bundle,
          categoryId: 3,
          includeFutureTopics: true, // KEY: Future topics included
          topicCreatedAt: null,
        );

        final newTopic = CourseTopic(
          id: 6,
          title: 'Advanced Security',
          description: 'Advanced security concepts',
          categoryId: 3,
          categoryName: 'Security',
          subcategoryId: null,
          subcategoryName: null,
          difficulty: 'Advanced',
          status: 'published',
          isFree: false,
          isFeatured: false,
          price: 599,
          durationMinutes: 180,
          thumbnailUrl: 'https://example.com/image.jpg',
          isEnrolled: true,
        );

        // Act
        final canAccess = enrollmentService.hasAccessToTopic(
          topic: newTopic,
          enrollments: [bundle],
        );

        // Assert
        expect(canAccess, isTrue,
            reason:
                'User with future topics included should access new topics');
      });
    });

    group('Individual Purchases (No Future Topics)', () {
      test('User can access purchased individual topic', () {
        // Arrange
        final individual = EnrollmentRecord(
          id: 2,
          topicId: 5,
          userId: 10,
          enrolledAt: DateTime(2024, 12, 21),
          purchaseType: PurchaseType.individual,
          categoryId: null, // Not used for individual
          includeFutureTopics: false,
          topicCreatedAt: null,
        );

        final purchasedTopic = CourseTopic(
          id: 5,
          title: 'Authentication',
          description: 'Learn about auth',
          categoryId: 3,
          categoryName: 'Security',
          subcategoryId: null,
          subcategoryName: null,
          difficulty: 'Intermediate',
          status: 'published',
          isFree: false,
          isFeatured: false,
          price: 499,
          durationMinutes: 120,
          thumbnailUrl: 'https://example.com/image.jpg',
          isEnrolled: true,
        );

        // Act
        final canAccess = enrollmentService.hasAccessToTopic(
          topic: purchasedTopic,
          enrollments: [individual],
        );

        // Assert
        expect(canAccess, isTrue,
            reason: 'User should access individually purchased topic');
      });

      test('User cannot access other topics in same category', () {
        // Arrange
        final individual = EnrollmentRecord(
          id: 2,
          topicId: 5,
          userId: 10,
          enrolledAt: DateTime(2024, 12, 21),
          purchaseType: PurchaseType.individual,
          categoryId: null,
          includeFutureTopics: false,
          topicCreatedAt: null,
        );

        final otherTopic = CourseTopic(
          id: 6,
          title: 'Encryption',
          description: 'Learn about encryption',
          categoryId: 3, // Same category
          categoryName: 'Security',
          subcategoryId: null,
          subcategoryName: null,
          difficulty: 'Advanced',
          status: 'published',
          isFree: false,
          isFeatured: false,
          price: 599,
          durationMinutes: 180,
          thumbnailUrl: 'https://example.com/image.jpg',
          isEnrolled: false,
        );

        // Act
        final canAccess = enrollmentService.hasAccessToTopic(
          topic: otherTopic,
          enrollments: [individual],
        );

        // Assert
        expect(canAccess, isFalse,
            reason:
                'User should not access other topics with individual purchase');
      });
    });

    group('Free Topics', () {
      test('Free topic is always accessible', () {
        // Arrange
        final freeTopic = CourseTopic(
          id: 1,
          title: 'Free Introduction',
          description: 'Free intro course',
          categoryId: 1,
          categoryName: 'Basics',
          subcategoryId: null,
          subcategoryName: null,
          difficulty: 'Beginner',
          status: 'published',
          isFree: true,
          isFeatured: false,
          price: 0,
          durationMinutes: 30,
          thumbnailUrl: 'https://example.com/image.jpg',
        );

        // Act
        final canAccess = enrollmentService.hasAccessToTopic(
          topic: freeTopic,
          enrollments: [],
        );

        // Assert
        expect(canAccess, isTrue, reason: 'Free topics should always be accessible');
      });
    });

    group('Access Status Details', () {
      test('Get detailed status for bundle purchase', () {
        // Arrange
        final bundle = EnrollmentRecord(
          id: 1,
          topicId: 0,
          userId: 10,
          enrolledAt: DateTime(2024, 12, 21),
          purchaseType: PurchaseType.bundle,
          categoryId: 3,
          includeFutureTopics: true,
          topicCreatedAt: null,
        );

        final topic = CourseTopic(
          id: 5,
          title: 'Authentication',
          description: 'Learn about auth',
          categoryId: 3,
          categoryName: 'Security',
          subcategoryId: null,
          subcategoryName: null,
          difficulty: 'Intermediate',
          status: 'published',
          isFree: false,
          isFeatured: false,
          price: 499,
          durationMinutes: 120,
          thumbnailUrl: 'https://example.com/image.jpg',
        );

        // Act
        final status = accessValidator.getAccessStatus(
          topic: topic,
          enrollments: [bundle],
        );

        // Assert
        expect(status.hasAccess, isTrue);
        expect(status.enrollmentType, equals('bundle'));
        expect(status.reason, contains('bundle'));
      });

      test('Get detailed status for no access', () {
        // Arrange
        final topic = CourseTopic(
          id: 5,
          title: 'Authentication',
          description: 'Learn about auth',
          categoryId: 3,
          categoryName: 'Security',
          subcategoryId: null,
          subcategoryName: null,
          difficulty: 'Intermediate',
          status: 'published',
          isFree: false,
          isFeatured: false,
          price: 499,
          durationMinutes: 120,
          thumbnailUrl: 'https://example.com/image.jpg',
        );

        // Act
        final status = accessValidator.getAccessStatus(
          topic: topic,
          enrollments: [],
        );

        // Assert
        expect(status.hasAccess, isFalse);
        expect(status.reason, equals('not_enrolled'));
      });
    });

    group('Purchase Options', () {
      test('Generate purchase options for free topic', () {
        // Arrange
        final freeTopic = CourseTopic(
          id: 1,
          title: 'Free Intro',
          description: 'Free intro',
          categoryId: 1,
          categoryName: 'Basics',
          subcategoryId: null,
          subcategoryName: null,
          difficulty: 'Beginner',
          status: 'published',
          isFree: true,
          isFeatured: false,
          price: 0,
          durationMinutes: 30,
          thumbnailUrl: 'https://example.com/image.jpg',
        );

        // Act
        final options = accessValidator.getPurchaseOptions(
          topic: freeTopic,
          bundlePrice: 0,
        );

        // Assert
        expect(options.length, equals(1));
        expect(options.first.type, equals('enroll_free'));
        expect(options.first.price, equals(0));
      });

      test('Generate purchase options for paid topic', () {
        // Arrange
        final paidTopic = CourseTopic(
          id: 5,
          title: 'Authentication',
          description: 'Learn auth',
          categoryId: 3,
          categoryName: 'Security',
          subcategoryId: null,
          subcategoryName: null,
          difficulty: 'Intermediate',
          status: 'published',
          isFree: false,
          isFeatured: false,
          price: 499,
          durationMinutes: 120,
          thumbnailUrl: 'https://example.com/image.jpg',
        );

        // Act
        final options = accessValidator.getPurchaseOptions(
          topic: paidTopic,
          bundlePrice: 1999,
        );

        // Assert
        expect(options.length, equals(2)); // Individual + Bundle
        expect(options[0].type, equals('individual'));
        expect(options[0].price, equals(499));
        expect(options[1].type, equals('bundle'));
        expect(options[1].price, equals(1999));
      });
    });

    group('Bundle Eligibility', () {
      test('User cannot purchase bundle if already owns it', () {
        // Arrange
        final existingBundle = EnrollmentRecord(
          id: 1,
          topicId: 0,
          userId: 10,
          enrolledAt: DateTime(2024, 12, 21),
          purchaseType: PurchaseType.bundle,
          categoryId: 3,
          includeFutureTopics: true,
          topicCreatedAt: null,
        );

        // Act
        final canPurchase = accessValidator.canPurchaseBundle(
          categoryId: 3,
          enrollments: [existingBundle],
        );

        // Assert
        expect(canPurchase, isFalse, reason: 'User cannot purchase same bundle twice');
      });

      test('User can purchase bundle for different category', () {
        // Arrange
        final bundleCategory3 = EnrollmentRecord(
          id: 1,
          topicId: 0,
          userId: 10,
          enrolledAt: DateTime(2024, 12, 21),
          purchaseType: PurchaseType.bundle,
          categoryId: 3,
          includeFutureTopics: true,
          topicCreatedAt: null,
        );

        // Act
        final canPurchase = accessValidator.canPurchaseBundle(
          categoryId: 4, // Different category
          enrollments: [bundleCategory3],
        );

        // Assert
        expect(canPurchase, isTrue,
            reason: 'User can purchase bundles for different categories');
      });

      test('User cannot purchase bundle if has individual purchase in same category (Flexible Plan)', () {
        // Arrange - User bought a single topic individually in category 3
        final individualPurchase = EnrollmentRecord(
          id: 1,
          topicId: 5,
          userId: 10,
          enrolledAt: DateTime(2024, 12, 21),
          purchaseType: PurchaseType.individual,
          categoryId: 3,  // Same category
          includeFutureTopics: false,
          topicCreatedAt: null,
        );

        // Act
        final canPurchase = accessValidator.canPurchaseBundle(
          categoryId: 3,
          enrollments: [individualPurchase],
        );

        // Assert
        expect(canPurchase, isFalse, 
            reason: 'User with individual purchase in flexible plan cannot buy bundle for same category');
      });

      test('User can purchase bundle for different category even with individual purchase', () {
        // Arrange - User bought individual topic in category 3
        final individualPurchase = EnrollmentRecord(
          id: 1,
          topicId: 5,
          userId: 10,
          enrolledAt: DateTime(2024, 12, 21),
          purchaseType: PurchaseType.individual,
          categoryId: 3,
          includeFutureTopics: false,
          topicCreatedAt: null,
        );

        // Act - Try to buy bundle for category 4
        final canPurchase = accessValidator.canPurchaseBundle(
          categoryId: 4,  // Different category
          enrollments: [individualPurchase],
        );

        // Assert
        expect(canPurchase, isTrue,
            reason: 'User can purchase bundle for different category');
      });

      test('User with individual purchase can check hasIndividualPurchaseInCategory', () {
        // Arrange
        final individualPurchase = EnrollmentRecord(
          id: 1,
          topicId: 5,
          userId: 10,
          enrolledAt: DateTime(2024, 12, 21),
          purchaseType: PurchaseType.individual,
          categoryId: 3,
          includeFutureTopics: false,
          topicCreatedAt: null,
        );

        // Act
        final hasIndividual = accessValidator.hasIndividualPurchaseInCategory(
          categoryId: 3,
          enrollments: [individualPurchase],
        );

        // Assert
        expect(hasIndividual, isTrue,
            reason: 'Should detect individual purchase in category');
      });
    });

    group('Free Topics', () {
      test('Free topic is always accessible without enrollment', () {
        // Arrange
        final freeTopic = CourseTopic(
          id: 1,
          title: 'Intro to Cybersecurity',
          description: 'Free introduction',
          categoryId: 1,
          categoryName: 'Basics',
          subcategoryId: null,
          subcategoryName: null,
          difficulty: 'Beginner',
          status: 'published',
          isFree: true,  // FREE topic
          isFeatured: false,
          price: 0,
          durationMinutes: 30,
          thumbnailUrl: 'https://example.com/image.jpg',
        );

        // Act
        final canAccess = enrollmentService.hasAccessToTopic(
          topic: freeTopic,
          enrollments: [],  // No enrollments
        );

        // Assert
        expect(canAccess, isTrue, reason: 'Free topics should always be accessible');
      });

      test('Free topic access status shows correct reason', () {
        // Arrange
        final freeTopic = CourseTopic(
          id: 1,
          title: 'Intro to Cybersecurity',
          description: 'Free introduction',
          categoryId: 1,
          categoryName: 'Basics',
          subcategoryId: null,
          subcategoryName: null,
          difficulty: 'Beginner',
          status: 'published',
          isFree: true,
          isFeatured: false,
          price: 0,
          durationMinutes: 30,
          thumbnailUrl: 'https://example.com/image.jpg',
        );

        // Act
        final status = accessValidator.getAccessStatus(
          topic: freeTopic,
          enrollments: [],
        );

        // Assert
        expect(status.hasAccess, isTrue);
        expect(status.reason, equals('free_topic'));
      });
    });

    group('Flexible Plan Scenarios', () {
      test('Individual purchase gives access only to that topic', () {
        // Arrange
        final individualEnrollment = EnrollmentRecord(
          id: 1,
          topicId: 5,
          userId: 10,
          enrolledAt: DateTime(2024, 12, 21),
          purchaseType: PurchaseType.individual,
          categoryId: 3,
          includeFutureTopics: false,
          topicCreatedAt: null,
        );

        final purchasedTopic = CourseTopic(
          id: 5,  // Same as enrollment
          title: 'Authentication',
          description: 'Auth topic',
          categoryId: 3,
          categoryName: 'Security',
          subcategoryId: null,
          subcategoryName: null,
          difficulty: 'Intermediate',
          status: 'published',
          isFree: false,
          isFeatured: false,
          price: 499,
          durationMinutes: 120,
          thumbnailUrl: 'https://example.com/image.jpg',
        );

        final otherTopic = CourseTopic(
          id: 6,  // Different topic in same category
          title: 'Authorization',
          description: 'Auth topic',
          categoryId: 3,
          categoryName: 'Security',
          subcategoryId: null,
          subcategoryName: null,
          difficulty: 'Intermediate',
          status: 'published',
          isFree: false,
          isFeatured: false,
          price: 499,
          durationMinutes: 120,
          thumbnailUrl: 'https://example.com/image.jpg',
        );

        // Act
        final canAccessPurchased = enrollmentService.hasAccessToTopic(
          topic: purchasedTopic,
          enrollments: [individualEnrollment],
        );
        final canAccessOther = enrollmentService.hasAccessToTopic(
          topic: otherTopic,
          enrollments: [individualEnrollment],
        );

        // Assert
        expect(canAccessPurchased, isTrue, 
            reason: 'Should access the purchased topic');
        expect(canAccessOther, isFalse, 
            reason: 'Should NOT access other topics in same category');
      });

      test('Bundle purchase gives access to all topics in category', () {
        // Arrange
        final bundleEnrollment = EnrollmentRecord(
          id: 1,
          topicId: 0,
          userId: 10,
          enrolledAt: DateTime(2024, 12, 21),
          purchaseType: PurchaseType.bundle,
          categoryId: 3,
          includeFutureTopics: true,
          topicCreatedAt: null,
        );

        final topic1 = CourseTopic(
          id: 5,
          title: 'Authentication',
          description: 'Auth topic',
          categoryId: 3,
          categoryName: 'Security',
          subcategoryId: null,
          subcategoryName: null,
          difficulty: 'Intermediate',
          status: 'published',
          isFree: false,
          isFeatured: false,
          price: 499,
          durationMinutes: 120,
          thumbnailUrl: 'https://example.com/image.jpg',
        );

        final topic2 = CourseTopic(
          id: 6,
          title: 'Authorization',
          description: 'Auth topic',
          categoryId: 3,
          categoryName: 'Security',
          subcategoryId: null,
          subcategoryName: null,
          difficulty: 'Intermediate',
          status: 'published',
          isFree: false,
          isFeatured: false,
          price: 499,
          durationMinutes: 120,
          thumbnailUrl: 'https://example.com/image.jpg',
        );

        // Act
        final canAccessTopic1 = enrollmentService.hasAccessToTopic(
          topic: topic1,
          enrollments: [bundleEnrollment],
        );
        final canAccessTopic2 = enrollmentService.hasAccessToTopic(
          topic: topic2,
          enrollments: [bundleEnrollment],
        );

        // Assert
        expect(canAccessTopic1, isTrue, reason: 'Should access topic 1 in bundle');
        expect(canAccessTopic2, isTrue, reason: 'Should access topic 2 in bundle');
      });

      test('Bundle does not give access to topics in other categories', () {
        // Arrange
        final bundleEnrollment = EnrollmentRecord(
          id: 1,
          topicId: 0,
          userId: 10,
          enrolledAt: DateTime(2024, 12, 21),
          purchaseType: PurchaseType.bundle,
          categoryId: 3,  // Security category
          includeFutureTopics: true,
          topicCreatedAt: null,
        );

        final otherCategoryTopic = CourseTopic(
          id: 10,
          title: 'Networking Basics',
          description: 'Networking topic',
          categoryId: 4,  // Different category
          categoryName: 'Networking',
          subcategoryId: null,
          subcategoryName: null,
          difficulty: 'Beginner',
          status: 'published',
          isFree: false,
          isFeatured: false,
          price: 399,
          durationMinutes: 90,
          thumbnailUrl: 'https://example.com/image.jpg',
        );

        // Act
        final canAccess = enrollmentService.hasAccessToTopic(
          topic: otherCategoryTopic,
          enrollments: [bundleEnrollment],
        );

        // Assert
        expect(canAccess, isFalse, 
            reason: 'Bundle should not give access to other categories');
      });
    });
  });
}
