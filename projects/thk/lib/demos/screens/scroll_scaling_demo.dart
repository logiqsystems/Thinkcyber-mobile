import 'package:flutter/material.dart';
import 'dart:math' as math;

class ScrollScalingDemo extends StatefulWidget {
  const ScrollScalingDemo({super.key});

  @override
  State<ScrollScalingDemo> createState() => _ScrollScalingDemoState();
}

class _ScrollScalingDemoState extends State<ScrollScalingDemo> {
  final ScrollController _scrollController = ScrollController();
  final List<CardItem> _cards = List.generate(
    20,
    (index) => CardItem(
      title: 'Card ${index + 1}',
      subtitle: 'This is card number ${index + 1} with scroll-based scaling',
      color: Color.lerp(Colors.blue, Colors.purple, index / 19)!,
      image: 'https://picsum.photos/300/200?random=$index',
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      appBar: AppBar(
        title: const Text('Scroll-based Scaling'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: const Text(
              'Scroll down to see cards scale based on their position',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                setState(() {});
                return false;
              },
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _cards.length,
                itemBuilder: (context, index) {
                  return ScalingCard(
                    card: _cards[index],
                    index: index,
                    scrollController: _scrollController,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ScalingCard extends StatelessWidget {
  final CardItem card;
  final int index;
  final ScrollController scrollController;

  const ScalingCard({
    super.key,
    required this.card,
    required this.index,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double itemHeight = 200;
        double itemSpacing = 16;
        double totalItemHeight = itemHeight + itemSpacing;
        
        // Calculate the position of this item
        double scrollOffset = scrollController.hasClients ? scrollController.offset : 0;
        double itemTop = index * totalItemHeight;
        double itemBottom = itemTop + itemHeight;
        
        // Calculate visibility and scale
        double viewportTop = scrollOffset;
        double viewportBottom = scrollOffset + constraints.maxHeight;
        
        double visibilityFactor = 1.0;
        if (itemBottom < viewportTop || itemTop > viewportBottom) {
          // Item is completely outside viewport
          visibilityFactor = 0.0;
        } else {
          // Calculate how much of the item is visible
          double visibleTop = math.max(itemTop, viewportTop);
          double visibleBottom = math.min(itemBottom, viewportBottom);
          double visibleHeight = visibleBottom - visibleTop;
          visibilityFactor = visibleHeight / itemHeight;
        }
        
        // Calculate scale based on position in viewport
        double itemCenter = itemTop + itemHeight / 2;
        double viewportCenter = viewportTop + constraints.maxHeight / 2;
        double distanceFromCenter = (itemCenter - viewportCenter).abs();
        double maxDistance = constraints.maxHeight / 2;
        
        double scale = 1.0;
        if (distanceFromCenter < maxDistance) {
          scale = 0.7 + (0.3 * (1 - distanceFromCenter / maxDistance));
        } else {
          scale = 0.7;
        }
        
        // Apply scaling with smooth animation
        return AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Transform.scale(
            scale: scale,
            child: Card(
              elevation: 8 * scale,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                height: itemHeight - 16,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      card.color,
                      card.color.withOpacity(0.7),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // Background pattern
                    Positioned.fill(
                      child: CustomPaint(
                        painter: GeometricPatternPainter(card.color),
                      ),
                    ),
                    
                    // Content
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  card.title,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  card.subtitle,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'Scale: ${scale.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(40),
                            ),
                            child: Icon(
                              Icons.zoom_in,
                              color: Colors.white,
                              size: 40,
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

class GeometricPatternPainter extends CustomPainter {
  final Color baseColor;

  GeometricPatternPainter(this.baseColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    
    // Draw geometric patterns
    for (int i = 0; i < 3; i++) {
      double x = size.width * 0.7 + i * 20;
      double y = size.height * 0.2 + i * 15;
      
      path.moveTo(x, y);
      path.lineTo(x + 30, y + 15);
      path.lineTo(x + 15, y + 30);
      path.close();
    }
    
    canvas.drawPath(path, paint);
    
    // Draw circles
    for (int i = 0; i < 2; i++) {
      canvas.drawCircle(
        Offset(size.width * 0.8 + i * 25, size.height * 0.6 + i * 20),
        8,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CardItem {
  final String title;
  final String subtitle;
  final Color color;
  final String image;

  CardItem({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.image,
  });
}