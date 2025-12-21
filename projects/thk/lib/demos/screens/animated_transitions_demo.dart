import 'package:flutter/material.dart';
import 'dart:math' as math;

class AnimatedTransitionsDemo extends StatefulWidget {
  const AnimatedTransitionsDemo({super.key});

  @override
  State<AnimatedTransitionsDemo> createState() => _AnimatedTransitionsDemoState();
}

class _AnimatedTransitionsDemoState extends State<AnimatedTransitionsDemo>
    with TickerProviderStateMixin {
  late AnimationController _gridAnimationController;
  late Animation<double> _gridAnimation;
  
  final List<HeroCard> _cards = List.generate(
    12,
    (index) => HeroCard(
      id: 'card_$index',
      title: 'Hero Card ${index + 1}',
      description: 'Tap to see beautiful Hero animation transitions',
      imageUrl: 'https://picsum.photos/400/300?random=$index',
      color: Color.lerp(
        const Color(0xFF667eea),
        const Color(0xFF764ba2),
        index / 11,
      )!,
      stats: HeroCardStats(
        likes: (index + 1) * 127,
        views: (index + 1) * 2341,
        shares: (index + 1) * 45,
      ),
    ),
  );

  @override
  void initState() {
    super.initState();
    _gridAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _gridAnimation = CurvedAnimation(
      parent: _gridAnimationController,
      curve: Curves.easeOutBack,
    );
    
    // Start animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _gridAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _gridAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a0a0a),
      appBar: AppBar(
        title: const Text('Hero Animations'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _gridAnimationController.reset();
              _gridAnimationController.forward();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: const Text(
              'Tap any card to see Hero widget animations',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: AnimatedBuilder(
              animation: _gridAnimation,
              builder: (context, child) {
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _cards.length,
                  itemBuilder: (context, index) {
                    final delay = index * 100;
                    final animationValue = Curves.easeOutBack.transform(
                      math.max(0, (_gridAnimation.value * 1200 - delay) / 300)
                          .clamp(0.0, 1.0),
                    );
                    
                    return Transform.scale(
                      scale: animationValue,
                      child: Transform.translate(
                        offset: Offset(
                          0,
                          50 * (1 - animationValue),
                        ),
                        child: Opacity(
                          opacity: animationValue,
                          child: HeroCardWidget(
                            card: _cards[index],
                            onTap: () => _navigateToDetail(_cards[index]),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToDetail(HeroCard card) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return HeroDetailScreen(card: card);
        },
        transitionDuration: const Duration(milliseconds: 600),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }
}

class HeroCardWidget extends StatefulWidget {
  final HeroCard card;
  final VoidCallback onTap;

  const HeroCardWidget({
    super.key,
    required this.card,
    required this.onTap,
  });

  @override
  State<HeroCardWidget> createState() => _HeroCardWidgetState();
}

class _HeroCardWidgetState extends State<HeroCardWidget>
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
        final scale = 1.0 - (_hoverController.value * 0.05);
        final elevation = 8.0 + (_hoverController.value * 16.0);
        
        return Transform.scale(
          scale: _isPressed ? 0.95 : scale,
          child: Hero(
            tag: widget.card.id,
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
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        widget.card.color,
                        widget.card.color.withOpacity(0.8),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image section with Hero tag
                      Expanded(
                        flex: 3,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                widget.card.color.withOpacity(0.3),
                                widget.card.color,
                              ],
                            ),
                          ),
                          child: Stack(
                            children: [
                              // Background pattern
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: CardPatternPainter(widget.card.color),
                                ),
                              ),
                              
                              // Content
                              Center(
                                child: Hero(
                                  tag: '${widget.card.id}_icon',
                                  child: Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(30),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.3),
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.star,
                                      color: Colors.white,
                                      size: 30,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Content section
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Hero(
                                tag: '${widget.card.id}_title',
                                child: Material(
                                  color: Colors.transparent,
                                  child: Text(
                                    widget.card.title,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.card.description,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Spacer(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.favorite,
                                        color: Colors.white70,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${widget.card.stats.likes}',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Icon(
                                    Icons.arrow_forward_ios,
                                    color: Colors.white70,
                                    size: 14,
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
            ),
          ),
        );
      },
    );
  }
}

class HeroDetailScreen extends StatefulWidget {
  final HeroCard card;

  const HeroDetailScreen({
    super.key,
    required this.card,
  });

  @override
  State<HeroDetailScreen> createState() => _HeroDetailScreenState();
}

class _HeroDetailScreenState extends State<HeroDetailScreen>
    with TickerProviderStateMixin {
  late AnimationController _contentAnimationController;
  late Animation<double> _contentAnimation;

  @override
  void initState() {
    super.initState();
    _contentAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _contentAnimation = CurvedAnimation(
      parent: _contentAnimationController,
      curve: Curves.easeOutCubic,
    );
    
    // Start content animation after hero animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _contentAnimationController.forward();
        }
      });
    });
  }

  @override
  void dispose() {
    _contentAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a0a0a),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: widget.card.color,
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: widget.card.id,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        widget.card.color,
                        widget.card.color.withOpacity(0.8),
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Background pattern
                      Positioned.fill(
                        child: CustomPaint(
                          painter: CardPatternPainter(widget.card.color),
                        ),
                      ),
                      
                      // Hero icon
                      Center(
                        child: Hero(
                          tag: '${widget.card.id}_icon',
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(60),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 3,
                              ),
                            ),
                            child: const Icon(
                              Icons.star,
                              color: Colors.white,
                              size: 60,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          SliverToBoxAdapter(
            child: AnimatedBuilder(
              animation: _contentAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, 50 * (1 - _contentAnimation.value)),
                  child: Opacity(
                    opacity: _contentAnimation.value,
                    child: child,
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Hero(
                      tag: '${widget.card.id}_title',
                      child: Material(
                        color: Colors.transparent,
                        child: Text(
                          widget.card.title,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Stats row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatItem(
                          icon: Icons.favorite,
                          value: widget.card.stats.likes,
                          label: 'Likes',
                          delay: 100,
                          animation: _contentAnimation,
                        ),
                        _StatItem(
                          icon: Icons.visibility,
                          value: widget.card.stats.views,
                          label: 'Views',
                          delay: 200,
                          animation: _contentAnimation,
                        ),
                        _StatItem(
                          icon: Icons.share,
                          value: widget.card.stats.shares,
                          label: 'Shares',
                          delay: 300,
                          animation: _contentAnimation,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Description
                    Text(
                      'Detailed Description',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    Text(
                      'This is a comprehensive example of Hero widget animations in Flutter. '
                      'The Hero widget automatically animates between two screens when navigating, '
                      'creating smooth and visually appealing transitions. This demo shows how to '
                      'use multiple Hero widgets with different tags for complex animations.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.7),
                        height: 1.6,
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: widget.card.color,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Like',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: widget.card.color),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Share',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: widget.card.color,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final int value;
  final String label;
  final int delay;
  final Animation<double> animation;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.delay,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      duration: Duration(milliseconds: 1000 + delay),
      tween: IntTween(begin: 0, end: value),
      builder: (context, animatedValue, child) {
        return Column(
          children: [
            Icon(
              icon,
              color: Colors.white70,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              '$animatedValue',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ],
        );
      },
    );
  }
}

class CardPatternPainter extends CustomPainter {
  final Color baseColor;

  CardPatternPainter(this.baseColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Draw geometric patterns
    for (int i = 0; i < 6; i++) {
      for (int j = 0; j < 4; j++) {
        final x = (size.width / 6) * i;
        final y = (size.height / 4) * j;
        
        canvas.drawCircle(Offset(x, y), 20, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class HeroCard {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final Color color;
  final HeroCardStats stats;

  HeroCard({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.color,
    required this.stats,
  });
}

class HeroCardStats {
  final int likes;
  final int views;
  final int shares;

  HeroCardStats({
    required this.likes,
    required this.views,
    required this.shares,
  });
}