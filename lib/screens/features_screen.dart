import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../services/plan_classifier.dart';
import '../widgets/translated_text.dart';

class FeaturesScreen extends StatefulWidget {
  const FeaturesScreen({super.key});

  @override
  State<FeaturesScreen> createState() => _FeaturesScreenState();
}

class _FeaturesScreenState extends State<FeaturesScreen> with TickerProviderStateMixin {
  final ThinkCyberApi _api = ThinkCyberApi();
  List<FeaturePlan> _plans = [];
  bool _loading = true;
  String? _error;
  int? _selectedPlanId;
  late AnimationController _headerAnimationController;
  late AnimationController _cardsAnimationController;
  late Animation<double> _headerFadeAnimation;
  late Animation<Offset> _headerSlideAnimation;

  @override
  void initState() {
    super.initState();
    _headerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _cardsAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _headerFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _headerAnimationController, curve: Curves.easeOut),
    );
    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _headerAnimationController, curve: Curves.easeOutCubic));

    _loadPlans();
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _cardsAnimationController.dispose();
    _api.dispose();
    super.dispose();
  }

  Future<void> _loadPlans() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await _api.fetchFeaturePlans();
      if (!mounted) return;

      setState(() {
        _plans = response.data;
        _loading = false;
      });

      _headerAnimationController.forward();
      _cardsAnimationController.forward();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load plans. Please try again.';
        _loading = false;
      });
      debugPrint('Error loading plans: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
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
        child: _loading
            ? Center(
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
                      color: const Color(0xFF6366F1).withOpacity(0.3),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                  strokeWidth: 3,
                ),
              ),
            ],
          ),
        )
            : _error != null
            ? Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.red.shade50,
                        Colors.red.shade100,
                      ],
                    ),
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
                    Icons.error_outline_rounded,
                    size: 56,
                    color: Colors.red.shade600,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 28),
                ElevatedButton.icon(
                  onPressed: _loadPlans,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const TranslatedText('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 36,
                      vertical: 18,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    shadowColor: const Color(0xFF6366F1).withOpacity(0.4),
                  ),
                ),
              ],
            ),
          ),
        )
            : _plans.isEmpty
            ? Center(
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
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  size: 48,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 20),
              const TranslatedText(
                'No plans available',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        )
            : RefreshIndicator(
          onRefresh: _loadPlans,
          color: const Color(0xFF6366F1),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Custom Header
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _headerFadeAnimation,
                  child: SlideTransition(
                    position: _headerSlideAnimation,
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(20, 60, 20, 32),
                      child: Column(
                        children: [
                          // Floating badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.auto_awesome_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                SizedBox(width: 8),
                                TranslatedText(
                                  'Premium Learning',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Main title with gradient text effect
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [Colors.white, Color(0xFFE0E7FF)],
                            ).createShader(bounds),
                            child: const TranslatedText(
                              'Choose Your\nLearning Path',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                height: 1.15,
                                letterSpacing: -1,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Subtitle
                          Container(
                            constraints: const BoxConstraints(maxWidth: 300),
                            child: const TranslatedText(
                              'Select the perfect plan tailored to your goals and unlock your potential',
                              style: TextStyle(
                                fontSize: 15,
                                color: Color(0xFFE0E7FF),
                                height: 1.6,
                                fontWeight: FontWeight.w400,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Plans Grid
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final plan = _plans[index];
                      final planType = PlanClassifier.classifyPlan(plan);
                      final isSelected = _selectedPlanId == plan.id;
                      return _buildEnhancedPlanCard(
                        plan,
                        planType,
                        isSelected,
                        index,
                      );
                    },
                    childCount: _plans.length,
                  ),
                ),
              ),

              const SliverPadding(padding: EdgeInsets.only(bottom: 50)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedPlanCard(
      FeaturePlan plan,
      PlanType planType,
      bool isSelected,
      int index,
      ) {
    final colors = {
      PlanType.free: const Color(0xFF10B981),
      PlanType.bundleOnly: const Color(0xFF0EA5E9),
      PlanType.flexible: const Color(0xFF8B5CF6),
      PlanType.individualOnly: const Color(0xFFF59E0B),
    };

    final gradients = {
      PlanType.free: [const Color(0xFF10B981), const Color(0xFF059669)],
      PlanType.bundleOnly: [const Color(0xFF0EA5E9), const Color(0xFF0284C7)],
      PlanType.flexible: [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)],
      PlanType.individualOnly: [const Color(0xFFF59E0B), const Color(0xFFD97706)],
    };

    final bgColors = {
      PlanType.free: const Color(0xFFECFDF5),
      PlanType.bundleOnly: const Color(0xFFE0F2FE),
      PlanType.flexible: const Color(0xFFF5F3FF),
      PlanType.individualOnly: const Color(0xFFFEF3C7),
    };

    final cardColor = colors[planType]!;
    final gradient = gradients[planType]!;
    final bgColor = bgColors[planType]!;
    final features = PlanClassifier.getPlanFeatures(plan);
    final badge = PlanClassifier.getPlanTypeLabel(planType);
    final isPopular = planType == PlanType.flexible;

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + (index * 150)),
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
        onTap: () =>(){}
            // _selectPlan(plan)
        ,
        child: Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? cardColor.withOpacity(0.3)
                    : Colors.black.withOpacity(0.08),
                blurRadius: isSelected ? 30 : 20,
                offset: Offset(0, isSelected ? 12 : 8),
                spreadRadius: isSelected ? 2 : 0,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Main card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected ? cardColor : const Color(0xFFE5E7EB),
                    width: isSelected ? 2.5 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header with gradient
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            bgColor,
                            bgColor.withOpacity(0.5),
                          ],
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(23),
                          topRight: Radius.circular(23),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: gradient),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: cardColor.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: TranslatedText(
                                  badge,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              // Selection indicator
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: gradient),
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color: cardColor.withOpacity(0.25),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Plan name
                          TranslatedText(
                            plan.name,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: cardColor,
                              letterSpacing: -0.5,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Description
                          TranslatedText(
                            plan.description,
                            style: TextStyle(
                              fontSize: 14,
                              color: const Color(0xFF64748B),
                              height: 1.6,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Features section
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: bgColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.star_rounded,
                                  color: cardColor,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'What\'s included',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF6B7280),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // Features list with enhanced styling
                          ...features.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final feature = entry.value;
                            return TweenAnimationBuilder<double>(
                              duration: Duration(milliseconds: 400 + (idx * 100)),
                              tween: Tween(begin: 0.0, end: 1.0),
                              curve: Curves.easeOut,
                              builder: (context, value, child) {
                                return Transform.translate(
                                  offset: Offset(20 * (1 - value), 0),
                                  child: Opacity(
                                    opacity: value,
                                    child: child,
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.only(top: 2),
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(colors: gradient),
                                        borderRadius: BorderRadius.circular(6),
                                        boxShadow: [
                                          BoxShadow(
                                            color: cardColor.withOpacity(0.2),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.check_rounded,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: TranslatedText(
                                        feature,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF475569),
                                          height: 1.6,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),

                          // const SizedBox(height: 24),

                          // CTA Button
                          // _buildEnhancedButton(
                          //   label: isSelected ? 'Selected' : 'Choose Plan',
                          //   gradient: gradient,
                          //   onTap: isSelected ? null : () => _selectPlan(plan),
                          //   isSelected: isSelected,
                          // ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Popular badge (optional)
              // if (isPopular)
              //   Row(mainAxisAlignment: MainAxisAlignment.end,
              //     children: [
              //       Container(
              //         padding: const EdgeInsets.symmetric(
              //           horizontal: 16,
              //           vertical: 8,
              //         ),
              //         decoration: BoxDecoration(
              //           gradient: const LinearGradient(
              //             colors: [Color(0xFFEC4899), Color(0xFFDB2777)],
              //           ),
              //           borderRadius: BorderRadius.circular(20),
              //           boxShadow: [
              //             BoxShadow(
              //               color: const Color(0xFFEC4899).withOpacity(0.4),
              //               blurRadius: 12,
              //               offset: const Offset(0, 4),
              //             ),
              //           ],
              //         ),
              //         child: const Row(
              //           mainAxisSize: MainAxisSize.min,
              //           children: [
              //             Icon(Icons.trending_up, color: Colors.white, size: 14),
              //             SizedBox(width: 6),
              //             Text(
              //               'MOST POPULAR',
              //               style: TextStyle(
              //                 fontSize: 11,
              //                 fontWeight: FontWeight.w800,
              //                 color: Colors.white,
              //                 letterSpacing: 0.8,
              //               ),
              //             ),
              //           ],
              //         ),
              //       ),
              //     ],
              //   ),

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedButton({
    required String label,
    required List<Color> gradient,
    VoidCallback? onTap,
    bool isSelected = false,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? null
                  : LinearGradient(colors: gradient),
              color: isSelected ? const Color(0xFFF3F4F6) : null,
              borderRadius: BorderRadius.circular(16),
              border: isSelected
                  ? Border.all(color: gradient[0], width: 2)
                  : null,
              boxShadow: !isSelected
                  ? [
                BoxShadow(
                  color: gradient[0].withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isSelected)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: gradient[0],
                      size: 20,
                    ),
                  ),
                TranslatedText(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? gradient[0] : Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
                if (!isSelected)
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // void _selectPlan(FeaturePlan plan) {
  //   setState(() {
  //     _selectedPlanId = _selectedPlanId == plan.id ? null : plan.id;
  //   });
  //
  //   if (_selectedPlanId == plan.id) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Row(
  //           children: [
  //             Container(
  //               padding: const EdgeInsets.all(8),
  //               decoration: BoxDecoration(
  //                 color: Colors.white.withOpacity(0.2),
  //                 borderRadius: BorderRadius.circular(8),
  //               ),
  //               child: const Icon(
  //                 Icons.check_circle_rounded,
  //                 color: Colors.white,
  //                 size: 20,
  //               ),
  //             ),
  //             const SizedBox(width: 12),
  //             Expanded(
  //               child: Text(
  //                 '${plan.name} selected!',
  //                 style: const TextStyle(
  //                   fontSize: 15,
  //                   fontWeight: FontWeight.w600,
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //         backgroundColor: const Color(0xFF1F2937),
  //         behavior: SnackBarBehavior.floating,
  //         shape: RoundedRectangleBorder(
  //           borderRadius: BorderRadius.circular(16),
  //         ),
  //         margin: const EdgeInsets.all(16),
  //         elevation: 8,
  //         duration: const Duration(seconds: 2),
  //       ),
  //     );
  //   }
  // }
}
