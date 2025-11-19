import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_client.dart';
import '../services/wishlist_store.dart';
import '../widgets/topic_visuals.dart';
import '../widgets/translated_text.dart';
import 'topic_detail_screen.dart';

const _pageBackground = Color(0xFFF5F7FA);
const _cardBackground = Colors.white;
const _textColor = Color(0xFF1F2937);
const _mutedColor = Color(0xFF6B7280);
const _accentColor = Color(0xFF2E7DFF);
const _shadowColor = Color(0x11000000);

String _truncateDescription(String description, int maxLength) {
  if (description.length <= maxLength) {
    return description;
  }
  
  // Find the last complete word within the limit
  String truncated = description.substring(0, maxLength);
  int lastSpace = truncated.lastIndexOf(' ');
  
  if (lastSpace > 0) {
    truncated = truncated.substring(0, lastSpace);
  }
  
  return '$truncated...';
}

class AllCoursesScreen extends StatefulWidget {
  const AllCoursesScreen({super.key});

  @override
  State<AllCoursesScreen> createState() => _AllCoursesScreenState();
}

class _AllCoursesScreenState extends State<AllCoursesScreen> {
  final ThinkCyberApi _api = ThinkCyberApi();
  final WishlistStore _wishlist = WishlistStore.instance;
  late final VoidCallback _wishlistListener;
  List<CourseTopic> _courses = const [];
  List<CourseTopic> _freeCourses = const [];
  List<CourseTopic> _paidCourses = const [];
  List<CourseTopic> _enrolledCourses = const [];
  bool _loading = true;
  String? _error;
  bool _enrollmentsLoading = false;
  String? _enrollmentsError;
  int? _userId;

  @override
  void initState() {
    super.initState();
    _loadCourses();
    _loadEnrollments();
    _wishlistListener = () {
      if (mounted) setState(() {});
    };
    _wishlist.addListener(_wishlistListener);
    _wishlist.hydrate();
  }

  @override
  void dispose() {
    _api.dispose();
    _wishlist.removeListener(_wishlistListener);
    super.dispose();
  }

  Future<void> _loadCourses({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final storedUserId = prefs.getInt('thinkcyber_user_id');

      final response = await _api.fetchTopics(userId: storedUserId);
      if (!mounted) return;
      setState(() {
        _courses = response.topics;
        _freeCourses = _courses.where((c) => c.isFree || c.price == 0).toList();
        _paidCourses = _courses.where((c) => !(c.isFree || c.price == 0)).toList();
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load courses right now. Please try again shortly.';
        _loading = false;
      });
    }
  }

  Future<void> _loadEnrollments({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        _enrollmentsLoading = true;
        _enrollmentsError = null;
      });
    } else {
      setState(() {
        _enrollmentsError = null;
      });
    }

    final prefs = await SharedPreferences.getInstance();
    final storedUserId = prefs.getInt('thinkcyber_user_id');
    if (!mounted) return;

    if (storedUserId == null || storedUserId <= 0) {
      setState(() {
        _userId = null;
        _enrolledCourses = const [];
        _enrollmentsLoading = false;
      });
      return;
    }

    try {
      final courses = await _api.fetchUserEnrollments(userId: storedUserId);
      if (!mounted) return;
      setState(() {
        _userId = storedUserId;
        _enrolledCourses = courses;
        _enrollmentsLoading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _userId = storedUserId;
        _enrollmentsError = error.message;
        _enrollmentsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _userId = storedUserId;
        _enrollmentsError =
            'Unable to load enrollments right now. Please try again.';
        _enrollmentsLoading = false;
      });
    }
  }

  Widget _buildGrid(
    List<CourseTopic> courses, {
    Future<void> Function()? onRefresh,
    Widget? emptyState,
  }) {
    if (courses.isEmpty) {
      return emptyState ?? const _EmptyState();
    }

    return RefreshIndicator(
      onRefresh: onRefresh ?? () => _loadCourses(showLoader: false),
      color: _accentColor,
      child: GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: courses.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 0.78,
        ),
        itemBuilder: (context, index) {
          final course = courses[index];
          return _CourseCard(
            course: course,
            isWishlisted: _wishlist.contains(course.id),
            onToggleWishlist: () async {
              final messenger = ScaffoldMessenger.of(context);
              final added = await _wishlist.toggleCourse(summary: course);
              if (!mounted) return;
              messenger.showSnackBar(
                SnackBar(
                  content: TranslatedText(
                    added ? 'Added to wishlist' : 'Removed from wishlist',
                  ),
                ),
              );
            },
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => TopicDetailScreen(topic: course),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: _pageBackground,
        appBar: AppBar(
          title: const TranslatedText('All Topics'),
          backgroundColor: _pageBackground,
          foregroundColor: _textColor,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: _accentColor),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: _pageBackground,
        appBar: AppBar(
          title: const TranslatedText('All Topics'),
          backgroundColor: _pageBackground,
          foregroundColor: _textColor,
          elevation: 0,
        ),
        body: _CoursesError(message: _error!, onRetry: _loadCourses),
      );
    }

    if (_courses.isEmpty) {
      return Scaffold(
        backgroundColor: _pageBackground,
        appBar: AppBar(
          title: const TranslatedText('All Topics'),
          backgroundColor: _pageBackground,
          foregroundColor: _textColor,
          elevation: 0,
        ),
        body: const _EmptyState(),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: _pageBackground,
        appBar: AppBar(
          title: const TranslatedText('All Topics'),
          backgroundColor: _pageBackground,
          foregroundColor: _textColor,
          surfaceTintColor: Colors.transparent, // removes default Material3 tint line

          elevation: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(52),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(25),
              ),

              child: TabBar(
                 indicatorSize: TabBarIndicatorSize.tab, // 🔥 makes indicator match tab width

                labelColor: Colors.white,
                unselectedLabelColor: _mutedColor,
                indicator: BoxDecoration(
                  color: _accentColor,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                tabs: [
                  Tab(child: TranslatedText('Free (${_freeCourses.length})')),
                  Tab(child: TranslatedText('Paid (${_paidCourses.length})')),
                  Tab(
                    child: TranslatedText(_userId == null
                        ? 'Enrollments'
                        : 'Enrollments (${_enrolledCourses.length})'),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _buildGrid(_freeCourses),
            _buildGrid(_paidCourses),
            _buildEnrollmentsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildEnrollmentsTab() {
    if (_enrollmentsLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _accentColor),
      );
    }

    if (_userId == null) {
      return const _EnrollmentsSignInPrompt();
    }

    if (_enrollmentsError != null) {
      return _CoursesError(
        message: _enrollmentsError!,
        onRetry: ({bool showLoader = true}) =>
            _loadEnrollments(showLoader: showLoader),
      );
    }

    return _buildGrid(
      _enrolledCourses,
      onRefresh: () => _loadEnrollments(showLoader: false),
      emptyState: const _EnrollmentsEmptyState(),
    );
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({
    required this.course,
    required this.isWishlisted,
    required this.onToggleWishlist,
    required this.onTap,
  });

  final CourseTopic course;
  final bool isWishlisted;
  final Future<void> Function() onToggleWishlist;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isFree = course.isFree || course.price == 0;
    final bool isOwned = course.isEnrolled;

    String priceText(num value) {
      if (value % 1 == 0) {
        return '₹${value.toInt()}';
      }
      return '₹${value.toStringAsFixed(2)}';
    }

    final String priceLabel = isOwned
        ? 'Enrolled'
        : (isFree ? 'Free' : priceText(course.price));
    final Color priceColor = isOwned
        ? const Color(0xFF22C55E)
        : (isFree ? const Color(0xFF10B981) : _accentColor);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _cardBackground,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: _shadowColor,
              blurRadius: 12,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail with price + wishlist
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                  child: SizedBox(
                    height: 110,
                    width: double.infinity,
                    child: TopicImage(
                      imageUrl: course.thumbnailUrl,
                      title: course.title,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: priceColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1A000000),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      priceLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 10,
                  top: 10,
                  child: _WishlistPill(
                    isActive: isWishlisted,
                    onToggle: onToggleWishlist,
                  ),
                ),
              ],
            ),
            // Info section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TranslatedText(
                      course.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _textColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TranslatedText(
                      course.categoryName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _mutedColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: TranslatedText(
                        _truncateDescription(
                          course.description.isNotEmpty
                              ? course.description
                              : 'Learn ${course.categoryName.toLowerCase()} fundamentals',
                          100,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _mutedColor,
                          fontSize: 10,
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: _accentColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: TranslatedText(
                            course.difficulty.toUpperCase(),
                            style: const TextStyle(
                              color: _accentColor,
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.schedule_outlined, 
                              size: 11, 
                              color: _mutedColor.withOpacity(0.7),
                            ),
                            const SizedBox(width: 3),
                            TranslatedText(
                              course.durationMinutes > 0
                                  ? '${course.durationMinutes}m'
                                  : 'Self',
                              style: const TextStyle(
                                color: _mutedColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}



class _WishlistPill extends StatelessWidget {
  const _WishlistPill({required this.isActive, required this.onToggle});
  final bool isActive;
  final Future<void> Function() onToggle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onToggle(),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          isActive ? Icons.favorite : Icons.favorite_border,
          size: 16,
          color: isActive ? const Color(0xFFEF4444) : _mutedColor.withOpacity(0.6),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cast_for_education_outlined,
                size: 64, color: _mutedColor),
            const SizedBox(height: 16),
            const TranslatedText(
              'Courses will appear here soon',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _textColor,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const TranslatedText(
              'Looks like the catalogue is still loading. Pull down to refresh.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _mutedColor,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EnrollmentsEmptyState extends StatelessWidget {
  const _EnrollmentsEmptyState();

  @override
  Widget build(BuildContext context) {
    return const _EnrollmentsMessage(
      icon: Icons.school_outlined,
      title: 'No enrollments yet',
      subtitle: 'Start your learning journey by enrolling in a course.',
    );
  }
}

class _EnrollmentsSignInPrompt extends StatelessWidget {
  const _EnrollmentsSignInPrompt();

  @override
  Widget build(BuildContext context) {
    return const _EnrollmentsMessage(
      icon: Icons.lock_outline,
      title: 'Sign in to view enrollments',
      subtitle: 'Log in to keep track of the courses you have joined.',
    );
  }
}

class _EnrollmentsMessage extends StatelessWidget {
  const _EnrollmentsMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: _mutedColor),
            const SizedBox(height: 16),
            TranslatedText(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _textColor,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            TranslatedText(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _mutedColor,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoursesError extends StatelessWidget {
  const _CoursesError({required this.message, required this.onRetry});
  final String message;
  final Future<void> Function({bool showLoader}) onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 64, color: _mutedColor),
            const SizedBox(height: 16),
            TranslatedText(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _textColor,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => onRetry(showLoader: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              label: const TranslatedText('Try again',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
