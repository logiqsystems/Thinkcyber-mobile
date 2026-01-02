import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/razorpay_config.dart';
import '../services/api_client.dart';
import '../services/cart_service.dart';
import '../widgets/translated_text.dart';
import '../widgets/topic_visuals.dart';
import 'topic_detail_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> with SingleTickerProviderStateMixin {
  final CartService _cartService = CartService.instance;
  final ThinkCyberApi _api = ThinkCyberApi();
  late Razorpay _razorpay;
  late AnimationController _animationController;
  bool _isLoading = false;
  int? _userId;
  String? _userEmail;
  String? _currentOrderId;

  @override
  void initState() {
    super.initState();
    _loadCartItems();
    _cartService.addListener(_onCartChanged);
    _initializeRazorpay();
    _loadUserInfo();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animationController.forward();
  }

  void _initializeRazorpay() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final rawUser = prefs.getString('thinkcyber_user');

    if (rawUser != null && rawUser.isNotEmpty) {
      try {
        final json = jsonDecode(rawUser);
        if (json is Map<String, dynamic>) {
          final user = SignupUser.fromJson(json);
          setState(() {
            _userId = user.id;
            _userEmail = user.email;
          });
        }
      } catch (e) {
        debugPrint('Error loading user info: $e');
      }
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    debugPrint('✅ Payment Success: ${response.paymentId}');

    if (_currentOrderId == null) {
      _showSnackBar('Error: Order ID not found', isError: true);
      setState(() => _isLoading = false);
      return;
    }

    try {
      final paidCourses = _cartService.items.where((item) => !item.isFree && item.price > 0).toList();

      if (paidCourses.isEmpty) {
        throw Exception('No paid courses found in cart');
      }

      int enrolledCount = 0;
      for (final item in paidCourses) {
        try {
          final verifyResponse = await _api.verifyPaymentAndEnroll(
            userId: _userId!,
            topicId: item.id,
            paymentId: response.paymentId!,
            orderId: _currentOrderId!,
            signature: response.signature!,
          );

          if (verifyResponse.success) {
            debugPrint('✅ Enrolled in paid course: ${item.title}');
            enrolledCount++;
          } else {
            debugPrint('❌ Failed to enroll in ${item.title}: ${verifyResponse.message}');
          }
        } catch (e) {
          debugPrint('❌ Error enrolling in course ${item.id}: $e');
        }
      }

      if (!mounted) return;

      if (enrolledCount > 0) {
        _showSnackBar('Payment successful! Enrolled in $enrolledCount course(s).', isSuccess: true);
        await _cartService.checkout();
        Navigator.pop(context);
      } else {
        _showSnackBar('Payment successful but enrollment failed.', isError: true);
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Enrollment failed: ${e.toString()}', isError: true);
      setState(() => _isLoading = false);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint('❌ Payment Error: ${response.message}');
    _showSnackBar('Payment failed: ${response.message}', isError: true);
    setState(() => _isLoading = false);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('External Wallet: ${response.walletName}');
    _showSnackBar('${response.walletName} wallet selected');
  }

  void _showSnackBar(String message, {bool isError = false, bool isSuccess = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : (isError ? Icons.error : Icons.info),
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: isSuccess
            ? const Color(0xFF10B981)
            : (isError ? const Color(0xFFEF4444) : const Color(0xFF3B82F6)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: Duration(seconds: isError ? 4 : 3),
      ),
    );
  }

  @override
  void dispose() {
    _razorpay.clear();
    _cartService.removeListener(_onCartChanged);
    _animationController.dispose();
    super.dispose();
  }

  void _onCartChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadCartItems() async {
    await _cartService.hydrate();
  }

  Future<void> _removeItem(int itemId) async {
    await _cartService.removeItem(itemId);
    if (!mounted) return;
    _showSnackBar('Item removed from cart');
  }

  Future<void> _proceedToCheckout() async {
    if (_cartService.isEmpty) {
      _showSnackBar('Your cart is empty', isError: true);
      return;
    }

    if (_userId == null || _userId! <= 0 || _userEmail == null || _userEmail!.isEmpty) {
      _showSnackBar('Please sign in to continue with checkout.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final freeCourses = _cartService.items.where((item) => item.isFree || item.price == 0).toList();
      final paidCourses = _cartService.items.where((item) => !item.isFree && item.price > 0).toList();

      for (final item in freeCourses) {
        try {
          await _api.enrollFreeCourse(
            userId: _userId!,
            topicId: item.id,
            email: _userEmail!,
          );
          debugPrint('✅ Enrolled in free course: ${item.title}');
        } catch (e) {
          debugPrint('❌ Failed to enroll in free course ${item.title}: $e');
        }
      }

      if (paidCourses.isNotEmpty) {
        final totalAmount = paidCourses.fold<double>(0, (sum, item) => sum + item.price);

        debugPrint('✅ Creating order for ${paidCourses.length} paid course(s), total: ₹$totalAmount');

        final orderData = await _api.createOrderForCourse(
          userId: _userId!,
          topicId: paidCourses.first.id,
          email: _userEmail!,
        );

        final orderId = orderData['orderId'] as String?;
        final keyId = orderData['keyId'] as String?;

        if (orderId == null || keyId == null) {
          throw Exception('Invalid order response from backend');
        }

        debugPrint('✅ Order created: $orderId');

        var options = {
          'key': keyId,
          'amount': (totalAmount * 100).toInt(),
          'name': RazorpayConfig.merchantName,
          'description': 'ThinkCyber Course Bundle',
          'order_id': orderId,
          'prefill': {
            'contact': '',
            'email': _userEmail,
          },
          'external': {
            'wallets': RazorpayConfig.supportedWallets,
          }
        };

        _currentOrderId = orderId;

        try {
          _razorpay.open(options);
        } catch (e) {
          debugPrint('Error opening Razorpay: $e');
          _showSnackBar('Error: ${e.toString()}', isError: true);
          setState(() => _isLoading = false);
        }
      } else {
        if (!mounted) return;
        setState(() => _isLoading = false);
        _showSnackBar('Successfully enrolled in all courses!', isSuccess: true);
        await _cartService.checkout();
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnackBar('Checkout failed: ${e.toString()}', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Enhanced App Bar
            _buildAppBar(),

            // Body
            Expanded(
              child: _cartService.isEmpty
                  ? const _EmptyCartWidget()
                  : _buildCartContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
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
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TranslatedText(
                  'Your Cart',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 2),
                TranslatedText(
                  'Ready to start learning?',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          if (!_cartService.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_cartService.itemCount} ${_cartService.itemCount == 1 ? "course" : "courses"}',
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

  Widget _buildCartContent() {
    return Column(
      children: [
        // Cart Items List
        Expanded(
          child: FadeTransition(
            opacity: _animationController,
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: _cartService.items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final item = _cartService.items[index];
                return TweenAnimationBuilder<double>(
                  duration: Duration(milliseconds: 300 + (index * 100)),
                  tween: Tween(begin: 0.0, end: 1.0),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: Opacity(opacity: value, child: child),
                    );
                  },
                  child: _CartItemCard(
                    item: item,
                    onRemove: () => _removeItem(item.id),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => TopicDetailScreen(
                            topic: item.toCourseTopic(),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ),

        // Enhanced Summary Section
        _buildSummarySection(),
      ],
    );
  }

  Widget _buildSummarySection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.receipt_long, color: Color(0xFF3B82F6), size: 20),
                    SizedBox(width: 8),
                    TranslatedText(
                      'Order Summary',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Summary Rows
                _buildSummaryRow(
                  'Courses',
                  '${_cartService.itemCount}',
                  isCount: true,
                ),
                const SizedBox(height: 12),
                _buildSummaryRow(
                  'Subtotal',
                  '₹${_cartService.subtotal.toStringAsFixed(2)}',
                ),

                if (_cartService.subtotal != _cartService.total) ...[
                  const SizedBox(height: 12),
                  _buildSummaryRow(
                    'Discount',
                    '-₹${(_cartService.subtotal - _cartService.total).toStringAsFixed(2)}',
                    isDiscount: true,
                  ),
                ],

                const SizedBox(height: 16),
                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFE2E8F0).withOpacity(0),
                        const Color(0xFFE2E8F0),
                        const Color(0xFFE2E8F0).withOpacity(0),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const TranslatedText(
                      'Total Amount',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '₹${_cartService.total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Checkout Button
                _buildCheckoutButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isCount = false, bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TranslatedText(
          label,
          style: const TextStyle(
            fontSize: 15,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isDiscount ? const Color(0xFF10B981) : const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckoutButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _proceedToCheckout,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: _isLoading
                ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
                : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.lock_outline,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                const TranslatedText(
                  'Proceed to Checkout',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CartItemCard extends StatefulWidget {
  const _CartItemCard({
    required this.item,
    required this.onRemove,
    required this.onTap,
  });

  final CartCourseItem item;
  final VoidCallback onRemove;
  final VoidCallback onTap;

  @override
  State<_CartItemCard> createState() => _CartItemCardState();
}

class _CartItemCardState extends State<_CartItemCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Enhanced Thumbnail
              Container(
                width: 100,
                height: 75,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF667EEA).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: TopicImage(
                        imageUrl: widget.item.thumbnailUrl,
                        title: widget.item.title,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),

                    // Play overlay
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.3),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Course Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TranslatedText(
                            widget.item.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Remove Button
                        GestureDetector(
                          onTap: widget.onRemove,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: Color(0xFFEF4444),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    Row(
                      children: [
                        const Icon(
                          Icons.person_outline,
                          size: 14,
                          color: Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: TranslatedText(
                            widget.item.instructor,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (widget.item.description.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        child: Text(
                          widget.item.description,
                          maxLines: _expanded ? 5 : 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF475569),
                            height: 1.4,
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
                    ],
                    const SizedBox(height: 12),

                    // Price Section
                    Row(
                      children: [
                        if (widget.item.isFree)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF10B981), Color(0xFF059669)],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const TranslatedText(
                              'FREE',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          )
                        else ...[
                          Text(
                            '₹${widget.item.price.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.5,
                            ),
                          ),
                          if (widget.item.isDiscounted && widget.item.originalPrice > widget.item.price) ...[
                            const SizedBox(width: 8),
                            Text(
                              '₹${widget.item.originalPrice.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF94A3B8),
                                decoration: TextDecoration.lineThrough,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${((1 - (widget.item.price / widget.item.originalPrice)) * 100).toInt()}% OFF',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF166534),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}

class _EmptyCartWidget extends StatelessWidget {
  const _EmptyCartWidget();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated Empty State Icon
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 600),
              tween: Tween(begin: 0.0, end: 1.0),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: child,
                );
              },
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF3B82F6).withOpacity(0.1),
                      const Color(0xFF2563EB).withOpacity(0.1),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withOpacity(0.3),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.shopping_cart_outlined,
                    size: 64,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            const TranslatedText(
              'Your Cart is Empty',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            TranslatedText(
              'Start exploring amazing courses and add them to your wishlist to begin your learning journey!',
              style: TextStyle(
                fontSize: 15,
                color: const Color(0xFF64748B),
                height: 1.6,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // Enhanced CTA Button
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 18,
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.explore_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                        SizedBox(width: 12),
                        TranslatedText(
                          'Explore Courses',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
