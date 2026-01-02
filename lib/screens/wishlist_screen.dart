import 'package:flutter/material.dart';

import '../services/wishlist_store.dart';
import '../widgets/topic_visuals.dart' show topicGradientFor, TopicImage;
import '../widgets/translated_text.dart';
import '../widgets/lottie_loader.dart';
import 'topic_detail_screen.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  final WishlistStore _wishlist = WishlistStore.instance;
  late final VoidCallback _listener;
  bool _hydrated = false;

  @override
  void initState() {
    super.initState();
    _listener = () {
      if (mounted) setState(() {});
    };
    _wishlist.addListener(_listener);
    _hydrate();
  }

  @override
  void dispose() {
    _wishlist.removeListener(_listener);
    super.dispose();
  }

  Future<void> _hydrate() async {
    await _wishlist.hydrate();
    if (!mounted) return;
    setState(() => _hydrated = true);
  }

  @override
  Widget build(BuildContext context) {
    final courses = _wishlist.courses;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            _WishlistTopBar(count: courses.length, onBack: () => Navigator.pop(context)),
            Expanded(
              child: !_hydrated
                  ? const Center(child: LottieLoader(width: 120, height: 120))
                  : courses.isEmpty
                  ? const _EmptyWishlist()
                  : RefreshIndicator(
                      color: const Color(0xFF2E7DFF),
                      onRefresh: _hydrate,
                      child: CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                              child: _WishlistHeader(
                                count: courses.length,
                                onClear: () async {
                                  final messenger = ScaffoldMessenger.of(context);
                                  await _wishlist.clear();
                                  if (!mounted) return;
                                  messenger.showSnackBar(
                                    const SnackBar(content: TranslatedText('Wishlist cleared')),
                                  );
                                },
                              ),
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                            sliver: SliverList.separated(
                              itemCount: courses.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 16),
                              itemBuilder: (context, index) {
                                final saved = courses[index];
                                return _WishlistCourseCard(
                                  course: saved,
                                  onOpen: () {
                                    final topic = saved.toCourseTopic();
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => TopicDetailScreen(topic: topic),
                                      ),
                                    );
                                  },
                                  onRemove: () async {
                                    final messenger = ScaffoldMessenger.of(context);
                                    await _wishlist.remove(saved.id);
                                    if (!mounted) return;
                                    messenger.showSnackBar(
                                      const SnackBar(content: TranslatedText('Removed from wishlist')),
                                    );
                                  },
                                );
                              },
                            ),
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

class _WishlistCourseCard extends StatefulWidget {
  const _WishlistCourseCard({
    required this.course,
    required this.onOpen,
    required this.onRemove,
  });

  final SavedCourse course;
  final VoidCallback onOpen;
  final Future<void> Function() onRemove;

  @override
  State<_WishlistCourseCard> createState() => _WishlistCourseCardState();
}

class _WishlistCourseCardState extends State<_WishlistCourseCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final topic = widget.course.toCourseTopic();
    final isFree = topic.isFree || topic.price == 0;
    final bool isOwned = topic.isEnrolled;

    String priceText(num value) {
      if (value % 1 == 0) {
        return '₹${value.toInt()}';
      }
      return '₹${value.toStringAsFixed(2)}';
    }

    final String priceLabel = isOwned
        ? 'Enrolled'
        : (isFree ? 'Free' : priceText(topic.price));  // Will be translated in UI
    final Color priceColor = isOwned
        ? const Color(0xFF22C55E)
        : (isFree ? Colors.green : const Color(0xFF2E7DFF));

    return InkWell(
      onTap: widget.onOpen,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x11000000),
              blurRadius: 24,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            _WishlistThumbnail(course: widget.course),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TranslatedText(
                    widget.course.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (widget.course.description.isNotEmpty) ...[
                    AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      child: TranslatedText(
                        widget.course.description,
                        maxLines: _expanded ? 5 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF6B7280),
                          height: 1.45,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => setState(() => _expanded = !_expanded),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: Icon(
                        _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                        size: 16,
                        color: const Color(0xFF2563EB),
                      ),
                      label: Text(
                        _expanded ? 'View less' : 'View more',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                  if (widget.course.description.isEmpty) const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      _TagChip(label: widget.course.categoryName, translate: true),
                      _TagChip(label: widget.course.difficulty, translate: true),
                      _TagChip(
                        label: priceLabel,
                        backgroundColor: priceColor.withValues(alpha: 0.12),
                        foregroundColor: priceColor,
                        translate: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              onPressed: () => widget.onRemove(),
              tooltip: 'Remove',
              icon: const Icon(Icons.delete_outline, color: Color(0xFFFF5757)),
            ),
          ],
        ),
      ),
    );
  }
}

class _WishlistHeader extends StatelessWidget {
  const _WishlistHeader({required this.count, required this.onClear});

  final int count;
  final Future<void> Function() onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.favorite_rounded, color: Color(0xFF4F46E5)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const TranslatedText(
                  'Saved Courses',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                TranslatedText(
                  '$count item${count == 1 ? '' : 's'} in your wishlist',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: count == 0 ? null : onClear,
            icon: const Icon(Icons.delete_sweep_rounded, size: 16),
            label: const TranslatedText(
              'Clear',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFEF4444),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }
}

class _WishlistTopBar extends StatelessWidget {
  const _WishlistTopBar({required this.count, required this.onBack});

  final int count;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 18),
              color: const Color(0xFF1E293B),
              onPressed: onBack,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const TranslatedText(
                  'Wishlist',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                TranslatedText(
                  count == 0
                      ? 'Your wishlist is empty'
                      : '$count item${count == 1 ? '' : 's'} saved',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          if (count > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$count ${count == 1 ? "item" : "items"}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _WishlistThumbnail extends StatelessWidget {
  const _WishlistThumbnail({required this.course});

  final SavedCourse course;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: TopicImage(
        imageUrl: course.thumbnailUrl,
        title: course.title,
        fit: BoxFit.cover,
        width: 82,
        height: 82,
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.label,
    this.backgroundColor,
    this.foregroundColor,
    this.translate = false,
  });

  final String label;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool translate;

  @override
  Widget build(BuildContext context) {
    final Color bg = backgroundColor ?? const Color(0xFF2E7DFF).withValues(alpha: 0.12);
    final Color fg = foregroundColor ?? const Color(0xFF2E7DFF);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: translate
          ? TranslatedText(
              label,
              style: TextStyle(
                color: fg,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            )
          : Text(
              label,
              style: TextStyle(
                color: fg,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }
}

class _EmptyWishlist extends StatelessWidget {
  const _EmptyWishlist();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.favorite_border_rounded,
              size: 72,
              color: Color(0xFFCBD5F5),
            ),
            SizedBox(height: 16),
            TranslatedText(
              'No saved courses yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2937),
              ),
            ),
            SizedBox(height: 10),
            TranslatedText(
              'Tap the heart on any course to build your wishlist.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
