import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'dart:math' as math;

class SmoothScrollingDemo extends StatefulWidget {
  const SmoothScrollingDemo({super.key});

  @override
  State<SmoothScrollingDemo> createState() => _SmoothScrollingDemoState();
}

class _SmoothScrollingDemoState extends State<SmoothScrollingDemo>
    with TickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;
  
  final List<SmoothItem> _items = List.generate(
    100,
    (index) => SmoothItem(
      id: index,
      title: 'Smooth Item $index',
      description: 'This is a smoothly scrolling item with physics-based animation',
      category: ['Technology', 'Design', 'Innovation', 'Future'][index % 4],
      progress: (index * 13) % 100 / 100,
      color: Color.lerp(
        const Color(0xFF667eea),
        const Color(0xFF764ba2),
        (index % 10) / 10,
      )!,
    ),
  );

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    );
    
    _scrollController.addListener(_handleScroll);
  }

  void _handleScroll() {
    if (_scrollController.offset > 200) {
      _fabAnimationController.forward();
    } else {
      _fabAnimationController.reverse();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0d1421),
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          // Custom SliverAppBar with smooth animations
          SliverAppBar(
            expandedHeight: 200,
            floating: true,
            pinned: true,
            snap: false,
            backgroundColor: const Color(0xFF1a1a2e),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Smooth Scrolling',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
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
                  ),
                  Positioned.fill(
                    child: CustomPaint(
                      painter: WavePatternPainter(),
                    ),
                  ),
                  const Positioned(
                    bottom: 60,
                    left: 20,
                    right: 20,
                    child: Text(
                      'CustomScrollView + SliverList\nwith Physics-based Scrolling',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Sliver for category filters
          SliverToBoxAdapter(
            child: Container(
              height: 60,
              margin: const EdgeInsets.symmetric(vertical: 16),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: 4,
                itemBuilder: (context, index) {
                  final categories = ['Technology', 'Design', 'Innovation', 'Future'];
                  return Container(
                    margin: const EdgeInsets.only(right: 12),
                    child: FilterChip(
                      label: Text(categories[index]),
                      selected: index == 0,
                      onSelected: (_) {},
                      backgroundColor: Colors.white.withOpacity(0.1),
                      selectedColor: const Color(0xFF667eea),
                      labelStyle: const TextStyle(color: Colors.white),
                    ),
                  );
                },
              ),
            ),
          ),
          
          // Main content with SliverList
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
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
                  child: SmoothScrollItem(
                    item: _items[index],
                    index: index,
                  ),
                );
              },
              childCount: _items.length,
            ),
          ),
        ],
      ),
      
      // Animated FAB
      floatingActionButton: ScaleTransition(
        scale: _fabAnimation,
        child: FloatingActionButton(
          onPressed: _scrollToTop,
          backgroundColor: const Color(0xFF667eea),
          child: const Icon(Icons.keyboard_arrow_up),
        ),
      ),
    );
  }
}

class SmoothScrollItem extends StatefulWidget {
  final SmoothItem item;
  final int index;

  const SmoothScrollItem({
    super.key,
    required this.item,
    required this.index,
  });

  @override
  State<SmoothScrollItem> createState() => _SmoothScrollItemState();
}

class _SmoothScrollItemState extends State<SmoothScrollItem>
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
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Transform.scale(
            scale: scale,
            child: Material(
              elevation: elevation,
              borderRadius: BorderRadius.circular(16),
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  // Handle tap with smooth animation
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
                        widget.item.color,
                        widget.item.color.withOpacity(0.8),
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      // Leading circle with animation
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 1000),
                        tween: Tween(begin: 0.0, end: widget.item.progress),
                        builder: (context, value, child) {
                          return SizedBox(
                            width: 60,
                            height: 60,
                            child: Stack(
                              children: [
                                CircularProgressIndicator(
                                  value: value,
                                  backgroundColor: Colors.white.withOpacity(0.2),
                                  valueColor: const AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                  strokeWidth: 4,
                                ),
                                Center(
                                  child: Text(
                                    '${(value * 100).toInt()}%',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // Content
                      Expanded(
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
                              widget.item.description,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 12),
                            
                            // Animated progress bar
                            Container(
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: widget.item.progress,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Trailing arrow
                      AnimatedRotation(
                        turns: _isHovered ? 0.25 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white70,
                        ),
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

class WavePatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    final waveHeight = size.height * 0.1;
    final waveLength = size.width / 4;

    for (int i = 0; i < 5; i++) {
      path.reset();
      final yOffset = size.height * 0.2 + i * 20;
      
      path.moveTo(0, yOffset);
      for (double x = 0; x <= size.width; x += 10) {
        final y = yOffset + math.sin((x / waveLength) * 2 * math.pi) * waveHeight;
        path.lineTo(x, y);
      }
      
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SmoothItem {
  final int id;
  final String title;
  final String description;
  final String category;
  final double progress;
  final Color color;

  SmoothItem({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.progress,
    required this.color,
  });
}