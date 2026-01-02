import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_client.dart';
import '../services/wishlist_store.dart';
import '../widgets/topic_visuals.dart';
import '../widgets/translated_text.dart';
import 'topic_detail_screen.dart';
import 'bundle_topics_detail_screen.dart';

const _pageBackground = Color(0xFFF8FAFC);
const _cardBackground = Colors.white;
const _textColor = Color(0xFF1F2937);
const _mutedColor = Color(0xFF6B7280);
const _accentColor = Color(0xFF2E7DFF);
const _shadowColor = Color(0x11000000);

String _truncateDescription(String description, int maxLength) {
  if (description.length <= maxLength) {
    return description;
  }

  String truncated = description.substring(0, maxLength);
  int lastSpace = truncated.lastIndexOf(' ');

  if (lastSpace > 0) {
    truncated = truncated.substring(0, lastSpace);
  }

  return '$truncated...';
}

class AllCoursesController {
  void Function(int)? _switchToTab;

  void switchToTab(int index) {
    _switchToTab?.call(index);
  }

  void _attach(void Function(int) callback) {
    _switchToTab = callback;
  }

  void _detach() {
    _switchToTab = null;
  }
}

class AllCoursesScreen extends StatefulWidget {
  const AllCoursesScreen({
    super.key,
    this.initialTabIndex = 0,
    this.controller,
    this.initialCategoryName,
  });

  final int initialTabIndex;
  final AllCoursesController? controller;
  final String? initialCategoryName;

  @override
  State<AllCoursesScreen> createState() => _AllCoursesScreenState();
}

class _AllCoursesScreenState extends State<AllCoursesScreen>
    with TickerProviderStateMixin {
  final ThinkCyberApi _api = ThinkCyberApi();
  final WishlistStore _wishlist = WishlistStore.instance;
  late final VoidCallback _wishlistListener;
  late TabController _tabController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  String? _categoryFilter;

  List<CourseTopic> _courses = const [];
  List<CourseTopic> _freeCourses = const [];
  List<CourseTopic> _paidCourses = const [];
  List<CourseTopic> _enrolledCourses = const [];
  List<UserBundle> _userBundles = const [];
  bool _loading = true;
  String? _error;
  bool _enrollmentsLoading = false;
  String? _enrollmentsError;
  int? _userId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _tabController.addListener(_onTabChanged);
    _loadCourses();
    _loadEnrollments();
    _wishlistListener = () {
      if (mounted) setState(() {});
    };
    _wishlist.addListener(_wishlistListener);
    _wishlist.hydrate();

    widget.controller?._attach(_switchToTab);

    _categoryFilter = widget.initialCategoryName;
  }

  void switchToTab(int index) {
    _switchToTab(index);
  }

  void _switchToTab(int index) {
    if (index >= 0 && index < 3 && mounted) {
      _tabController.animateTo(index);
    }
  }

  List<CourseTopic> _applyCategoryFilter(List<CourseTopic> list) {
    if (_categoryFilter == null || _categoryFilter!.isEmpty) return list;
    return list.where((c) => c.categoryName == _categoryFilter).toList();
  }

  void _onTabChanged() {
    if (_tabController.index == 2) {
      debugPrint('🔄 Enrollments tab selected, refreshing enrollments...');
      _loadEnrollments(showLoader: false);
    }
  }

  @override
  void dispose() {
    widget.controller?._detach();
    _api.dispose();
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _fadeController.dispose();
    _wishlist.removeListener(_wishlistListener);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AllCoursesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCategoryName != oldWidget.initialCategoryName) {
      setState(() {
        _categoryFilter = widget.initialCategoryName;
      });
    }
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

      final topicsResponse = await _api.fetchTopics(userId: storedUserId);
      List<CourseTopic> courses = topicsResponse.topics;

      final freeBundleCategoryIds = <int>{};
      if (storedUserId != null && storedUserId > 0) {
        try {
          final userBundles = await _api.fetchUserBundles(userId: storedUserId);
          freeBundleCategoryIds.addAll(
            userBundles
                .where((b) => b.planType.toUpperCase() == 'FREE')
                .map((b) => b.categoryId),
          );

          if (freeBundleCategoryIds.isNotEmpty) {
            courses = courses
                .map((course) => freeBundleCategoryIds.contains(course.categoryId)
                    ? course.copyWith(isFree: true, price: 0)
                    : course)
                .toList();
          }
        } catch (e) {
          debugPrint('Error loading user bundles for free topics: $e');
        }
      }

      // Debug: understand why topics land in the Free tab
      int byFlag = 0, byZeroPrice = 0, byBundle = 0, paidButMarkedFree = 0;
      for (final course in courses) {
        final bool bundleFree = freeBundleCategoryIds.contains(course.categoryId);
        final bool zeroPrice = course.price == 0;
        if (course.isFree) byFlag++;
        if (zeroPrice) byZeroPrice++;
        if (bundleFree) byBundle++;
        if (course.isFree && course.price > 0) {
          paidButMarkedFree++;
          debugPrint('⚠️  Paid price but flagged free: ${course.title} (price: ${course.price})');
        }
      }
      debugPrint('Free classification counts -> isFree flag: $byFlag, zero price: $byZeroPrice, free bundles: $byBundle, paid-but-flagged-free: $paidButMarkedFree');

      if (!mounted) return;
      setState(() {
        _courses = courses;
        _freeCourses = courses.where((c) => c.isFree || c.price == 0).toList();
        _paidCourses = courses.where((c) => !(c.isFree || c.price == 0)).toList();
        _loading = false;
      });
      _fadeController.forward();
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
      final bundles = await _api.fetchUserBundles(userId: storedUserId);
      if (!mounted) return;
      setState(() {
        _userId = storedUserId;
        _enrolledCourses = courses;
        _userBundles = bundles;
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
        bool hidePriceBadge = false,
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
          childAspectRatio: 0.75,
        ),
        itemBuilder: (context, index) {
          final course = courses[index];
          return _EnhancedCourseCard(
            course: course,
            isWishlisted: _wishlist.contains(course.id),
            hidePriceBadge: hidePriceBadge,
            index: index,
            onToggleWishlist: () async {
              final messenger = ScaffoldMessenger.of(context);
              final added = await _wishlist.toggleCourse(summary: course);
              if (!mounted) return;
              messenger.showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          added ? Icons.favorite : Icons.favorite_border,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TranslatedText(
                          added ? 'Added to wishlist' : 'Removed from wishlist',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: const Color(0xFF1F2937),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.all(16),
                ),
              );
            },
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TopicDetailScreen(
                    topic: course,
                    fromEnrollments: _tabController.index == 2,
                  ),
                ),
              );
              if (mounted && _tabController.index == 2) {
                debugPrint('🔄 Returning to Enrollments tab, refreshing...');
                _loadEnrollments(showLoader: false);
              }
            },
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
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF6366F1),
                Color(0xFF8B5CF6),
                Color(0xFFF8FAFC),
              ],
              stops: [0.0, 0.3, 0.6],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withOpacity(0.3),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: const CircularProgressIndicator(
                      color: Color(0xFF6366F1),
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Loading Courses...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: _pageBackground,
        appBar: _buildEnhancedAppBar(),
        body: _CoursesError(message: _error!, onRetry: _loadCourses),
      );
    }

    if (_courses.isEmpty) {
      return Scaffold(
        backgroundColor: _pageBackground,
        appBar: _buildEnhancedAppBar(),
        body: const _EmptyState(),
      );
    }

    final filteredFree = _applyCategoryFilter(_freeCourses);
    final filteredPaid = _applyCategoryFilter(_paidCourses);
    final hasCategoryFilter = _categoryFilter != null && _categoryFilter!.isNotEmpty;

    return Scaffold(
      backgroundColor: _pageBackground,
      appBar: _buildEnhancedAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            if (hasCategoryFilter)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _accentColor.withOpacity(0.15)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _accentColor.withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.filter_alt_rounded, color: _accentColor, size: 16),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TranslatedText(
                          'Showing topics in ${_categoryFilter!}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _textColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _categoryFilter = null;
                          });
                        },
                        icon: const Icon(Icons.close_rounded, size: 16),
                        label: const TranslatedText('Clear', style: TextStyle(fontWeight: FontWeight.w700)),
                        style: TextButton.styleFrom(
                          foregroundColor: _accentColor,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildGrid(filteredFree),
                  _buildGrid(filteredPaid),
                  _buildEnrollmentsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildEnhancedAppBar() {
    final freeCount = _applyCategoryFilter(_freeCourses).length;
    final paidCount = _applyCategoryFilter(_paidCourses).length;
    return AppBar(
      title: const TranslatedText(
        'All Topics',
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 24,
          letterSpacing: -0.5,
        ),
      ),
      backgroundColor: _pageBackground,
      foregroundColor: _textColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(68),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(4),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: _mutedColor,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2E7DFF), Color(0xFF1E5FDD)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: _accentColor.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                letterSpacing: 0.2,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              labelPadding: EdgeInsets.zero,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.card_giftcard, size: 16),
                      const SizedBox(width: 6),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: TranslatedText('Free ($freeCount)'),
                      ),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.diamond_outlined, size: 16),
                      const SizedBox(width: 6),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: TranslatedText('Paid ($paidCount)'),
                      ),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.school_outlined, size: 16),
                      const SizedBox(width: 6),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: TranslatedText(_userId == null
                            ? 'My Courses'
                            : 'My (${_enrolledCourses.length})'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnrollmentsTab() {
    if (_enrollmentsLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _accentColor.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const CircularProgressIndicator(color: _accentColor),
            ),
          ],
        ),
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

    if (_enrolledCourses.isEmpty) {
      return const _EnrollmentsEmptyState();
    }

    debugPrint('=== ALL ENROLLMENTS (${_enrolledCourses.length}) ===');
    for (int i = 0; i < _enrolledCourses.length; i++) {
      final e = _enrolledCourses[i];
      debugPrint('[$i] ${e.title} - categoryName: "${e.categoryName}" - price: ${e.price}');
    }
    debugPrint('=== ALL BUNDLES (${_userBundles.length}) ===');
    for (int i = 0; i < _userBundles.length; i++) {
      final b = _userBundles[i];
      debugPrint('[$i] ${b.categoryName} - planType: ${b.planType} - price: ${b.bundlePrice}');
    }

    final paidBundleEnrollments = _userBundles.where((b) =>
    b.planType == 'BUNDLE'
    ).toList();

    final flexibleBundleEnrollments = _userBundles.where((b) =>
    b.planType == 'FLEXIBLE'
    ).toList();

    var freeBundleEnrollments = _userBundles.where((b) =>
    b.planType == 'FREE'
    ).toList();

    final freeEnrollmentsWithCategory = _enrolledCourses.where((e) =>
    e.price == 0 && e.categoryName != null && e.categoryName!.isNotEmpty
    ).toList();

    final Map<String, List<CourseTopic>> freeByCategory = {};
    for (final e in freeEnrollmentsWithCategory) {
      final cat = e.categoryName ?? 'General';
      freeByCategory.putIfAbsent(cat, () => []).add(e);
    }

    for (final entry in freeByCategory.entries) {
      final firstTopic = entry.value.first;
      final virtualFreeBundle = UserBundle(
        id: -1,
        userId: _userId ?? 0,
        categoryId: firstTopic.categoryId,
        categoryName: entry.key,
        bundlePrice: 0,
        planType: 'FREE',
        paymentStatus: 'completed',
        enrolledAt: DateTime.now().toIso8601String(),
        futureTopicsIncluded: true,
        accessibleTopicsCount: entry.value.length,
        description: 'Free Plan',
      );

      if (!freeBundleEnrollments.any((b) => b.categoryId == firstTopic.categoryId)) {
        freeBundleEnrollments = [...freeBundleEnrollments, virtualFreeBundle];
      }
    }

    debugPrint('=== FILTERED BUNDLES ===');
    debugPrint('Paid Bundles: ${paidBundleEnrollments.length}');
    debugPrint('Flexible Bundles: ${flexibleBundleEnrollments.length}');
    debugPrint('Free Bundles (including virtual): ${freeBundleEnrollments.length}');
    for (var fb in freeBundleEnrollments) {
      debugPrint('  ✅ ${fb.categoryName} (${fb.accessibleTopicsCount} topics)');
    }

    final individualEnrollments = _enrolledCourses.where((c) =>
    c.categoryName == null || c.categoryName!.isEmpty
    ).toList();

    return RefreshIndicator(
      onRefresh: () => _loadEnrollments(showLoader: false),
      color: _accentColor,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  // const _PremiumEnrollmentsTopBar(),

                  if (paidBundleEnrollments.isNotEmpty) ...[
                    // const SizedBox(height: 14),
                    // _PremiumSectionHeader(
                    //   title: 'Bundle Plans',
                    //   subtitle: 'Full access by category',
                    //   count: paidBundleEnrollments.length,
                    //   icon: Icons.workspace_premium_rounded,
                    //   tone: _SectionTone.amber,
                    // ),
                    const SizedBox(height: 10),
                    _PremiumListContainer(
                      tone: _SectionTone.amber,
                      heading: 'Bundle Plans',
                      subheading: 'Everything in this category',
                      icon: Icons.workspace_premium_rounded,
                      children: _buildBundleCardsFromUserBundles(paidBundleEnrollments),
                    ),
                  ],

                  if (flexibleBundleEnrollments.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    _PremiumSectionHeader(
                      title: 'Flexible Plans',
                      subtitle: 'Pick what you want to learn',
                      count: flexibleBundleEnrollments.length,
                      icon: Icons.tune_rounded,
                      tone: _SectionTone.indigo,
                    ),
                    const SizedBox(height: 10),
                    ..._buildFlexibleBundleCards(flexibleBundleEnrollments),
                  ],

                  if (freeBundleEnrollments.isNotEmpty) ...[
                    // const SizedBox(height: 18),
                    // _PremiumSectionHeader(
                    //   title: 'Free Plans',
                    //   subtitle: 'Starter access included',
                    //   count: freeBundleEnrollments.length,
                    //   icon: Icons.lock_open_rounded,
                    //   tone: _SectionTone.green,
                    // ),
                    const SizedBox(height: 10),
                    _PremiumListContainer(
                      tone: _SectionTone.green,
                      heading: 'Free Plans',
                      subheading: 'Included starter access',
                      icon: Icons.lock_open_rounded,
                      children: _buildFreeBundleCardsFromUserBundles(freeBundleEnrollments),
                    ),
                  ],

                  if (individualEnrollments.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    _PremiumSectionHeader(
                      title: 'Individual Topics',
                      subtitle: 'Standalone enrollments',
                      count: individualEnrollments.length,
                      icon: Icons.article_outlined,
                      tone: _SectionTone.violet,
                    ),
                    const SizedBox(height: 10),
                    ..._buildIndividualCards(individualEnrollments),
                  ],

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _getBundleCount(List<CourseTopic> courses) {
    final bundleCourses = courses.where((enrollment) {
      final actualCourse = _courses.firstWhere(
            (c) => c.id == enrollment.id,
        orElse: () => enrollment,
      );
      return actualCourse.price > 0 && enrollment.categoryName != null && enrollment.categoryName!.isNotEmpty;
    }).toList();

    final categories = bundleCourses
        .map((c) => c.categoryName)
        .toSet()
        .length;
    return categories;
  }

  int _getIndividualCount(List<CourseTopic> courses) {
    return courses
        .where((c) => c.categoryName == null || c.categoryName!.isEmpty)
        .length;
  }

  int _getFreeBundleCount(List<CourseTopic> courses) {
    final freeBundleCourses = courses.where((enrollment) {
      final actualCourse = _courses.firstWhere(
            (c) => c.id == enrollment.id,
        orElse: () => enrollment,
      );
      return actualCourse.price == 0 && enrollment.categoryName != null && enrollment.categoryName!.isNotEmpty;
    }).toList();

    final categories = freeBundleCourses
        .map((c) => c.categoryName)
        .toSet()
        .length;
    return categories;
  }

  String _resolveCategoryName(int categoryId, String? fallbackName) {
    final match = _courses.firstWhere(
          (c) => c.categoryId == categoryId,
      orElse: () => CourseTopic(
        id: -1,
        title: '',
        description: '',
        categoryId: categoryId,
        categoryName: fallbackName ?? 'General',
        subcategoryId: null,
        subcategoryName: null,
        difficulty: 'Beginner',
        status: 'active',
        isFree: true,
        isFeatured: false,
        price: 0,
        durationMinutes: 0,
        thumbnailUrl: '',
      ),
    );
    return match.categoryName;
  }

  int _getTopicsCountForCategoryId(int categoryId) {
    return _courses.where((c) => c.categoryId == categoryId).length;
  }

  List<Widget> _buildBundleCardsFromUserBundles(List<UserBundle> bundles) {
    return bundles.asMap().entries.map((entry) {
      final index = entry.key;
      final bundle = entry.value;
      return TweenAnimationBuilder<double>(
        duration: Duration(milliseconds: 400 + (index * 100)),
        tween: Tween(begin: 0.0, end: 1.0),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: Opacity(
              opacity: value,
              child: child,
            ),
          );
        },
        child: _buildBundleCard(bundle, const [Color(0xFFF59E0B), Color(0xFFD97706)], 'BUNDLE'),
      );
    }).toList();
  }

  List<Widget> _buildFlexibleBundleCards(List<UserBundle> bundles) {
    return bundles.asMap().entries.map((entry) {
      final index = entry.key;
      final bundle = entry.value;
      return TweenAnimationBuilder<double>(
        duration: Duration(milliseconds: 400 + (index * 100)),
        tween: Tween(begin: 0.0, end: 1.0),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: Opacity(
              opacity: value,
              child: child,
            ),
          );
        },
        child: _buildBundleCard(bundle, const [Color(0xFF6366F1), Color(0xFF4F46E5)], 'FLEXIBLE'),
      );
    }).toList();
  }

  List<Widget> _buildFreeBundleCardsFromUserBundles(List<UserBundle> bundles) {
    return bundles.asMap().entries.map((entry) {
      final index = entry.key;
      final bundle = entry.value;
      return TweenAnimationBuilder<double>(
        duration: Duration(milliseconds: 400 + (index * 100)),
        tween: Tween(begin: 0.0, end: 1.0),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: Opacity(
              opacity: value,
              child: child,
            ),
          );
        },
        child: _buildBundleCard(bundle, const [Color(0xFF10B981), Color(0xFF059669)], 'FREE'),
      );
    }).toList();
  }

  Widget _buildBundleCard(UserBundle bundle, List<Color> gradient, String planLabel) {
    int displayTopicsCount;
    if (planLabel == 'BUNDLE' || planLabel == 'FLEXIBLE') {
      displayTopicsCount = _getTopicsCountForCategoryId(bundle.categoryId);
    } else {
      displayTopicsCount = _enrolledCourses.where((c) =>
      c.categoryId == bundle.categoryId && c.price == 0
      ).length;
      if (displayTopicsCount == 0) {
        displayTopicsCount = bundle.accessibleTopicsCount;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.90),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              debugPrint('Viewing topics for: ${bundle.categoryName} (category ${bundle.categoryId})');
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BundleTopicsDetailScreen(
                    categoryId: bundle.categoryId,
                    categoryName: bundle.categoryName,
                    userId: _userId ?? 0,
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: gradient),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: gradient[0].withOpacity(0.25),
                          blurRadius: 14,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.card_giftcard_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TranslatedText(
                                bundle.categoryName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: _textColor,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: gradient[0].withOpacity(0.10),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: gradient[0].withOpacity(0.18),
                                ),
                              ),
                              child: Text(
                                planLabel,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: gradient[0],
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _compactMetaChip(
                              icon: Icons.library_books_outlined,
                              text: '$displayTopicsCount topics',
                              tone: gradient[0],
                            ),
                            if (bundle.bundlePrice > 0)
                              _compactMetaChip(
                                icon: Icons.currency_rupee_rounded,
                                text: '${bundle.bundlePrice.toStringAsFixed(0)}',
                                tone: const Color(0xFFDC2626),
                              ),
                            _compactMetaChip(
                              icon: bundle.futureTopicsIncluded
                                  ? Icons.check_circle_rounded
                                  : Icons.cancel_rounded,
                              text: bundle.futureTopicsIncluded
                                  ? 'Future included'
                                  : 'Future not included',
                              tone: bundle.futureTopicsIncluded
                                  ? const Color(0xFF059669)
                                  : const Color(0xFFDC2626),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: _accentColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _compactMetaChip({
    required IconData icon,
    required String text,
    required Color tone,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: tone.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tone.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: tone),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: tone,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildIndividualCards(List<CourseTopic> courses) {
    return courses.asMap().entries.map((entry) {
      final index = entry.key;
      final course = entry.value;
      return TweenAnimationBuilder<double>(
        duration: Duration(milliseconds: 400 + (index * 80)),
        tween: Tween(begin: 0.0, end: 1.0),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: Opacity(
              opacity: value,
              child: child,
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFFE5E7EB),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.article_outlined,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              title: TranslatedText(
                course.title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _textColor,
                  letterSpacing: -0.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const TranslatedText(
                        'INDIVIDUAL',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF6366F1),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: Color(0xFF10B981),
                        size: 14,
                      ),
                    ),
                  ],
                ),
              ),
              trailing: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  size: 20,
                  color: _accentColor,
                ),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TopicDetailScreen(topic: course),
                  ),
                );
              },
            ),
          ),
        ),
      );
    }).toList();
  }
}

class _EnhancedCourseCard extends StatelessWidget {
  const _EnhancedCourseCard({
    required this.course,
    required this.isWishlisted,
    required this.onToggleWishlist,
    required this.onTap,
    required this.index,
    this.hidePriceBadge = false,
  });

  final CourseTopic course;
  final bool isWishlisted;
  final Future<void> Function() onToggleWishlist;
  final VoidCallback onTap;
  final int index;
  final bool hidePriceBadge;

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

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + (index * 80)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: _cardBackground,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: SizedBox(
                      height: 120,
                      width: double.infinity,
                      child: TopicImage(
                        imageUrl: course.thumbnailUrl,
                        title: course.title,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  // Gradient overlay for better text visibility
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.3),
                          ],
                          stops: const [0.6, 1.0],
                        ),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                    ),
                  ),
                  if (!hidePriceBadge)
                    Positioned(
                      right: 12,
                      top: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [priceColor, priceColor.withOpacity(0.8)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: priceColor.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          priceLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    left: 12,
                    top: 12,
                    child: _EnhancedWishlistPill(
                      isActive: isWishlisted,
                      onToggle: onToggleWishlist,
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TranslatedText(
                        course.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          height: 1.25,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _accentColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: TranslatedText(
                          course.categoryName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _accentColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: TranslatedText(
                          _truncateDescription(
                            course.description.isNotEmpty
                                ? course.description
                                : 'Learn ${course.categoryName.toLowerCase()} fundamentals',
                            80,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _mutedColor.withOpacity(0.9),
                            fontSize: 11,
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  _accentColor.withOpacity(0.15),
                                  _accentColor.withOpacity(0.08),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: TranslatedText(
                              course.difficulty.toUpperCase(),
                              style: TextStyle(
                                color: _accentColor,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: _mutedColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.schedule_outlined,
                                  size: 11,
                                  color: _mutedColor,
                                ),
                                const SizedBox(width: 4),
                                TranslatedText(
                                  course.durationMinutes > 0
                                      ? '${course.durationMinutes}m'
                                      : 'Self',
                                  style: TextStyle(
                                    color: _mutedColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
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
      ),
    );
  }
}

enum _SectionTone { amber, indigo, green, violet }

Color _toneColor(_SectionTone tone) {
  switch (tone) {
    case _SectionTone.amber:
      return const Color(0xFFF59E0B);
    case _SectionTone.indigo:
      return const Color(0xFF4F46E5);
    case _SectionTone.green:
      return const Color(0xFF059669);
    case _SectionTone.violet:
      return const Color(0xFF7C3AED);
  }
}

class _PremiumEnrollmentsTopBar extends StatelessWidget {
  const _PremiumEnrollmentsTopBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.75),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _accentColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _accentColor.withOpacity(0.18),
                width: 1,
              ),
            ),
            child: const Icon(Icons.school_rounded, color: _accentColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                TranslatedText(
                  'My Learning',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _textColor,
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: 2),
                TranslatedText(
                  'Your active plans and enrolled topics',
                  style: TextStyle(
                    fontSize: 12,
                    color: _mutedColor,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: const [
                Icon(Icons.auto_graph_rounded, size: 16, color: _mutedColor),
                SizedBox(width: 6),
                TranslatedText(
                  'Progress',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _mutedColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumSectionHeader extends StatelessWidget {
  const _PremiumSectionHeader({
    required this.title,
    required this.subtitle,
    required this.count,
    required this.icon,
    required this.tone,
  });

  final String title;
  final String subtitle;
  final int count;
  final IconData icon;
  final _SectionTone tone;

  @override
  Widget build(BuildContext context) {
    final c = _toneColor(tone);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.82),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: [
          BoxShadow(
            color: c.withOpacity(0.10),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: c.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: c.withOpacity(0.18)),
            ),
            child: Icon(icon, color: c, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TranslatedText(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: _textColor,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                TranslatedText(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _mutedColor,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: c.withOpacity(0.10),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: c.withOpacity(0.18)),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: c,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumListContainer extends StatelessWidget {
  const _PremiumListContainer({
    required this.tone,
    required this.children,
    this.heading,
    this.subheading,
    this.icon,
  });

  final _SectionTone tone;
  final List<Widget> children;
  final String? heading;
  final String? subheading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = _toneColor(tone);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.96),
            Colors.white.withOpacity(0.90),
            c.withOpacity(0.05),
          ],
          stops: const [0.0, 0.6, 1.0],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (heading != null) ...[
            Row(
              children: [
                if (icon != null)
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: c.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: c.withOpacity(0.18)),
                    ),
                    child: Icon(icon, color: c, size: 20),
                  ),
                if (icon != null) const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        heading!,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: _textColor,
                          letterSpacing: -0.2,
                        ),
                      ),
                      if (subheading != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            subheading!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: _mutedColor,
                              height: 1.25,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          ...children
              .asMap()
              .entries
              .map((entry) {
                final isLast = entry.key == children.length - 1;
                return Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
                  child: entry.value,
                );
              })
              .toList(),
        ],
      ),
    );
  }
}

class _EnhancedWishlistPill extends StatelessWidget {
  const _EnhancedWishlistPill({required this.isActive, required this.onToggle});
  final bool isActive;
  final Future<void> Function() onToggle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onToggle(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: isActive
                  ? const Color(0xFFEF4444).withOpacity(0.3)
                  : Colors.black.withOpacity(0.1),
              blurRadius: isActive ? 12 : 8,
              offset: const Offset(0, 4),
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
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _accentColor.withOpacity(0.1),
                    _accentColor.withOpacity(0.05),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cast_for_education_outlined,
                size: 64,
                color: _mutedColor,
              ),
            ),
            const SizedBox(height: 24),
            const TranslatedText(
              'Courses will appear here soon',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _textColor,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 12),
            const TranslatedText(
              'Looks like the catalogue is still loading. Pull down to refresh.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _mutedColor,
                fontSize: 14,
                height: 1.5,
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
      gradient: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
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
      gradient: [Color(0xFFF59E0B), Color(0xFFD97706)],
    );
  }
}

class _EnrollmentsMessage extends StatelessWidget {
  const _EnrollmentsMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradient),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: gradient[0].withOpacity(0.3),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(icon, size: 64, color: Colors.white),
            ),
            const SizedBox(height: 24),
            TranslatedText(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _textColor,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            TranslatedText(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _mutedColor,
                fontSize: 15,
                height: 1.5,
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
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(
                Icons.wifi_off_rounded,
                size: 64,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 24),
            TranslatedText(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _textColor,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => onRetry(showLoader: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 4,
                shadowColor: _accentColor.withOpacity(0.4),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 22),
              label: const TranslatedText(
                'Try again',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
