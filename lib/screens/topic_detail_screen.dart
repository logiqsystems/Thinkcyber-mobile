import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../config/razorpay_config.dart';
import '../services/api_client.dart';
import '../services/razorpay_http_service.dart';
import '../services/wishlist_store.dart';
import '../services/cart_service.dart';
import '../widgets/topic_visuals.dart';
import '../widgets/translated_text.dart';
import 'cart_screen.dart';

const _primaryRed = Color( 0xFF2E7DFF);
const _darkText = Color(0xFF2D3142);
const _lightText = Color(0xFF9094A6);
const _cardBg = Color(0xFFF8F9FA);

Widget _metaPill(IconData icon, String label) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.1),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.white70),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class _PipOverlayManager {
  _PipOverlayManager._();
  static final _PipOverlayManager instance = _PipOverlayManager._();

  OverlayEntry? _entry;

  void showYoutube(
    BuildContext context, {
    required YoutubePlayerController controller,
    required List<_PlaylistItem> queue,
    required int currentIndex,
    VoidCallback? onClose,
  }) {
    close();
    _entry = OverlayEntry(
      builder: (_) => _YoutubePipOverlay(
        controller: controller,
        queue: queue,
        currentIndex: currentIndex,
        onClose: onClose,
      ),
    );
    Overlay.of(context, rootOverlay: true).insert(_entry!);
  }

  void showUploaded(
    BuildContext context, {
    required List<TopicVideo> playlist,
    required int currentIndex,
    VoidCallback? onClose,
  }) {
    close();
    _entry = OverlayEntry(
      builder: (_) => _UploadedPipOverlay(
        playlist: playlist,
        currentIndex: currentIndex,
        onClose: onClose,
      ),
    );
    Overlay.of(context, rootOverlay: true).insert(_entry!);
  }

  void close() {
    _entry?.remove();
    _entry = null;
  }
}

class _DraggablePipFrame extends StatefulWidget {
  const _DraggablePipFrame({required this.child, this.onClose});
  final Widget child;
  final VoidCallback? onClose;

  @override
  State<_DraggablePipFrame> createState() => _DraggablePipFrameState();
}

class _DraggablePipFrameState extends State<_DraggablePipFrame> {
  Offset _offset = const Offset(12, 12);

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    return Positioned(
      left: _offset.dx,
      bottom: _offset.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            final dx = (_offset.dx + details.delta.dx).clamp(8.0, screen.width - 228);
            final dy = (_offset.dy - details.delta.dy).clamp(8.0, screen.height - 180);
            _offset = Offset(dx, dy);
          });
        },
        onTap: widget.onClose,
        child: widget.child,
      ),
    );
  }
}

class _YoutubePipOverlay extends StatelessWidget {
  const _YoutubePipOverlay({
    required this.controller,
    required this.queue,
    required this.currentIndex,
    this.onClose,
  });

  final YoutubePlayerController controller;
  final List<_PlaylistItem> queue;
  final int currentIndex;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final title = queue.isNotEmpty ? queue[currentIndex].title : 'Playing';
    return _DraggablePipFrame(
      onClose: () {
        _PipOverlayManager.instance.close();
        onClose?.call();
      },
      child: _MiniShell(
        title: title,
        body: YoutubePlayer(
          controller: controller,
          showVideoProgressIndicator: true,
        ),
      ),
    );
  }
}

class _UploadedPipOverlay extends StatefulWidget {
  const _UploadedPipOverlay({
    required this.playlist,
    required this.currentIndex,
    this.onClose,
  });

  final List<TopicVideo> playlist;
  final int currentIndex;
  final VoidCallback? onClose;

  @override
  State<_UploadedPipOverlay> createState() => _UploadedPipOverlayState();
}

class _UploadedPipOverlayState extends State<_UploadedPipOverlay> {
  late WebViewController _controller;
  Offset _offset = const Offset(12, 12);

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent('Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36');
    _load(widget.playlist[widget.currentIndex].videoUrl);
  }

  void _load(String url) {
    final htmlContent = '''
    <html><head><style>body,html{margin:0;padding:0;background:#000;}</style></head>
    <body><video controls autoplay style="width:100%;height:100%;object-fit:contain;" src="$url"></video></body></html>
    ''';
    _controller.loadHtmlString(htmlContent);
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.playlist[widget.currentIndex].title;
    return _DraggablePipFrame(
      onClose: () {
        _PipOverlayManager.instance.close();
        widget.onClose?.call();
      },
      child: _MiniShell(
        title: title,
        body: WebViewWidget(controller: _controller),
      ),
    );
  }
}

class _MiniShell extends StatelessWidget {
  const _MiniShell({required this.title, required this.body});
  final String title;
  final Widget body;

  double get width => 220;
  double get height => 140;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(aspectRatio: 16 / 9, child: body),
            Container(
              color: Colors.black87,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 18),
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      _PipOverlayManager.instance.close();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UploadedVideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String title;
  final List<TopicVideo> playlist;
  final int initialIndex;

  const _UploadedVideoPlayerScreen({
    required this.videoUrl,
    required this.title,
    this.playlist = const [],
    this.initialIndex = 0,
  });

  @override
  State<_UploadedVideoPlayerScreen> createState() => _UploadedVideoPlayerScreenState();
}

class _UploadedVideoPlayerScreenState extends State<_UploadedVideoPlayerScreen> {
  late WebViewController _webViewController;
  late List<TopicVideo> _queue;
  late int _currentIndex;
  bool _isMini = false;
  Offset _miniOffset = const Offset(12, 12);
  bool _handedToGlobalPip = false;

  @override
  void initState() {
    super.initState();
    _queue = widget.playlist.isNotEmpty
        ? widget.playlist
        : [TopicVideo(id: 0, title: widget.title, videoUrl: widget.videoUrl, thumbnailUrl: null, description: '')];
    _currentIndex = widget.initialIndex.clamp(0, _queue.length - 1);

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent('Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36');

    _loadVideo(_queue[_currentIndex].videoUrl);
  }

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    final screenWidth = MediaQuery.of(context).size.width;
    final playerHeight = orientation == Orientation.portrait
        ? screenWidth * 9 / 16
        : MediaQuery.of(context).size.height;

    final player = Container(
      color: Colors.black,
      height: playerHeight,
      width: double.infinity,
      child: WebViewWidget(controller: _webViewController),
    );

    Widget portraitBody = SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          player,
          _uploadedMetaSection(),
          _playlistSection(),
        ],
      ),
    );

    return WillPopScope(
      onWillPop: () async {
        if (!_handedToGlobalPip) {
          _handOffToGlobalPip();
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => _handOffToGlobalPip(),
          ),
          title: Text(
            widget.title,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            IconButton(
              icon: Icon(
                _isMini ? Icons.fullscreen : Icons.picture_in_picture_alt_outlined,
                color: Colors.white,
              ),
              onPressed: () => setState(() => _isMini = !_isMini),
            ),
            IconButton(
              icon: const Icon(Icons.open_in_new, color: Colors.white),
              onPressed: _handOffToGlobalPip,
            ),
          ],
        ),
        body: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: orientation == Orientation.portrait
                    ? portraitBody
                    : Row(
                        children: [
                          Expanded(child: player),
                          Container(
                            width: 300,
                            color: Colors.black,
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _uploadedMetaSection(),
                                  const SizedBox(height: 12),
                                  _playlistSection(),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
              if (_isMini)
                _DraggablePipFrame(
                  onClose: () => setState(() => _isMini = false),
                  child: _miniUploaded(player),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniUploaded(Widget player) {
    return GestureDetector(
      onTap: () => setState(() => _isMini = false),
      child: Material(
        color: Colors.transparent,
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 200,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 4)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AspectRatio(aspectRatio: 16 / 9, child: player),
                Container(
                  color: Colors.black87,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _queue[_currentIndex].title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 18),
                        padding: EdgeInsets.zero,
                        onPressed: () => setState(() => _isMini = false),
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
  }

  void _handOffToGlobalPip() {
    if (_handedToGlobalPip) return;
    _handedToGlobalPip = true;
    _PipOverlayManager.instance.showUploaded(
      context,
      playlist: _queue,
      currentIndex: _currentIndex,
      onClose: () {},
    );
    Navigator.of(context).pop();
  }

  void _loadVideo(String url) {
    final htmlContent = '''
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <style>
        body { margin: 0; padding: 0; display: flex; justify-content: center; align-items: center; height: 100vh; background-color: #000; font-family: Arial, sans-serif; }
        .video-container { width: 100%; height: 100%; display: flex; justify-content: center; align-items: center; background-color: #000; }
        video { width: 100%; height: 100%; object-fit: contain; }
      </style>
    </head>
    <body>
      <div class="video-container">
        <video controls controlsList="nodownload" autoplay disablePictureInPicture>
          <source src="$url" type="video/mp4">
          Your browser does not support the video tag.
        </video>
      </div>
    </body>
    </html>
    ''';
    _webViewController.loadHtmlString(htmlContent);
  }

  Widget _uploadedMetaSection() {
    final current = _queue[_currentIndex];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            current.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (current.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              current.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withOpacity(0.72),
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              _metaPill(Icons.play_circle_fill, 'Now playing'),
              const SizedBox(width: 8),
              _metaPill(Icons.screen_rotation, 'Rotate for full screen'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _playlistSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: Text(
            'Playlist',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          itemCount: _queue.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final item = _queue[index];
            final isActive = index == _currentIndex;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _currentIndex = index;
                });
                _loadVideo(item.videoUrl);
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isActive ? Colors.white10 : Colors.white.withOpacity(0.02),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 26,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          '#${index + 1}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withOpacity(isActive ? 1 : 0.9),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.schedule, size: 12, color: Colors.white54),
                              const SizedBox(width: 4),
                              Text(
                                item.duration ?? '',
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      isActive ? Icons.pause_circle_filled : Icons.play_circle_fill,
                      color: Colors.white,
                      size: 26,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class TopicDetailScreen extends StatefulWidget {
  const TopicDetailScreen({super.key, required this.topic, this.fromEnrollments = false});

  final CourseTopic topic;
  final bool fromEnrollments;

  @override
  State<TopicDetailScreen> createState() => _TopicDetailScreenState();
}

class _TopicDetailScreenState extends State<TopicDetailScreen>
    with SingleTickerProviderStateMixin {
  final ThinkCyberApi _api = ThinkCyberApi();
  final WishlistStore _wishlist = WishlistStore.instance;
  late Razorpay _razorpay;
  TopicDetail? _detail;
  bool _loading = true;
  String? _error;
  late TabController _tabController;
  int? _userId;
  String? _userEmail;
  String? _currentOrderId;
  bool _processingCheckout = false;
  bool _isWishlisted = false;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    _tabController = TabController(length: 2, vsync: this);
    _initialize();
    _hydrateWishlist();
  }

  Future<void> _initialize() async {
    final userId = await _loadUser();
    await _fetchDetail(userId: userId);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _api.dispose();
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _fetchDetail({int? userId}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Removed static detail injection after testing
      final resolvedUserId = userId ?? _userId;
      final response = await _api.fetchTopicDetail(
        widget.topic.id,
        userId: resolvedUserId,
      );
      if (!mounted) return;
      setState(() {
        _detail = response.topic;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load course details right now.';
        _loading = false;
      });
    }
  }

  Future<int?> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    int? userId;
    String? email;

    final rawUser = prefs.getString('thinkcyber_user');
    if (rawUser != null && rawUser.isNotEmpty) {
      try {
        final json = jsonDecode(rawUser);
        if (json is Map<String, dynamic>) {
          userId = json['id'] as int?;
          email = json['email'] as String?;
        }
      } catch (_) {
        // Ignore malformed cache and fall back to individual keys.
      }
    }

    userId ??= prefs.getInt('thinkcyber_user_id');
    email ??= prefs.getString('thinkcyber_email');

    if (!mounted) return userId;
    setState(() {
      _userId = userId;
      _userEmail = email;
    });
    return userId;
  }

  Future<void> _hydrateWishlist() async {
    await _wishlist.hydrate();
    if (!mounted) return;
    setState(() {
      _isWishlisted = _wishlist.contains(widget.topic.id);
    });
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    // Handle Razorpay payment success - verify payment and enroll
    debugPrint('✅ Razorpay | Payment Success - PaymentId: ${response.paymentId}');
    
    final messenger = ScaffoldMessenger.of(context);
    final userId = _userId;
    final orderId = _currentOrderId;

    if (userId == null || orderId == null) {
      debugPrint('❌ Razorpay | Missing userId or orderId');
      messenger.showSnackBar(
        const SnackBar(content: TranslatedText('Payment successful!')),
      );
      return;
    }

    try {
      debugPrint('✅ Razorpay | Verifying payment and enrolling user...');
      debugPrint('✅ Razorpay | PaymentId: ${response.paymentId}, OrderId: $orderId');
      
      // Verify payment and auto-enroll
      final enrollResponse = await _api.verifyPaymentAndEnroll(
        userId: userId,
        topicId: widget.topic.id,
        paymentId: response.paymentId!,
        orderId: orderId,
        signature: response.signature!,
      );
      
      if (!mounted) return;

      if (enrollResponse.success) {
        debugPrint('✅ Razorpay | Payment verified and user enrolled successfully!');
        if (mounted) {
          messenger.showSnackBar(
            const SnackBar(
              content: TranslatedText('Payment successful! You are now enrolled.'),
              backgroundColor: Color(0xFF22C55E),
            ),
          );
          
          setState(() {
            // Mark user as enrolled since payment verification succeeded
            _detail = _detail?.copyWith(isEnrolled: true);
          });
        }
        // Don't refresh detail here - user might see buttons flash
        // The UI is already updated with isEnrolled: true
      } else {
        debugPrint('❌ Razorpay | Verification failed: ${enrollResponse.message}');
        messenger.showSnackBar(
          SnackBar(content: Text('Enrollment error: ${enrollResponse.message}')),
        );
      }
    } catch (error, stackTrace) {
      debugPrint('❌ Razorpay | Error verifying payment: $error');
      debugPrint('❌ Razorpay | Stack trace: $stackTrace');
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Error: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _processingCheckout = false);
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    // Handle Razorpay payment failure
    final errorMessage = response.message ?? response.code ?? 'Payment cancelled';
    debugPrint('Razorpay | Payment Error - Code: ${response.code}, Message: ${response.message}');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment failed: $errorMessage')),
    );
    setState(() => _processingCheckout = false);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    // Handle Razorpay external wallet
    final walletName = response.walletName ?? 'Wallet';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('External wallet selected: $walletName')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final summary = widget.topic;
    final detail = _detail;
    final bool summaryEnrolled = summary.isEnrolled;
    final bool detailEnrolled = detail?.isEnrolled ?? false;
    final bool isEnrolled = widget.fromEnrollments || detailEnrolled || summaryEnrolled;
    final bool isFreeCourse = detail?.isFree ?? summary.isFree || summary.price == 0;
    final num priceValue = detail?.price ?? summary.price;
    final String formattedPrice;
    if (priceValue % 1 == 0) {
      formattedPrice = '₹${priceValue.toInt()}';
    } else {
      formattedPrice = '₹${priceValue.toStringAsFixed(2)}';
    }
    final String priceDisplay = isFreeCourse ? 'Free' : formattedPrice;
    final String badgeLabel = isEnrolled ? 'Enrolled' : priceDisplay;
    final heroTag = topicHeroTag(summary.id);
    final heroTitle = (((detail?.title) ?? '').isNotEmpty)
        ? detail!.title
        : summary.title;
    final heroThumbnail = (((detail?.thumbnailUrl) ?? '').isNotEmpty)
        ? detail!.thumbnailUrl
        : summary.thumbnailUrl;
    final Color badgeColor = isEnrolled
        ? const Color(0xFF22C55E)
        : (isFreeCourse ? _primaryRed : const Color(0xFF4A5568));

    final heroHeader = TopicHeroHeader(
      heroTag: heroTag,
      title: heroTitle,
      thumbnailUrl: heroThumbnail,
      badgeLabel: badgeLabel,
      badgeColor: badgeColor,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _darkText),
          onPressed: () => Navigator.pop(context),
        ),
        title: const TranslatedText(
          'Details',
          style: TextStyle(
            color: _darkText,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          if (detail != null)
            IconButton(
              icon: Icon(
                _isWishlisted ? Icons.favorite : Icons.favorite_border,
                color: _isWishlisted ? _primaryRed : _darkText,
              ),
              onPressed: () => _toggleWishlistAction(detail),
              tooltip: _isWishlisted
                  ? 'Remove from wishlist'
                  : 'Add to wishlist',
            ),
        ],
      ),
      body: _loading
          ? ListView(
              padding: EdgeInsets.zero,
              children: [
                heroHeader,
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: CircularProgressIndicator(color: _primaryRed),
                  ),
                ),
              ],
            )
          : _error != null
              ? ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    heroHeader,
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 24,
                      ),
                      child: _DetailError(
                        message: _error!,
                        onRetry: () {
                          _fetchDetail(userId: _userId);
                        },
                      ),
                    ),
                  ],
                )
              : detail == null
                  ? ListView(
                      padding: EdgeInsets.zero,
                      children: [heroHeader],
                    )
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          heroHeader,
                          const SizedBox(height: 12),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TranslatedText(
                                  detail.title,
                                  style: const TextStyle(
                                    color: _darkText,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const TranslatedText(
                                      'By',
                                      style: TextStyle(
                                        color: _lightText,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    TranslatedText(
                                      detail.categoryName,
                                      style: const TextStyle(
                                        color: _darkText,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    // const Spacer(),
                                    // const Icon(
                                    //   Icons.star,
                                    //   color: Color(0xFFFFC107),
                                    //   size: 16,
                                    // ),
                                    // const SizedBox(width: 4),
                                    // const Text(
                                    //   '(4.9)',
                                    //   style: TextStyle(
                                    //     color: _darkText,
                                    //     fontSize: 13,
                                    //     fontWeight: FontWeight.w600,
                                    //   ),
                                    // ),
                                    // const Icon(
                                    //   Icons.star,
                                    //   color: Color(0xFFFFC107),
                                    //   size: 16,
                                    // ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.access_time,
                                      size: 16,
                                      color: _lightText,
                                    ),
                                    const SizedBox(width: 6),
                                    TranslatedText(
                                      detail.durationMinutes > 0
                                          ? '${(detail.durationMinutes / 60).toStringAsFixed(1)}h ${detail.durationMinutes % 60}m'
                                          : 'Self-paced',
                                      style: const TextStyle(
                                        color: _lightText,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    const Icon(
                                      Icons.play_circle_outline,
                                      size: 16,
                                      color: _lightText,
                                    ),
                                    const SizedBox(width: 6),
                                    TranslatedText(
                                      '${_getTotalVideos(detail.modules)} Tutorials',
                                      style: const TextStyle(
                                        color: _lightText,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _TabSection(
                                  tabController: _tabController,
                                  detail: detail,
                                  hasCourseAccess: isEnrolled || isFreeCourse,
                                  isEnrolled: isEnrolled,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
      bottomNavigationBar: !_loading && _error == null && detail != null && !isEnrolled && !widget.fromEnrollments
          ? _BottomBar(
              priceLabel: priceDisplay,
              isFree: isFreeCourse,
              isProcessing: _processingCheckout,
              onBuyNow: () => _handlePurchase(detail, isFreeCourse),
              onAddToCart: _handleAddToCart,
            )
          : null,
    );
  }

  int _getTotalVideos(List<TopicModule> modules) {
    return modules.fold(0, (sum, module) => sum + module.videos.length);
  }

  Future<void> _handlePurchase(TopicDetail detail, bool isFree) async {
    if (_processingCheckout) return;

    final messenger = ScaffoldMessenger.of(context);
    final userId = _userId;
    final email = _userEmail;

    if (userId == null || userId <= 0 || email == null || email.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: TranslatedText('Please sign in to continue with checkout.'),
        ),
      );
      return;
    }

    final isFreeCourse = isFree || detail.isFree || detail.price == 0;

    if (isFreeCourse) {
      setState(() => _processingCheckout = true);
      try {
        final response = await _api.enrollFreeCourse(
          userId: userId,
          topicId: detail.id,
          email: email,
        );

        if (response.success) {
          debugPrint('✅ FreeEnroll | Enrollment successful!');
          if (mounted) {
            messenger.showSnackBar(
              const SnackBar(
                content: TranslatedText('You are now enrolled!'),
                backgroundColor: Color(0xFF22C55E),
              ),
            );
            
            setState(() {
              // Mark user as enrolled since enrollment succeeded
              _detail = _detail?.copyWith(isEnrolled: true);
            });
          }
          // Don't refresh detail here - user might see buttons flash
          // The UI is already updated with isEnrolled: true
        } else {
          final message = response.message.isNotEmpty
              ? response.message
              : 'Unable to enroll in this course.';
          
          debugPrint('❌ FreeEnroll | Enrollment failed: $message');
          messenger.showSnackBar(SnackBar(content: Text(message)));
        }
      } on ApiException catch (error) {
        messenger.showSnackBar(SnackBar(content: Text(error.message)));
      } catch (error, stackTrace) {
        debugPrint('FreeEnroll | Unexpected error $error\n$stackTrace');
        messenger.showSnackBar(
          const SnackBar(
            content: TranslatedText('Unable to enroll right now. Please try again.'),
          ),
        );
      } finally {
        if (mounted) {
          setState(() => _processingCheckout = false);
        }
      }
      return;
    }

    setState(() => _processingCheckout = true);
    try {
      // Step 1: Create order via backend
      debugPrint('✅ Razorpay | Creating order via backend...');
      
      final orderData = await _api.createOrderForCourse(
        userId: userId,
        topicId: detail.id,
        email: email,
      );

      final orderId = orderData['orderId'] as String?;
      final keyId = orderData['keyId'] as String?;
      
      if (orderId == null || keyId == null) {
        throw Exception('Invalid order response from backend');
      }
      
      debugPrint('✅ Razorpay | Order created: $orderId');

      // Step 2: Open Razorpay dialog with the order
      var options = {
        'key': keyId,
        'amount': (detail.price * 100).toInt(), // Amount in paise
        'name': RazorpayConfig.merchantName,
        'description': detail.title,
        'order_id': orderId,
        'prefill': {
          'contact': '',
          'email': email,
        },
        'external': {
          'wallets': RazorpayConfig.supportedWallets,
        }
      };

      // Store orderId for payment verification
      _currentOrderId = orderId;

      try {
        _razorpay.open(options);
      } catch (e) {
        debugPrint('Razorpay | Error opening dialog: $e');
        messenger.showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
        setState(() => _processingCheckout = false);
      }
    } catch (error, stackTrace) {
      debugPrint('Razorpay | Unexpected error creating order: $error\n$stackTrace');
      messenger.showSnackBar(
        const SnackBar(
          content: TranslatedText('Unable to start checkout. Please try again.'),
        ),
      );
      if (mounted) {
        setState(() => _processingCheckout = false);
      }
    }
  }

  Future<void> _toggleWishlistAction(TopicDetail detail) async {
    final added = await _wishlist.toggleCourse(
      summary: widget.topic,
      detail: detail,
    );
    if (!mounted) return;
    setState(() => _isWishlisted = added);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: TranslatedText(added ? 'Added to wishlist' : 'Removed from wishlist'),
      ),
    );
  }

  Future<void> _handleAddToCart() async {
    final cartService = CartService.instance;
    final detail = _detail;
    final topic = widget.topic;
    
    // Check if already in cart
    if (cartService.contains(topic.id)) {
      // If already in cart, navigate to cart screen
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const CartScreen(),
        ),
      );
      return;
    }
    
    // Add to cart
    final added = await cartService.addItem(
      topic: topic,
      detail: detail,
    );
    
    if (!mounted) return;
    
    if (added) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shopping_cart,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              const TranslatedText('Added to cart successfully!'),
            ],
          ),
          backgroundColor: const Color(0xFF22C55E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          action: SnackBarAction(
            label: 'View Cart',  // Note: SnackBarAction doesn't support TranslatedText
            textColor: Colors.white,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CartScreen(),
                ),
              );
            },
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: TranslatedText('This course is already in your cart'),
          backgroundColor: Color(0xFFFF9500),
        ),
      );
    }
  }
}

class TopicHeroHeader extends StatelessWidget {
  const TopicHeroHeader({
    super.key,
    required this.heroTag,
    required this.title,
    required this.thumbnailUrl,
    required this.badgeLabel,
    this.badgeColor,
  });

  final String heroTag;
  final String title;
  final String thumbnailUrl;
  final String badgeLabel;
  final Color? badgeColor;

  @override
  Widget build(BuildContext context) {
    Widget buildImage() {
      return TopicImage(
        imageUrl: thumbnailUrl,
        title: title,
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Hero(
            tag: heroTag,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                height: double.infinity,
                width: double.infinity,
                child: buildImage(),
              ),
            ),
          ),
          Positioned(top: 16, right: 16, child: _HeartBadge()),
          Positioned(
            bottom: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: badgeColor ?? const Color(0xFF4A5568),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TranslatedText(
                badgeLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeartBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B9D), Color(0xFFFFA07A), Color(0xFFFFD700)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.favorite, color: Colors.white, size: 18),
    );
  }
}

class _TabSection extends StatelessWidget {
  const _TabSection({
    required this.tabController,
    required this.detail,
    required this.hasCourseAccess,
    required this.isEnrolled,
  });

  final TabController tabController;
  final TopicDetail detail;
  final bool hasCourseAccess;
  final bool isEnrolled;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(25),
          ),
          child: TabBar(
            controller: tabController,
            indicator: BoxDecoration(
              color: _primaryRed,
              borderRadius: BorderRadius.circular(25),
            ),
            labelColor: Colors.white,
            indicatorSize: TabBarIndicatorSize.tab, // 🔥 makes indicator match tab width

            unselectedLabelColor: _lightText,
            labelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            dividerColor: Colors.transparent,
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const TranslatedText('Playlist'),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${detail.modules.length}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Tab(child: TranslatedText('Descriptions')),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.65, // Use 65% of screen height for more space
          child: TabBarView(
            controller: tabController,
            children: [
              _PlaylistTab(
                modules: detail.modules,
                hasCourseAccess: hasCourseAccess,
                isEnrolled: isEnrolled,
              ),
              _DescriptionTab(detail: detail),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlaylistTab extends StatelessWidget {
  const _PlaylistTab({
    required this.modules,
    required this.hasCourseAccess,
    required this.isEnrolled,
  });

  final List<TopicModule> modules;
  final bool hasCourseAccess;
  final bool isEnrolled;

  @override
  Widget build(BuildContext context) {
    if (modules.isEmpty) {
      return const Center(
        child: TranslatedText(
          'No modules available yet',
          style: TextStyle(color: _lightText, fontSize: 14),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 120), // Increased bottom padding for footer space
      itemCount: modules.length + 1, // Add one more item for footer
      itemBuilder: (context, index) {
        // Show footer at the end
        if (index == modules.length) {
          return _ModulesFooter(totalModules: modules.length);
        }
        
        final module = modules[index];
        final moduleAccess = hasCourseAccess || module.isEnrolled;
        return _ModuleItem(
          index: index + 1,
          module: module,
          hasAccess: moduleAccess,
          showDescriptions: isEnrolled,
        );
      },
    );
  }
}

class _ModuleItem extends StatefulWidget {
  const _ModuleItem({
    required this.index,
    required this.module,
    required this.hasAccess,
    required this.showDescriptions,
  });

  final int index;
  final TopicModule module;
  final bool hasAccess;
  final bool showDescriptions;

  @override
  State<_ModuleItem> createState() => _ModuleItemState();
}

class _ModuleItemState extends State<_ModuleItem> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final module = widget.module;
    final totalDuration = _calculateDuration();
    final hasVideos = module.videos.isNotEmpty;
    final hasDescription = module.description.isNotEmpty;
    final bool isUnlocked = widget.hasAccess;
    final bool shouldShowDescription = widget.showDescriptions && hasDescription;
    final bool canExpand = isUnlocked && (hasVideos || shouldShowDescription);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF8FBFF), Color(0xFFF1F5FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _lightText.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: canExpand
                ? () => setState(() => _expanded = !_expanded)
                : null,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '${widget.index}',
                        style: const TextStyle(
                          color: _darkText,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TranslatedText(
                                module.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: _darkText,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  height: 1.3,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Container(
                            //   padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            //   decoration: BoxDecoration(
                            //     color: isUnlocked
                            //         ? const Color(0xFFE8F6FF)
                            //         : _primaryRed.withValues(alpha: 0.08),
                            //     borderRadius: BorderRadius.circular(12),
                            //   ),
                            //   child: Row(
                            //     mainAxisSize: MainAxisSize.min,
                            //     children: [
                            //       Icon(
                            //         isUnlocked ? Icons.lock_open_rounded : Icons.lock_outline,
                            //         size: 14,
                            //         color: isUnlocked ? _primaryRed : _primaryRed,
                            //       ),
                            //       // const SizedBox(width: 6),
                            //       // TranslatedText(
                            //       //   isUnlocked ? 'Accessible' : 'Locked',
                            //       //   style: const TextStyle(
                            //       //     color: _primaryRed,
                            //       //     fontSize: 11,
                            //       //     fontWeight: FontWeight.w700,
                            //       //   ),
                            //       // ),
                            //     ],
                            //   ),
                            // ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _InfoChip(icon: Icons.movie_filter, label: hasVideos ? '${module.videos.length} lesson${module.videos.length == 1 ? '' : 's'}' : 'No videos yet'),
                            _InfoChip(icon: Icons.schedule, label: hasVideos ? totalDuration : 'Coming soon'),
                            if (shouldShowDescription)
                              const _InfoChip(icon: Icons.menu_book, label: 'Summary ready'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (canExpand)
                    Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      color: _darkText,
                      size: 24,
                    )
                  else if (!isUnlocked)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _primaryRed.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const TranslatedText(
                        'Locked',
                        style: TextStyle(
                          color: _primaryRed,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _lightText.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.lock_clock,
                        color: _lightText,
                        size: 18,
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (_expanded && canExpand)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (shouldShowDescription) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      margin: EdgeInsets.only(bottom: hasVideos ? 12 : 0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _lightText.withOpacity(0.15)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.description_outlined,
                                color: _primaryRed,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              const TranslatedText(
                                'Module Description',
                                style: TextStyle(
                                  color: _darkText,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TranslatedText(
                            module.description,
                            style: const TextStyle(
                              color: _lightText,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  ...module.videos.map((video) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _VideoListItem(
                        video: video,
                        isUnlocked: isUnlocked,
                        playlist: module.videos,
                        initialIndex: module.videos.indexOf(video),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _calculateDuration() {
    if (widget.module.durationMinutes > 0) {
      final minutes = widget.module.durationMinutes;
      final hours = minutes ~/ 60;
      final remaining = minutes % 60;
      if (hours > 0) {
        return '${hours}h ${remaining}m';
      }
      return '${minutes}m';
    }

    if (widget.module.videos.isEmpty) return 'Coming soon';
    final count = widget.module.videos.length;
    return '$count video${count == 1 ? '' : 's'}';
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _lightText.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _primaryRed),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: _darkText,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoListItem extends StatelessWidget {
  const _VideoListItem({
    required this.video,
    required this.isUnlocked,
    this.playlist,
    this.initialIndex = 0,
  });

  final TopicVideo video;
  final bool isUnlocked;
  final List<TopicVideo>? playlist;
  final int initialIndex;

  String _durationLabel() {
    if (video.durationSeconds != null && video.durationSeconds! > 0) {
      final minutes = (video.durationSeconds! / 60).ceil();
      return '${minutes}m';
    }
    if (video.duration != null && video.duration!.isNotEmpty) return video.duration!;
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _handleTap(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14), // Slightly more padding
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _lightText.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isUnlocked
                    ? _primaryRed.withValues(alpha: 0.1)
                    : _lightText.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isUnlocked ? Icons.play_arrow : Icons.lock_outline,
                color: isUnlocked ? _primaryRed : _lightText,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TranslatedText(
                video.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _darkText,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (video.isPreview) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _primaryRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Preview',
                  style: TextStyle(
                    color: _primaryRed,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            if (_durationLabel().isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _durationLabel(),
                  style: const TextStyle(
                    color: _darkText,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Icon(
              isUnlocked ? Icons.chevron_right : Icons.lock_outline,
              color: _lightText,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _handleTap(BuildContext context) {
    if (!isUnlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: TranslatedText('Purchase the course to access this lesson.'),
        ),
      );
      return;
    }

    _playVideo(context, video);
  }

  void _playVideo(BuildContext context, TopicVideo video) {
    String? videoId = _extractYouTubeId(video.videoUrl);

    if (videoId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => _VideoPlayerScreen(
            videoId: videoId,
            title: video.title,
            playlist: playlist ?? [video],
            initialIndex: initialIndex,
          ),
        ),
      );
    } else if (video.videoUrl.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => _UploadedVideoPlayerScreen(
            videoUrl: video.videoUrl,
            title: video.title,
            playlist: playlist ?? [video],
            initialIndex: initialIndex,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: TranslatedText('Unable to play this video')),
      );
    }
  }
}

class _VideoPlayerScreen extends StatefulWidget {
  const _VideoPlayerScreen({
    required this.videoId,
    required this.title,
    this.playlist = const [],
    this.initialIndex = 0,
  });

  final String videoId;
  final String title;
  final List<TopicVideo> playlist;
  final int initialIndex;

  @override
  State<_VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<_VideoPlayerScreen> {
  late YoutubePlayerController _controller;
  bool _isPlayerReady = false;
  bool _isMuted = false;
  late List<_PlaylistItem> _queue;
  late int _currentIndex;
  Duration _position = Duration.zero;
  Duration _total = Duration.zero;
  bool _isMini = false;
  Offset _miniOffset = const Offset(12, 12);
  bool _handedToGlobalPip = false;

  @override
  void initState() {
    super.initState();
    _queue = _buildQueue();
    _currentIndex = _queue.isEmpty
        ? 0
        : widget.initialIndex.clamp(0, _queue.length - 1);
    final initial = _queue.isNotEmpty
        ? _queue[_currentIndex]
        : _PlaylistItem(youtubeId: widget.videoId, title: widget.title);
    // Initialize the controller with your video ID
    _controller = YoutubePlayerController(
      initialVideoId: initial.youtubeId,
      flags: const YoutubePlayerFlags(
        mute: false,
        autoPlay: true, // Set to false if you want manual start
        disableDragSeek: false,
        loop: false,
        isLive: false,
        enableCaption: true, // Shows subtitles if available
        // showVideoProgressIndicator: true,
      ),
    );

    // Listen for player readiness
    _controller.addListener(() {
      // Keep local state in sync with the controller. This ensures the
      // UI (volume icon) correctly reflects the actual player state.
      if (mounted) {
        setState(() {
          _isPlayerReady = _controller.value.isReady;
          _position = _controller.value.position;
          _total = _controller.value.metaData.duration;
          // Note: YoutubePlayerValue doesn't have isMuted property
          // We track mute state manually in _isMuted variable
        });
      }
    });

    // Enable full-screen orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    if (!_handedToGlobalPip) {
      _controller.dispose();
    }
    // Reset orientation to portrait
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentTitle = _queue.isNotEmpty ? _queue[_currentIndex].title : widget.title;
    Widget content;
    if (_queue.isEmpty) {
      content = Center(child: _buildPlayer(currentTitle, aspectRatio: 16 / 9));
    } else {
      final tiles = <Widget>[];
      for (int i = 0; i < _queue.length; i++) {
        if (!_isMini && i == _currentIndex) {
          tiles.add(_currentPlayerSection(currentTitle));
        }
        tiles.add(_playlistTile(i, isActive: i == _currentIndex));
      }

      content = ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: tiles,
      );
    }

    return WillPopScope(
      onWillPop: () async {
        if (!_handedToGlobalPip) {
          _handOffToGlobalPip(currentTitle);
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => _handOffToGlobalPip(currentTitle),
          ),
          title: Text(
            currentTitle,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            IconButton(
              icon: Icon(
                _isMini ? Icons.fullscreen : Icons.picture_in_picture_alt_outlined,
                color: Colors.white,
              ),
              onPressed: () {
                setState(() => _isMini = !_isMini);
              },
            ),
            IconButton(
              icon: const Icon(Icons.open_in_new, color: Colors.white),
              onPressed: () => _handOffToGlobalPip(currentTitle),
            ),
          ],
        ),
        body: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(child: content),
              if (_isMini)
                _DraggablePipFrame(
                  onClose: () => setState(() => _isMini = false),
                  child: _miniCard(currentTitle),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniPlayerCard(String currentTitle) {
    return Draggable(
      feedback: _miniCard(currentTitle),
      childWhenDragging: const SizedBox.shrink(),
      onDragEnd: (d) => setState(() => _miniOffset = d.offset),
      child: Transform.translate(
        offset: _miniOffset,
        child: _miniCard(currentTitle),
      ),
    );
  }

  Widget _miniCard(String currentTitle) {
    return GestureDetector(
      onTap: () => setState(() => _isMini = false),
      child: Material(
        color: Colors.transparent,
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 200,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 4)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildPlayer(currentTitle, aspectRatio: 16 / 9),
                Container(
                  color: Colors.black87,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          currentTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 18),
                        padding: EdgeInsets.zero,
                        onPressed: () => setState(() => _isMini = false),
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
  }

  void _handOffToGlobalPip(String title) {
    if (_handedToGlobalPip) return;
    _handedToGlobalPip = true;
    _PipOverlayManager.instance.showYoutube(
      context,
      controller: _controller,
      queue: _queue,
      currentIndex: _currentIndex,
      onClose: () {
        _controller.dispose();
      },
    );
    Navigator.of(context).pop();
  }

  Widget _currentPlayerSection(String currentTitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPlayer(currentTitle, aspectRatio: 16 / 9),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                currentTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _metaPill(Icons.play_circle_fill, 'Playlist · ${_queue.length}'),
                  const SizedBox(width: 8),
                  _metaPill(Icons.screen_rotation, 'Rotate for full screen'),
                ],
              ),
            ],
          ),
        ),
        const Divider(color: Colors.white12, height: 1),
      ],
    );
  }

  Widget _playlistTile(int index, {required bool isActive}) {
    final item = _queue[index];
    final progress = isActive && _total.inMilliseconds > 0
        ? _position.inMilliseconds.clamp(0, _total.inMilliseconds) /
            _total.inMilliseconds
        : 0.0;
    return GestureDetector(
      onTap: () => _playFromIndex(index),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive ? Colors.white10 : Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 26,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  '#${index + 1}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(isActive ? 1 : 0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (item.description.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        item.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ),
                  Row(
                    children: [
                      if (item.duration != null && item.duration!.isNotEmpty) ...[
                        const Icon(Icons.schedule, size: 12, color: Colors.white54),
                        const SizedBox(width: 4),
                        Text(
                          item.duration!,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      if (item.isPreview) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Preview',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (isActive) ...[
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        minHeight: 4,
                        value: progress.isFinite ? progress : 0,
                        backgroundColor: Colors.white12,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              isActive ? Icons.pause_circle_filled : Icons.play_circle_fill,
              color: Colors.white,
              size: 26,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayer(String currentTitle, {double? aspectRatio}) {
    final ratio = aspectRatio ?? 16 / 9;
    return YoutubePlayerBuilder(
      onExitFullScreen: () {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      },
      player: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
        progressColors: const ProgressBarColors(
          playedColor: Colors.red,
        ),
        topActions: [
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              currentTitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18.0,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          IconButton(
            icon: Icon(
              _isMuted ? Icons.volume_off : Icons.volume_up,
              color: _isMuted ? Colors.grey[400] : Colors.white,
              size: 25.0,
            ),
            onPressed: _toggleMute,
          ),
        ],
        onReady: _hideVideoProgressIndicator,
        onEnded: (_) => _playNext(),
      ),
      builder: (context, player) {
        final content = Column(
          children: [
            AspectRatio(
              aspectRatio: ratio,
              child: player,
            ),
            if (!_isPlayerReady)
              const LinearProgressIndicator(
                backgroundColor: Colors.black,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
              ),
          ],
        );
        return content;
      },
    );
  }

  // Use shared pill helper

  void _playFromIndex(int index) {
    if (index < 0 || index >= _queue.length) return;
    setState(() {
      _currentIndex = index;
    });
    _controller.load(_queue[index].youtubeId);
  }

  void _playNext() {
    if (_queue.isEmpty) return;
    final next = (_currentIndex + 1) % _queue.length;
    _playFromIndex(next);
  }

  void _toggleMute() {
    final willMute = !_isMuted;
    setState(() => _isMuted = willMute);
    if (willMute) {
      try {
        _controller.mute();
        _controller.setVolume(0);
      } catch (_) {}
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: TranslatedText('Video muted'),
          duration: Duration(seconds: 1),
        ),
      );
    } else {
      try {
        _controller.unMute();
        _controller.setVolume(100);
      } catch (_) {}
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: TranslatedText('Video unmuted'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  List<_PlaylistItem> _buildQueue() {
    final items = <_PlaylistItem>[];
    for (final video in widget.playlist) {
      final id = _extractYouTubeId(video.videoUrl);
      if (id != null) {
        items.add(_PlaylistItem(
          youtubeId: id,
          title: video.title,
          duration: video.duration ??
              (video.durationSeconds != null && video.durationSeconds! > 0
                  ? '${(video.durationSeconds! / 60).ceil()}m'
                  : null),
          isPreview: video.isPreview,
          description: video.description,
        ));
      }
    }

    if (items.isEmpty) {
      items.add(_PlaylistItem(
        youtubeId: widget.videoId,
        title: widget.title,
      ));
    }
    return items;
  }

  void _hideVideoProgressIndicator() {
    // Optional: Hide progress after a delay
  }
}

class _PlaylistItem {
  _PlaylistItem({
    required this.youtubeId,
    required this.title,
    this.duration,
    this.isPreview = false,
    this.description = '',
  });

  final String youtubeId;
  final String title;
  final String? duration;
  final bool isPreview;
  final String description;
}

String? _extractYouTubeId(String url) {
  if (url.isEmpty) return null;

  if (url.contains('youtu.be/')) {
    return url.split('youtu.be/').last.split('?').first.split('#').first;
  }
  if (url.contains('youtube.com/watch?v=')) {
    return url.split('v=').last.split('&').first;
  }
  if (url.contains('youtube.com/embed/')) {
    return url.split('embed/').last.split('?').first.split('#').first;
  }
  if (RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(url.trim())) {
    return url.trim();
  }
  if (url.contains('youtube')) {
    final parts = url.split('/');
    for (int i = parts.length - 1; i >= 0; i--) {
      final part = parts[i].split('?').first.split('#').first;
      if (RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(part)) {
        return part;
      }
    }
  }
  return null;
}

class _DescriptionTab extends StatelessWidget {
  const _DescriptionTab({required this.detail});

  final TopicDetail detail;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (detail.description.isNotEmpty) ...[
            const TranslatedText(
              'About Course',
              style: TextStyle(
                color: _darkText,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            TranslatedText(
              detail.description,
              style: const TextStyle(
                color: _lightText,
                fontSize: 14,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),
          ],
          if (detail.learningObjectives.trim().isNotEmpty) ...[
            const TranslatedText(
              'What You\'ll Learn',
              style: TextStyle(
                color: _darkText,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            TranslatedText(
              _cleanText(detail.learningObjectives),
              style: const TextStyle(
                color: _lightText,
                fontSize: 14,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),
          ],
          if (detail.targetAudience.isNotEmpty) ...[
            const TranslatedText(
              'Target Audience',
              style: TextStyle(
                color: _darkText,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: detail.targetAudience
                  .map((audience) => _AudienceChip(text: audience))
                  .toList(),
            ),
            const SizedBox(height: 24),
          ],
          if (detail.prerequisites.trim().isNotEmpty) ...[
            const TranslatedText(
              'Prerequisites',
              style: TextStyle(
                color: _darkText,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            TranslatedText(
              detail.prerequisites,
              style: const TextStyle(
                color: _lightText,
                fontSize: 14,
                height: 1.6,
              ),
            ),
          ],
          const SizedBox(height: 32),
          _DescriptionFooter(),
          const SizedBox(height: 300), // Extra bottom padding to ensure all content is visible
        ],
      ),
    );
  }

  String _cleanText(String text) {
    return text
        .replaceAll('**', '')
        .replaceAll('_', '')
        .replaceAll('|', ' ')
        .trim();
  }
}

class _AudienceChip extends StatelessWidget {
  const _AudienceChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _lightText.withValues(alpha: 0.2)),
      ),
      child: TranslatedText(
        text,
        style: const TextStyle(
          color: _darkText,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.priceLabel,
    required this.isFree,
    required this.isProcessing,
    required this.onBuyNow,
    required this.onAddToCart,
  });

  final String priceLabel;
  final bool isFree;
  final bool isProcessing;
  final VoidCallback onBuyNow;
  final VoidCallback onAddToCart;

  @override
  Widget build(BuildContext context) {
    final label = isFree ? 'Enroll for Free' : 'Buy Now';  // Will be translated below
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            GestureDetector(
              onTap: onAddToCart,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  border: Border.all(color: _primaryRed, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.shopping_cart_outlined,
                  color: _primaryRed,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: isProcessing ? null : onBuyNow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : TranslatedText(
                        label,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            if (!isFree) ...[
              const SizedBox(width: 16),
              Text(
                priceLabel,
                style: const TextStyle(
                  color: _darkText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailError extends StatelessWidget {
  const _DetailError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: _lightText),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _darkText, fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const TranslatedText('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryRed,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DescriptionFooter extends StatelessWidget {
  const _DescriptionFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 30),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _lightText.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _primaryRed.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.info_outline,
              color: _primaryRed,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          const TranslatedText(
            'Ready to Start Learning?',
            style: TextStyle(
              color: _darkText,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          TranslatedText(
            'This course is designed to help you master the fundamentals and advance your skills.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _lightText.withOpacity(0.8),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _primaryRed.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.play_arrow,
                  color: _primaryRed,
                  size: 16,
                ),
                const SizedBox(width: 8),
                const TranslatedText(
                  'Start Learning',
                  style: TextStyle(
                    color: _primaryRed,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModulesFooter extends StatelessWidget {
  const _ModulesFooter({required this.totalModules});

  final int totalModules;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 20, bottom: 40),
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _lightText.withOpacity(0.1)),
      ),
      child: Column( 
        children: [
          TranslatedText(
            'You have reached the end of the playlist. You have access to $totalModules module${totalModules == 1 ? '' : 's'}.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _lightText.withOpacity(0.8),
              fontSize: 13,
              height: 1.4, 
            ),
          ),
        ],
      ),
    );
  }
}
