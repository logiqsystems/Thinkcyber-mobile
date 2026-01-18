import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;

class ModalSheetDemo extends StatefulWidget {
  const ModalSheetDemo({super.key});

  @override
  State<ModalSheetDemo> createState() => _ModalSheetDemoState();
}

class _ModalSheetDemoState extends State<ModalSheetDemo>
    with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late Animation<double> _backgroundAnimation;
  
  final List<SheetItem> _items = List.generate(
    20,
    (index) => SheetItem(
      id: index,
      title: 'Sheet Item ${index + 1}',
      subtitle: 'Tap to open modal with blur effect',
      icon: [
        Icons.palette,
        Icons.music_note,
        Icons.photo_camera,
        Icons.videogame_asset,
        Icons.book,
      ][index % 5],
      color: Color.lerp(
        const Color(0xFF667eea),
        const Color(0xFF764ba2),
        index / 19,
      )!,
      content: SheetContent(
        title: 'Detailed View ${index + 1}',
        description: 'This is a comprehensive modal bottom sheet with smooth blur effects and animations. '
                    'The sheet is scrollable and includes various interactive elements.',
        features: [
          'BackdropFilter blur effect',
          'Smooth animated transitions',
          'Scrollable content with isScrollControlled',
          'Custom drag handle',
          'Interactive elements',
        ],
        stats: SheetStats(
          rating: 4.0 + (index % 10) / 10,
          reviews: (index + 1) * 42,
          downloads: (index + 1) * 1250,
        ),
      ),
    ),
  );

  @override
  void initState() {
    super.initState();
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();
    
    _backgroundAnimation = CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    super.dispose();
  }

  void _showModalSheet(SheetItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => BlurredModalSheet(item: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a0a0a),
      appBar: AppBar(
        title: const Text('Modal Bottom Sheet'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // Animated background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _backgroundAnimation,
              builder: (context, child) {
                return CustomPaint(
                  painter: AnimatedBackgroundPainter(_backgroundAnimation.value),
                );
              },
            ),
          ),
          
          // Content
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: const Text(
                  'Tap any item to see modal sheet with blur effects',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return TweenAnimationBuilder<double>(
                      duration: Duration(milliseconds: 300 + (index % 5) * 100),
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(0, 30 * (1 - value)),
                          child: Opacity(
                            opacity: value,
                            child: child,
                          ),
                        );
                      },
                      child: SheetItemWidget(
                        item: item,
                        onTap: () => _showModalSheet(item),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SheetItemWidget extends StatefulWidget {
  final SheetItem item;
  final VoidCallback onTap;

  const SheetItemWidget({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  State<SheetItemWidget> createState() => _SheetItemWidgetState();
}

class _SheetItemWidgetState extends State<SheetItemWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  bool _isPressed = false;

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
        final scale = _isPressed ? 0.95 : (1.0 + (_hoverController.value * 0.02));
        final elevation = 4.0 + (_hoverController.value * 8.0);
        
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Transform.scale(
            scale: scale,
            child: Material(
              elevation: elevation,
              borderRadius: BorderRadius.circular(20),
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: widget.onTap,
                onTapDown: (_) => setState(() => _isPressed = true),
                onTapUp: (_) => setState(() => _isPressed = false),
                onTapCancel: () => setState(() => _isPressed = false),
                onHover: (hovered) {
                  if (hovered) {
                    _hoverController.forward();
                  } else {
                    _hoverController.reverse();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        widget.item.color.withOpacity(0.8),
                        widget.item.color.withOpacity(0.6),
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Icon(
                          widget.item.icon,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.item.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.item.subtitle,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.keyboard_arrow_up,
                        color: Colors.white70,
                        size: 24,
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

class BlurredModalSheet extends StatefulWidget {
  final SheetItem item;

  const BlurredModalSheet({
    super.key,
    required this.item,
  });

  @override
  State<BlurredModalSheet> createState() => _BlurredModalSheetState();
}

class _BlurredModalSheetState extends State<BlurredModalSheet>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _blurController;
  late AnimationController _contentController;
  
  late Animation<Offset> _slideAnimation;
  late Animation<double> _blurAnimation;
  late Animation<double> _contentAnimation;

  @override
  void initState() {
    super.initState();
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _blurController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _contentController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _blurAnimation = Tween<double>(
      begin: 0.0,
      end: 10.0,
    ).animate(CurvedAnimation(
      parent: _blurController,
      curve: Curves.easeInOut,
    ));
    
    _contentAnimation = CurvedAnimation(
      parent: _contentController,
      curve: Curves.easeOutBack,
    );
    
    // Start animations
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _blurController.forward();
      _slideController.forward().then((_) {
        _contentController.forward();
      });
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _blurController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _closeSheet() {
    _contentController.reverse().then((_) {
      _slideController.reverse().then((_) {
        _blurController.reverse().then((_) {
          if (mounted) Navigator.of(context).pop();
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_slideAnimation, _blurAnimation, _contentAnimation]),
      builder: (context, child) {
        return Stack(
          children: [
            // Backdrop blur
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: _blurAnimation.value,
                  sigmaY: _blurAnimation.value,
                ),
                child: Container(
                  color: Colors.black.withOpacity(0.3 * _blurAnimation.value / 10),
                ),
              ),
            ),
            
            // Modal sheet
            SlideTransition(
              position: _slideAnimation,
              child: DraggableScrollableSheet(
                initialChildSize: 0.6,
                minChildSize: 0.3,
                maxChildSize: 0.9,
                builder: (context, scrollController) {
                  return Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF1a1a2e),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Drag handle
                        Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        
                        // Content
                        Expanded(
                          child: SingleChildScrollView(
                            controller: scrollController,
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                            child: Transform.translate(
                              offset: Offset(0, 20 * (1 - _contentAnimation.value)),
                              child: Opacity(
                                opacity: _contentAnimation.value,
                                child: _buildSheetContent(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            // Close button
            Positioned(
              top: 60,
              right: 20,
              child: Transform.scale(
                scale: _contentAnimation.value,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    onPressed: _closeSheet,
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSheetContent() {
    final content = widget.item.content;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: widget.item.color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                widget.item.icon,
                color: widget.item.color,
                size: 40,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    content.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      Text(
                        ' ${content.stats.rating.toStringAsFixed(1)}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        ' (${content.stats.reviews} reviews)',
                        style: const TextStyle(
                          color: Colors.white50,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Statistics
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatColumn(
              icon: Icons.download,
              value: '${(content.stats.downloads / 1000).toStringAsFixed(1)}K',
              label: 'Downloads',
            ),
            _StatColumn(
              icon: Icons.rate_review,
              value: '${content.stats.reviews}',
              label: 'Reviews',
            ),
            _StatColumn(
              icon: Icons.star,
              value: content.stats.rating.toStringAsFixed(1),
              label: 'Rating',
            ),
          ],
        ),
        
        const SizedBox(height: 32),
        
        // Description
        const Text(
          'Description',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          content.description,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white70,
            height: 1.6,
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Features
        const Text(
          'Features',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        ...content.features.map((feature) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: widget.item.color,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    feature,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        
        const SizedBox(height: 32),
        
        // Action buttons
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.item.color,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Get Started',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: widget.item.color),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                onPressed: () {},
                icon: Icon(
                  Icons.favorite_border,
                  color: widget.item.color,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: widget.item.color),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                onPressed: () {},
                icon: Icon(
                  Icons.share,
                  color: widget.item.color,
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 24),
      ],
    );
  }
}

class _StatColumn extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatColumn({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white70,
          size: 28,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white50,
          ),
        ),
      ],
    );
  }
}

class AnimatedBackgroundPainter extends CustomPainter {
  final double animation;

  AnimatedBackgroundPainter(this.animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF667eea).withOpacity(0.1)
      ..style = PaintingStyle.fill;

    // Draw animated circles
    for (int i = 0; i < 5; i++) {
      final progress = (animation + i * 0.2) % 1.0;
      final radius = progress * 100;
      final opacity = 1.0 - progress;
      
      paint.color = Color.lerp(
        const Color(0xFF667eea),
        const Color(0xFF764ba2),
        i / 4,
      )!.withOpacity(opacity * 0.1);
      
      canvas.drawCircle(
        Offset(
          size.width * 0.2 + (i * size.width * 0.15),
          size.height * 0.3 + math.sin(animation * math.pi * 2 + i) * 50,
        ),
        radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class SheetItem {
  final int id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final SheetContent content;

  SheetItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.content,
  });
}

class SheetContent {
  final String title;
  final String description;
  final List<String> features;
  final SheetStats stats;

  SheetContent({
    required this.title,
    required this.description,
    required this.features,
    required this.stats,
  });
}

class SheetStats {
  final double rating;
  final int reviews;
  final int downloads;

  SheetStats({
    required this.rating,
    required this.reviews,
    required this.downloads,
  });
}