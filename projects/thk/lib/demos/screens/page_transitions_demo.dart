import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;

class PageTransitionsDemo extends StatefulWidget {
  const PageTransitionsDemo({super.key});

  @override
  State<PageTransitionsDemo> createState() => _PageTransitionsDemoState();
}

class _PageTransitionsDemoState extends State<PageTransitionsDemo>
    with TickerProviderStateMixin {
  late AnimationController _gridController;
  late Animation<double> _gridAnimation;
  
  final List<TransitionType> _transitionTypes = [
    TransitionType(
      name: 'Slide Left',
      description: 'Smooth slide transition from right to left',
      icon: Icons.arrow_forward,
      color: const Color(0xFF667eea),
      builder: _buildSlideLeftTransition,
    ),
    TransitionType(
      name: 'Slide Up',
      description: 'Vertical slide transition from bottom to top',
      icon: Icons.arrow_upward,
      color: const Color(0xFF764ba2),
      builder: _buildSlideUpTransition,
    ),
    TransitionType(
      name: 'Scale Fade',
      description: 'Scale and fade animation combination',
      icon: Icons.zoom_in,
      color: const Color(0xFF36d1dc),
      builder: _buildScaleFadeTransition,
    ),
    TransitionType(
      name: 'Rotation',
      description: 'Smooth rotation transition with fade',
      icon: Icons.rotate_right,
      color: const Color(0xFF5b86e5),
      builder: _buildRotationTransition,
    ),
    TransitionType(
      name: 'Flip Horizontal',
      description: '3D flip effect along horizontal axis',
      icon: Icons.flip,
      color: const Color(0xFFf093fb),
      builder: _buildFlipTransition,
    ),
    TransitionType(
      name: 'Custom Elastic',
      description: 'Custom elastic bounce animation',
      icon: Icons.sports_volleyball,
      color: const Color(0xFF4facfe),
      builder: _buildElasticTransition,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _gridController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _gridAnimation = CurvedAnimation(
      parent: _gridController,
      curve: Curves.easeOutBack,
    );
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _gridController.forward();
    });
  }

  @override
  void dispose() {
    _gridController.dispose();
    super.dispose();
  }

  void _navigateWithTransition(TransitionType transitionType) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return TransitionDetailScreen(transitionType: transitionType);
        },
        transitionDuration: const Duration(milliseconds: 800),
        reverseTransitionDuration: const Duration(milliseconds: 600),
        transitionsBuilder: transitionType.builder,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a0a0a),
      appBar: AppBar(
        title: const Text('Page Transitions'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _gridController.reset();
              _gridController.forward();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: const Text(
              'Choose a transition type to see custom page animations',
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
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _transitionTypes.length,
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
                          child: TransitionCard(
                            transitionType: _transitionTypes[index],
                            onTap: () => _navigateWithTransition(_transitionTypes[index]),
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

  static Widget _buildSlideLeftTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      )),
      child: child,
    );
  }

  static Widget _buildSlideUpTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.0, 1.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
      )),
      child: child,
    );
  }

  static Widget _buildScaleFadeTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return ScaleTransition(
      scale: Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.elasticOut,
      )),
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  }

  static Widget _buildRotationTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return RotationTransition(
      turns: Tween<double>(
        begin: 0.5,
        end: 0.0,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOut,
      )),
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  }

  static Widget _buildFlipTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final rotationValue = animation.value * math.pi;
        if (rotationValue >= math.pi / 2) {
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(math.pi),
            child: child,
          );
        } else {
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(rotationValue),
            child: Container(
              color: const Color(0xFF0a0a0a),
              child: const Center(
                child: Text(
                  'Flipping...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        }
      },
    );
  }

  static Widget _buildElasticTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(-1.0, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.elasticOut,
      )),
      child: ScaleTransition(
        scale: Tween<double>(
          begin: 0.8,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.elasticOut,
        )),
        child: child,
      ),
    );
  }
}

class TransitionCard extends StatefulWidget {
  final TransitionType transitionType;
  final VoidCallback onTap;

  const TransitionCard({
    super.key,
    required this.transitionType,
    required this.onTap,
  });

  @override
  State<TransitionCard> createState() => _TransitionCardState();
}

class _TransitionCardState extends State<TransitionCard>
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
        final scale = _isPressed ? 0.95 : (1.0 - (_hoverController.value * 0.05));
        final elevation = 8.0 + (_hoverController.value * 16.0);
        
        return Transform.scale(
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
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.transitionType.color,
                      widget.transitionType.color.withOpacity(0.7),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // Background pattern
                    Positioned.fill(
                      child: CustomPaint(
                        painter: TransitionPatternPainter(widget.transitionType.color),
                      ),
                    ),
                    
                    // Content
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icon
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Icon(
                              widget.transitionType.icon,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                          
                          const Spacer(),
                          
                          // Title
                          Text(
                            widget.transitionType.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          
                          const SizedBox(height: 8),
                          
                          // Description
                          Text(
                            widget.transitionType.description,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Arrow
                          Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.arrow_forward,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
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
      },
    );
  }
}

class TransitionDetailScreen extends StatefulWidget {
  final TransitionType transitionType;

  const TransitionDetailScreen({
    super.key,
    required this.transitionType,
  });

  @override
  State<TransitionDetailScreen> createState() => _TransitionDetailScreenState();
}

class _TransitionDetailScreenState extends State<TransitionDetailScreen>
    with TickerProviderStateMixin {
  late AnimationController _contentController;
  late Animation<double> _contentAnimation;
  
  final List<String> _features = [
    'Smooth animation curves',
    'Customizable duration',
    'Performance optimized',
    'Cross-platform support',
    'Easy integration',
  ];

  @override
  void initState() {
    super.initState();
    _contentController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _contentAnimation = CurvedAnimation(
      parent: _contentController,
      curve: Curves.easeOutBack,
    );
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _contentController.forward();
    });
  }

  @override
  void dispose() {
    _contentController.dispose();
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
            backgroundColor: widget.transitionType.color,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.transitionType.color,
                      widget.transitionType.color.withOpacity(0.8),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: TransitionPatternPainter(widget.transitionType.color),
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Icon(
                              widget.transitionType.icon,
                              color: Colors.white,
                              size: 50,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            widget.transitionType.name,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Description
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.transitionType.description,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                        height: 1.6,
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Features
                    const Text(
                      'Features',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    ..._features.asMap().entries.map((entry) {
                      final index = entry.key;
                      final feature = entry.value;
                      
                      return TweenAnimationBuilder<double>(
                        duration: Duration(milliseconds: 500 + (index * 100)),
                        tween: Tween(begin: 0.0, end: 1.0),
                        builder: (context, value, child) {
                          return Transform.translate(
                            offset: Offset(20 * (1 - value), 0),
                            child: Opacity(
                              opacity: value,
                              child: child,
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: widget.transitionType.color.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: widget.transitionType.color,
                                size: 24,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  feature,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    
                    const SizedBox(height: 32),
                    
                    // Demo button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // Navigate back with the same transition
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.transitionType.color,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Go Back with Transition',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
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

class TransitionPatternPainter extends CustomPainter {
  final Color baseColor;

  TransitionPatternPainter(this.baseColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draw transition-related patterns
    for (int i = 0; i < 5; i++) {
      final progress = i / 4;
      final x = size.width * progress;
      final y = size.height * 0.8;
      
      // Draw arrows
      final path = Path();
      path.moveTo(x, y);
      path.lineTo(x + 15, y - 8);
      path.moveTo(x, y);
      path.lineTo(x + 15, y + 8);
      path.moveTo(x, y);
      path.lineTo(x + 20, y);
      
      canvas.drawPath(path, paint);
    }
    
    // Draw curved path
    final curvePath = Path();
    curvePath.moveTo(0, size.height * 0.3);
    curvePath.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.1,
      size.width,
      size.height * 0.3,
    );
    canvas.drawPath(curvePath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class TransitionType {
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final Widget Function(
    BuildContext,
    Animation<double>,
    Animation<double>,
    Widget,
  ) builder;

  TransitionType({
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.builder,
  });
}