# Flutter Animation Demos

A comprehensive collection of Flutter animation demos showcasing advanced UI/UX techniques and smooth transitions.

## Features Implemented

### 1. Scroll-based Card Scaling
**Location:** `lib/demos/screens/scroll_scaling_demo.dart`

- **Implementation:** `NotificationListener<ScrollNotification>` + `Transform.scale`
- **Features:**
  - Real-time scaling based on scroll position
  - Cards scale from 0.7 to 1.0 based on viewport position
  - Smooth animation with performance optimization
  - Custom geometric pattern painting
  - Dynamic elevation changes

**Usage:**
```dart
NotificationListener<ScrollNotification>(
  onNotification: (notification) {
    setState(() {}); // Trigger rebuild for scaling
    return false;
  },
  child: ListView.builder(
    itemBuilder: (context, index) {
      return ScalingCard(
        scrollController: scrollController,
        // ... other properties
      );
    },
  ),
)
```

### 2. Smooth List Scrolling
**Location:** `lib/demos/screens/smooth_scrolling_demo.dart`

- **Implementation:** `CustomScrollView` + `SliverList` + `BouncingScrollPhysics`
- **Features:**
  - Physics-based smooth scrolling
  - SliverAppBar with expandable header
  - Animated FAB that appears/disappears on scroll
  - Hover effects with scale transformations
  - Progress indicators with animated content

**Usage:**
```dart
CustomScrollView(
  physics: const BouncingScrollPhysics(
    parent: AlwaysScrollableScrollPhysics(),
  ),
  slivers: [
    SliverAppBar(
      expandedHeight: 200,
      floating: true,
      pinned: true,
      // ...
    ),
    SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => SmoothScrollItem(item: items[index]),
      ),
    ),
  ],
)
```

### 3. Animated Card Transitions
**Location:** `lib/demos/screens/animated_transitions_demo.dart`

- **Implementation:** Multiple `Hero` widgets with custom tags
- **Features:**
  - Hero animations between screens
  - Multiple Hero widgets (icon, title, etc.)
  - Staggered grid animations
  - Custom transition curves
  - Animated statistics counters

**Usage:**
```dart
Hero(
  tag: 'unique_hero_tag',
  child: Widget(), // Your widget
)

// Navigation with custom page transition
Navigator.push(
  context,
  PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => DetailScreen(),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  ),
);
```

### 4. Floating Search Bar with Animation
**Location:** `lib/demos/screens/floating_search_demo.dart`

- **Implementation:** `AnimatedPositioned` + `SliverAppBar` + search logic
- **Features:**
  - Floating search bar that moves with scroll
  - Real-time search filtering
  - Animated search suggestions
  - Smooth expand/collapse animations
  - Voice search icon toggle

**Usage:**
```dart
AnimatedPositioned(
  duration: const Duration(milliseconds: 200),
  top: searchBarTop, // Dynamic position based on scroll
  left: 16,
  right: 16,
  child: Container(
    // Search bar content
  ),
)
```

### 5. Bottom Modal Sheet for Details
**Location:** `lib/demos/screens/modal_sheet_demo.dart`

- **Implementation:** `showModalBottomSheet` with `isScrollControlled` + `BackdropFilter`
- **Features:**
  - Full-screen modal with `isScrollControlled: true`
  - Blur effect using `BackdropFilter`
  - Animated fade and slide transitions
  - Draggable scrollable sheet
  - Custom close animations

**Usage:**
```dart
showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  builder: (context) => Stack(
    children: [
      // Backdrop blur
      Positioned.fill(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(color: Colors.black.withOpacity(0.3)),
        ),
      ),
      // Modal content
      DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, scrollController) => YourContent(),
      ),
    ],
  ),
);
```

### 6. Smooth Blur/Fade When Sheet Opens
- **Implementation:** `AnimatedOpacity` + `BackdropFilter` with animation controllers
- **Features:**
  - Coordinated blur and fade animations
  - Smooth entry and exit transitions
  - Performance-optimized blur effects

### 7. Page-to-Page Animation
**Location:** `lib/demos/screens/page_transitions_demo.dart`

- **Implementation:** `PageRouteBuilder` + `go_router` transitions
- **Features:**
  - 6 different transition types:
    - Slide Left/Right
    - Slide Up/Down  
    - Scale + Fade
    - Rotation
    - 3D Flip
    - Elastic Bounce
  - Custom transition curves
  - Configurable durations
  - Interactive demo cards

**Usage:**
```dart
// With go_router
GoRoute(
  path: '/page',
  pageBuilder: (context, state) => CustomTransitionPage(
    child: YourPage(),
    transitionDuration: Duration(milliseconds: 800),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      );
    },
  ),
)

// With PageRouteBuilder
Navigator.push(
  context,
  PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => NewPage(),
    transitionDuration: Duration(milliseconds: 800),
    transitionsBuilder: yourCustomTransition,
  ),
);
```

## Required Dependencies

Add these to your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  go_router: ^14.6.2
  modal_bottom_sheet: ^3.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
```

## Running the Demos

1. **Setup:**
   ```bash
   flutter pub get
   ```

2. **Run the demo app:**
   ```dart
   // In your main.dart
   import 'package:flutter/material.dart';
   import 'demos/demo_main.dart';

   void main() {
     runApp(DemoApp());
   }
   ```

3. **Or run individual demos:**
   ```dart
   // Import and use any specific demo screen
   import 'demos/screens/scroll_scaling_demo.dart';
   
   class MyApp extends StatelessWidget {
     @override
     Widget build(BuildContext context) {
       return MaterialApp(
         home: ScrollScalingDemo(),
       );
     }
   }
   ```

## Project Structure

```
lib/
├── demos/
│   ├── demo_main.dart              # Main demo app with navigation
│   └── screens/
│       ├── scroll_scaling_demo.dart        # Scroll-based scaling
│       ├── smooth_scrolling_demo.dart      # CustomScrollView + SliverList  
│       ├── animated_transitions_demo.dart  # Hero widget animations
│       ├── floating_search_demo.dart       # AnimatedPositioned + SliverAppBar
│       ├── modal_sheet_demo.dart          # Modal sheets with blur
│       └── page_transitions_demo.dart      # PageRouteBuilder transitions
└── demo_runner.dart               # Simple runner for demos
```

## Key Animation Concepts Demonstrated

1. **Performance Optimization:**
   - Using `RepaintBoundary` for complex widgets
   - Efficient `AnimationController` management
   - Proper disposal of animation resources

2. **Animation Composition:**
   - Combining multiple animations (scale + fade + slide)
   - Staggered animations with delays
   - Coordinated animation sequences

3. **Physics-Based Animations:**
   - `BouncingScrollPhysics` for natural feel
   - Elastic curves for bouncy effects
   - Custom animation curves

4. **Interactive Animations:**
   - Hover effects with `onHover`
   - Gesture-based animations
   - Scroll-driven animations

5. **Advanced Transitions:**
   - Custom page transitions
   - Hero animations across screens
   - 3D transform effects

## Performance Tips

1. **Use `const` constructors** where possible
2. **Dispose animation controllers** properly
3. **Use `RepaintBoundary`** for complex animated widgets
4. **Limit rebuild scope** with `AnimatedBuilder`
5. **Use `TweenAnimationBuilder`** for simple animations

## Customization

Each demo is highly customizable:

- **Colors:** Modify gradient colors and theme colors
- **Durations:** Adjust animation timing
- **Curves:** Change animation curves for different feels
- **Physics:** Modify scroll physics parameters
- **Transitions:** Create your own transition builders

## Browser/Platform Support

- ✅ **Android:** Full support with hardware acceleration
- ✅ **iOS:** Smooth 60fps animations
- ✅ **Web:** Works with slight performance considerations
- ✅ **Desktop:** Full support on Windows/macOS/Linux

## Contributing

Feel free to extend these demos with:
- More transition types
- Additional animation combinations  
- Performance optimizations
- Platform-specific enhancements

## License

MIT License - Feel free to use in your projects!