import 'package:flutter/material.dart';
import 'dart:math' as math;

class FloatingSearchDemo extends StatefulWidget {
  const FloatingSearchDemo({super.key});

  @override
  State<FloatingSearchDemo> createState() => _FloatingSearchDemoState();
}

class _FloatingSearchDemoState extends State<FloatingSearchDemo>
    with TickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _searchAnimationController;
  late AnimationController _fabAnimationController;
  late Animation<double> _searchAnimation;
  late Animation<double> _fabAnimation;
  
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  bool _isSearchExpanded = false;
  String _searchQuery = '';
  double _searchBarTop = 120.0;
  
  final List<SearchItem> _allItems = List.generate(
    50,
    (index) => SearchItem(
      id: index,
      title: 'Item ${index + 1}',
      subtitle: 'This is a searchable item with AnimatedPositioned',
      category: ['Technology', 'Design', 'Science', 'Art', 'Music'][index % 5],
      tags: ['tag${index % 3}', 'flutter', 'animation'],
      color: Color.lerp(
        const Color(0xFF667eea),
        const Color(0xFF764ba2),
        index / 49,
      )!,
    ),
  );
  
  List<SearchItem> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _filteredItems = _allItems;
    
    _scrollController = ScrollController();
    _searchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    
    _searchAnimation = CurvedAnimation(
      parent: _searchAnimationController,
      curve: Curves.easeInOut,
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    );
    
    _scrollController.addListener(_handleScroll);
    _searchController.addListener(_handleSearchChange);
    _searchFocusNode.addListener(_handleFocusChange);
  }

  void _handleScroll() {
    final offset = _scrollController.offset;
    final newTop = math.max(80.0, 120.0 - offset * 0.5).clamp(80.0, 120.0);
    
    if (newTop != _searchBarTop) {
      setState(() {
        _searchBarTop = newTop;
      });
    }
    
    // Show/hide FAB based on scroll position
    if (offset > 200) {
      _fabAnimationController.forward();
    } else {
      _fabAnimationController.reverse();
    }
  }

  void _handleSearchChange() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredItems = _allItems;
      } else {
        _filteredItems = _allItems.where((item) {
          return item.title.toLowerCase().contains(query) ||
                 item.subtitle.toLowerCase().contains(query) ||
                 item.category.toLowerCase().contains(query) ||
                 item.tags.any((tag) => tag.toLowerCase().contains(query));
        }).toList();
      }
    });
  }

  void _handleFocusChange() {
    if (_searchFocusNode.hasFocus && !_isSearchExpanded) {
      _expandSearch();
    } else if (!_searchFocusNode.hasFocus && _isSearchExpanded && _searchQuery.isEmpty) {
      _collapseSearch();
    }
  }

  void _expandSearch() {
    setState(() {
      _isSearchExpanded = true;
    });
    _searchAnimationController.forward();
  }

  void _collapseSearch() {
    setState(() {
      _isSearchExpanded = false;
    });
    _searchAnimationController.reverse();
    _searchFocusNode.unfocus();
  }

  void _clearSearch() {
    _searchController.clear();
    _collapseSearch();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchAnimationController.dispose();
    _fabAnimationController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a0a0a),
      body: Stack(
        children: [
          // Main content with SliverAppBar
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                floating: false,
                pinned: true,
                backgroundColor: const Color(0xFF1a1a2e),
                flexibleSpace: FlexibleSpaceBar(
                  title: const Text(
                    'Floating Search',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF667eea),
                          Color(0xFF764ba2),
                        ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Animated background pattern
                        Positioned.fill(
                          child: CustomPaint(
                            painter: SearchPatternPainter(),
                          ),
                        ),
                        const Positioned(
                          bottom: 60,
                          left: 20,
                          right: 20,
                          child: Text(
                            'AnimatedPositioned + SliverAppBar\nwith Floating Search Animation',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Search results
              SliverPadding(
                padding: const EdgeInsets.only(top: 80, left: 16, right: 16, bottom: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = _filteredItems[index];
                      return TweenAnimationBuilder<double>(
                        duration: Duration(milliseconds: 300 + (index % 5) * 50),
                        tween: Tween(begin: 0.0, end: 1.0),
                        builder: (context, value, child) {
                          return Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: Opacity(
                              opacity: value,
                              child: child,
                            ),
                          );
                        },
                        child: SearchResultItem(item: item),
                      );
                    },
                    childCount: _filteredItems.length,
                  ),
                ),
              ),
            ],
          ),
          
          // Floating search bar
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            top: _searchBarTop,
            left: 16,
            right: 16,
            child: AnimatedBuilder(
              animation: _searchAnimation,
              builder: (context, child) {
                return Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Search icon
                      Padding(
                        padding: const EdgeInsets.only(left: 16, right: 8),
                        child: Icon(
                          Icons.search,
                          color: Colors.grey[600],
                          size: 24,
                        ),
                      ),
                      
                      // Search input
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          decoration: const InputDecoration(
                            hintText: 'Search items...',
                            border: InputBorder.none,
                            hintStyle: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      
                      // Clear/Close button
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: _isSearchExpanded
                            ? IconButton(
                                key: const ValueKey('clear'),
                                icon: const Icon(Icons.clear),
                                color: Colors.grey[600],
                                onPressed: _clearSearch,
                              )
                            : IconButton(
                                key: const ValueKey('mic'),
                                icon: const Icon(Icons.mic),
                                color: Colors.grey[600],
                                onPressed: () {
                                  // Voice search functionality
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          
          // Search suggestions overlay
          if (_isSearchExpanded && _searchQuery.isNotEmpty)
            AnimatedBuilder(
              animation: _searchAnimation,
              builder: (context, child) {
                return Positioned(
                  top: _searchBarTop + 60,
                  left: 16,
                  right: 16,
                  child: Transform.scale(
                    scale: _searchAnimation.value,
                    alignment: Alignment.topCenter,
                    child: Opacity(
                      opacity: _searchAnimation.value,
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 200),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shrinkWrap: true,
                          itemCount: math.min(_filteredItems.length, 5),
                          itemBuilder: (context, index) {
                            final item = _filteredItems[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: item.color.withOpacity(0.2),
                                child: Icon(
                                  Icons.search,
                                  color: item.color,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                item.title,
                                style: const TextStyle(fontSize: 14),
                              ),
                              subtitle: Text(
                                item.category,
                                style: const TextStyle(fontSize: 12),
                              ),
                              onTap: () {
                                _searchController.text = item.title;
                                _collapseSearch();
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      
      // Animated FAB
      floatingActionButton: ScaleTransition(
        scale: _fabAnimation,
        child: FloatingActionButton(
          onPressed: () {
            _scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
            );
          },
          backgroundColor: const Color(0xFF667eea),
          child: const Icon(Icons.keyboard_arrow_up),
        ),
      ),
    );
  }
}

class SearchResultItem extends StatefulWidget {
  final SearchItem item;

  const SearchResultItem({
    super.key,
    required this.item,
  });

  @override
  State<SearchResultItem> createState() => _SearchResultItemState();
}

class _SearchResultItemState extends State<SearchResultItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _hoverController,
      builder: (context, child) {
        final scale = 1.0 + (_hoverController.value * 0.02);
        final elevation = 4.0 + (_hoverController.value * 8.0);
        
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Transform.scale(
            scale: scale,
            child: Material(
              elevation: elevation,
              borderRadius: BorderRadius.circular(16),
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  // Handle item tap
                },
                onHover: (hovered) {
                  setState(() => _isHovered = hovered);
                  if (hovered) {
                    _hoverController.forward();
                  } else {
                    _hoverController.reverse();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        widget.item.color.withOpacity(0.8),
                        widget.item.color.withOpacity(0.6),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.item.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              widget.item.category,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.item.subtitle,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: widget.item.tags.map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                              ),
                            ),
                            child: Text(
                              '#$tag',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class SearchPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Draw search-related patterns
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    
    // Search circles
    for (int i = 0; i < 3; i++) {
      canvas.drawCircle(
        Offset(centerX, centerY),
        40.0 + (i * 25),
        paint,
      );
    }
    
    // Search lines
    for (int i = 0; i < 8; i++) {
      final angle = (i * math.pi * 2) / 8;
      final startX = centerX + math.cos(angle) * 60;
      final startY = centerY + math.sin(angle) * 60;
      final endX = centerX + math.cos(angle) * 80;
      final endY = centerY + math.sin(angle) * 80;
      
      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SearchItem {
  final int id;
  final String title;
  final String subtitle;
  final String category;
  final List<String> tags;
  final Color color;

  SearchItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.tags,
    required this.color,
  });
}