import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../services/session_service.dart';
import '../widgets/translated_text.dart';
import 'login_screen.dart';

/// A WebView screen for account closure.
/// Loads the account deletion webpage and listens for postMessage
/// to logout the user upon successful account closure.
class AccountClosureWebViewScreen extends StatefulWidget {
  final String userId;

  const AccountClosureWebViewScreen({
    super.key,
    required this.userId,
  });

  @override
  State<AccountClosureWebViewScreen> createState() => _AccountClosureWebViewScreenState();
}

class _AccountClosureWebViewScreenState extends State<AccountClosureWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _error;
  bool _isProcessingLogout = false;

  static const _bg = Color(0xFFF7FAFF);
  static const _text = Color(0xFF0B1220);

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    final url = 'https://thinkcyber.info/mobile/delete-account/${widget.userId}';
    debugPrint('AccountClosure: Loading URL: $url');

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(_bg)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            debugPrint('AccountClosure: Page started: $url');
            if (mounted) {
              setState(() {
                _isLoading = true;
                _error = null;
              });
            }
          },
          onPageFinished: (String url) {
            debugPrint('AccountClosure: Page finished: $url');
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
            // Inject JavaScript to listen for postMessage and forward to Flutter
            _injectPostMessageListener();
            // Check page content for success indicators
            _checkPageForSuccess();
          },
          onNavigationRequest: (NavigationRequest request) {
            debugPrint('AccountClosure: Navigation request: ${request.url}');
            // Check if URL indicates success
            final urlLower = request.url.toLowerCase();
            if (urlLower.contains('success') ||
                urlLower.contains('deleted') ||
                urlLower.contains('logout') ||
                urlLower.contains('account-closed')) {
              debugPrint('AccountClosure: Success detected in URL');
              _handleAccountClosed();
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('AccountClosure: Web error: ${error.description}');
            if (mounted) {
              setState(() {
                _isLoading = false;
                _error = 'Failed to load page: ${error.description}';
              });
            }
          },
        ),
      )
      ..addJavaScriptChannel(
        'FlutterChannel',
        onMessageReceived: (JavaScriptMessage message) {
          debugPrint('AccountClosure: FlutterChannel message: ${message.message}');
          _handleWebMessage(message.message);
        },
      )
      ..loadRequest(Uri.parse(url));
  }

  /// Check page content for success indicators
  Future<void> _checkPageForSuccess() async {
    try {
      final result = await _controller.runJavaScriptReturningResult('''
        (function() {
          var body = document.body ? document.body.innerText.toLowerCase() : '';
          var hasSuccess = body.includes('successfully') || 
                          body.includes('account deleted') || 
                          body.includes('account closed') ||
                          body.includes('deletion complete');
          return hasSuccess ? 'success' : 'pending';
        })();
      ''');
      debugPrint('AccountClosure: Page check result: $result');
      final resultStr = result.toString().replaceAll('"', '').toLowerCase();
      if (resultStr == 'success') {
        _handleAccountClosed();
      }
    } catch (e) {
      debugPrint('AccountClosure: Error checking page: $e');
    }
  }

  /// Inject JavaScript to capture postMessage events and forward them to Flutter
  void _injectPostMessageListener() {
    _controller.runJavaScript('''
      (function() {
        console.log('FlutterChannel: Injecting listeners');
        
        // Listen for postMessage events
        window.addEventListener('message', function(event) {
          console.log('FlutterChannel: message event received', event.data);
          if (window.FlutterChannel) {
            try {
              var data = typeof event.data === 'string' ? event.data : JSON.stringify(event.data);
              FlutterChannel.postMessage(data);
            } catch(e) {
              FlutterChannel.postMessage(JSON.stringify({type: 'error', message: e.toString()}));
            }
          }
        });
        
        // Also override postMessage to capture direct calls
        var originalPostMessage = window.postMessage;
        window.postMessage = function(message, targetOrigin) {
          console.log('FlutterChannel: postMessage called', message);
          if (window.FlutterChannel) {
            try {
              var data = typeof message === 'string' ? message : JSON.stringify(message);
              FlutterChannel.postMessage(data);
            } catch(e) {}
          }
          return originalPostMessage.apply(window, arguments);
        };
        
        // Also listen for custom events that might be used
        document.addEventListener('accountDeleted', function(e) {
          console.log('FlutterChannel: accountDeleted event');
          if (window.FlutterChannel) {
            FlutterChannel.postMessage(JSON.stringify({type: 'account_deleted', success: true}));
          }
        });
        
        // Monitor for success elements appearing on the page
        var observer = new MutationObserver(function(mutations) {
          var body = document.body ? document.body.innerText.toLowerCase() : '';
          if (body.includes('successfully') || body.includes('account deleted') || body.includes('account closed')) {
            console.log('FlutterChannel: Success text detected in page');
            if (window.FlutterChannel) {
              FlutterChannel.postMessage(JSON.stringify({type: 'success', message: 'Account deleted successfully'}));
            }
            observer.disconnect();
          }
        });
        observer.observe(document.body || document.documentElement, {childList: true, subtree: true, characterData: true});
        
        console.log('FlutterChannel: Listeners injected successfully');
      })();
    ''');
  }

  /// Handle messages received from the webpage
  void _handleWebMessage(String message) {
    debugPrint('AccountClosure: WebView message received: $message');

    if (_isProcessingLogout) {
      debugPrint('AccountClosure: Already processing logout, ignoring message');
      return;
    }

    try {
      // Try to parse as JSON first
      final data = jsonDecode(message);
      debugPrint('AccountClosure: Parsed JSON data: $data');
      
      // Check for success/logout signals
      // Common patterns: {type: 'success'}, {action: 'logout'}, {status: 'deleted'}
      final type = data['type']?.toString().toLowerCase();
      final action = data['action']?.toString().toLowerCase();
      final status = data['status']?.toString().toLowerCase();
      final success = data['success'];
      final msgText = data['message']?.toString().toLowerCase() ?? '';

      debugPrint('AccountClosure: type=$type, action=$action, status=$status, success=$success, msg=$msgText');

      if (type == 'success' ||
          type == 'account_deleted' ||
          type == 'logout' ||
          action == 'logout' ||
          action == 'close_account_success' ||
          status == 'deleted' ||
          status == 'success' ||
          success == true ||
          msgText.contains('success') ||
          msgText.contains('deleted')) {
        debugPrint('AccountClosure: Success condition met, triggering logout');
        _handleAccountClosed();
        return;
      }
    } catch (e) {
      debugPrint('AccountClosure: JSON parse error: $e');
      // Not JSON, check if it's a plain string message
      final lowerMessage = message.toLowerCase();
      if (lowerMessage.contains('success') ||
          lowerMessage.contains('deleted') ||
          lowerMessage.contains('logout') ||
          lowerMessage.contains('account_closed') ||
          lowerMessage.contains('account closed')) {
        debugPrint('AccountClosure: Success keyword found in message, triggering logout');
        _handleAccountClosed();
        return;
      }
    }
  }

  /// Handle successful account closure - logout the user
  Future<void> _handleAccountClosed() async {
    if (_isProcessingLogout) {
      debugPrint('AccountClosure: Already processing logout');
      return;
    }
    
    _isProcessingLogout = true;
    debugPrint('AccountClosure: Processing account closure logout');

    // Show success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: TranslatedText('Account closed successfully. You will be logged out.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }

    // Wait a moment for the user to see the message
    await Future.delayed(const Duration(seconds: 2));

    // Clear session and navigate to login
    debugPrint('AccountClosure: Clearing session');
    await SessionService.clearSession();
    
    debugPrint('AccountClosure: Navigating to login screen');
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: _text),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const TranslatedText(
          'Close Account',
          style: TextStyle(
            color: _text,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          if (_error != null)
            _ErrorView(
              error: _error!,
              onRetry: () {
                setState(() {
                  _error = null;
                  _isLoading = true;
                });
                _initWebView();
              },
            )
          else
            WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7DFF)),
              ),
            ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFDC2626),
              size: 64,
            ),
            const SizedBox(height: 16),
            const TranslatedText(
              'Failed to load page',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0B1220),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const TranslatedText('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7DFF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
