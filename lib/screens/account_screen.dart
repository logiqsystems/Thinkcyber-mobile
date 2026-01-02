import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/api_client.dart';
import '../services/localization_service.dart';
import '../services/session_service.dart';
import '../widgets/translated_text.dart';
import 'login_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final ThinkCyberApi _api = ThinkCyberApi();

  bool _loading = true;
  String? _userName;
  String? _userEmail;
  Contact? _contact;
  String? _error;

  // Astonishing palette (clean + cyber premium)
  static const _bg = Color(0xFFF7FAFF);
  static const _text = Color(0xFF0B1220);
  static const _muted = Color(0xFF6B7280);
  static const _line = Color(0xFFE6EAF2);

  static const _blue = Color(0xFF2E7DFF);
  static const _indigo = Color(0xFF5B5CF6);
  static const _cyan = Color(0xFF00D4FF);

  static const _danger = Color(0xFFDC2626);

  @override
  void initState() {
    super.initState();
    _loadAccountData();
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  Future<void> _loadAccountData() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString('thinkcyber_user_name');
      final email = prefs.getString('thinkcyber_email');

      final localization = LocalizationService();
      final languageCode = localization.languageCode;

      final response = await _api.fetchHomepage(languageCode: languageCode);
      if (!mounted) return;

      setState(() {
        _userName = (name == null || name.trim().isEmpty) ? 'User' : name.trim();
        _userEmail = (email == null || email.trim().isEmpty) ? 'Not set' : email.trim();
        _contact = response.data.contact;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load account details.';
        _loading = false;
      });
      debugPrint('Error loading account data: $e');
    }
  }

  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(emailUri)) await launchUrl(emailUri);
  }

  Future<void> _launchPhone(String phone) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(phoneUri)) await launchUrl(phoneUri);
  }

  Future<void> _handleLogout() async {
    await SessionService.clearSession();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  void _showCloseAccountConfirmation() {
    showDialog(
      context: context,
      builder: (context) => _FrostDialog(
        title: 'Close Account',
        subtitle:
        'Are you absolutely sure you want to close your account? This action is permanent and cannot be undone.',
        primaryLabel: 'Close Account',
        primaryColor: _danger,
        onPrimary: () {
          Navigator.pop(context);
          _showFinalCloseAccountWarning();
        },
        secondaryLabel: 'Cancel',
        onSecondary: () => Navigator.pop(context),
      ),
    );
  }

  void _showFinalCloseAccountWarning() {
    showDialog(
      context: context,
      builder: (context) => _FrostDialog(
        title: 'Final Warning',
        subtitle:
        'This is your final chance. All your data will be permanently deleted. Type "CLOSE" to confirm.',
        primaryLabel: 'I Understand',
        primaryColor: _danger,
        onPrimary: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: TranslatedText('Please contact support to close your account.'),
              duration: Duration(seconds: 3),
            ),
          );
        },
        secondaryLabel: 'Cancel',
        onSecondary: () => Navigator.pop(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          const _AuroraBackground(),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                    child: Row(
                      children: [
                        const Expanded(
                          child: TranslatedText(
                            'Account',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.4,
                              color: _text,
                            ),
                          ),
                        ),
                        _IconChip(
                          icon: Icons.refresh_rounded,
                          label: 'Refresh',
                          onTap: _loadAccountData,
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
                    child: _loading
                        ? const _LoadingCard()
                        : _error != null
                        ? _PremiumErrorState(message: _error!, onRetry: _loadAccountData)
                        : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _HeroIdentityCard(
                          name: _userName ?? 'User',
                          email: _userEmail ?? 'Not set',
                          onQuickEmail: (_userEmail != null && _userEmail!.contains('@'))
                              ? () => _launchEmail(_userEmail!)
                              : null,
                        ),
                        const SizedBox(height: 14),

                        // _GlassSection(
                        //   title: 'Profile',
                        //   caption: 'Your saved identity',
                        //   // trailing: _MiniPill(
                        //   //   text: 'Secure',
                        //   //   icon: Icons.verified_user_rounded,
                        //   //   gradient: const [Color(0xFF10B981), Color(0xFF059669)],
                        //   // ),
                        //   child: Column(
                        //     children: [
                        //       _SmartTile(
                        //         icon: Icons.person_outline_rounded,
                        //         title: 'Full Name',
                        //         subtitle: _userName ?? 'Not set',
                        //         tone: _Tone.blue,
                        //         onTap: null,
                        //       ),
                        //       const SizedBox(height: 10),
                        //       _SmartTile(
                        //         icon: Icons.email_outlined,
                        //         title: 'Email',
                        //         subtitle: _userEmail ?? 'Not set',
                        //         tone: _Tone.indigo,
                        //         onTap: (_userEmail != null && _userEmail!.contains('@'))
                        //             ? () => _launchEmail(_userEmail!)
                        //             : null,
                        //         trailingText: (_userEmail != null && _userEmail!.contains('@'))
                        //             ? 'Open'
                        //             : null,
                        //       ),
                        //     ],
                        //   ),
                        // ),

                        if (_contact != null) ...[
                          const SizedBox(height: 14),
                          _GlassSection(
                            title: 'Support',
                            caption: 'Get help instantly',
                            trailing: _MiniPill(
                              text: '24/7',
                              icon: Icons.bolt_rounded,
                              gradient: const [Color(0xFF2E7DFF), Color(0xFF00D4FF)],
                            ),
                            child: Column(
                              children: [
                                if (_contact!.supportEmail.isNotEmpty) ...[
                                  _SmartTile(
                                    icon: Icons.support_agent_rounded,
                                    title: 'Contact Support',
                                    subtitle: _contact!.supportEmail,
                                    tone: _Tone.blue,
                                    onTap: () => _launchEmail(_contact!.supportEmail),
                                    trailingText: 'Email',
                                  ),
                                  const SizedBox(height: 10),
                                ],
                                if (_contact!.phone.isNotEmpty) ...[
                                  _SmartTile(
                                    icon: Icons.call_rounded,
                                    title: 'Call Us',
                                    subtitle: _contact!.phone,
                                    tone: _Tone.green,
                                    onTap: () => _launchPhone(_contact!.phone),
                                    trailingText: 'Call',
                                  ),
                                  const SizedBox(height: 10),
                                ],
                                if (_contact!.email.isNotEmpty)
                                  _SmartTile(
                                    icon: Icons.mail_rounded,
                                    title: 'General Inquiry',
                                    subtitle: _contact!.email,
                                    tone: _Tone.violet,
                                    onTap: () => _launchEmail(_contact!.email),
                                    trailingText: 'Email',
                                  ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 14),
                        _GlassSection(
                          title: 'Security',
                          caption: 'Control your access',
                          trailing: _MiniPill(
                            text: 'Protected',
                            icon: Icons.shield_rounded,
                            gradient: const [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                          ),
                          child: Column(
                            children: [
                              _DangerGlassCard(
                                onCloseAccount: _showCloseAccountConfirmation,
                              ),
                              const SizedBox(height: 12),
                              _GradientButton(
                                label: 'Logout',
                                icon: Icons.logout_rounded,
                                gradient: const [Color(0xFFEF4444), Color(0xFFB91C1C)],
                                onTap: _handleLogout,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 22),
                        Center(
                          child: Text(
                            'ThinkCyber • v1.0',
                            style: TextStyle(
                              fontSize: 12,
                              color: _muted.withOpacity(0.9),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
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

// =========================
// Astonishing UI pieces
// =========================

class _AuroraBackground extends StatelessWidget {
  const _AuroraBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF7FAFF),
                  Color(0xFFF3F7FF),
                  Color(0xFFF8FAFC),
                ],
              ),
            ),
          ),
        ),
        // Blobs
        Positioned(
          top: -120,
          left: -90,
          child: _BlurBlob(color: const Color(0xFF2E7DFF).withOpacity(0.22), size: 240),
        ),
        Positioned(
          top: 120,
          right: -120,
          child: _BlurBlob(color: const Color(0xFF00D4FF).withOpacity(0.18), size: 260),
        ),
        Positioned(
          bottom: -140,
          left: 40,
          child: _BlurBlob(color: const Color(0xFF8B5CF6).withOpacity(0.18), size: 280),
        ),
      ],
    );
  }
}

class _BlurBlob extends StatelessWidget {
  const _BlurBlob({required this.color, required this.size});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: const [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF2E7DFF)),
            ),
            SizedBox(width: 12),
            Text(
              'Loading account...',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0B1220),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconChip extends StatelessWidget {
  const _IconChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.75),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE6EAF2)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF0B1220).withOpacity(0.8)),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0B1220),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroIdentityCard extends StatelessWidget {
  const _HeroIdentityCard({
    required this.name,
    required this.email,
    this.onQuickEmail,
  });

  final String name;
  final String email;
  final VoidCallback? onQuickEmail;

  static const _text = Color(0xFF0B1220);
  static const _muted = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    final initials = _initials(name);

    return _GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2E7DFF), Color(0xFF5B5CF6), Color(0xFF00D4FF)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2E7DFF).withOpacity(0.18),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TranslatedText(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: _text,
                      letterSpacing: -0.25,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: _muted.withOpacity(0.95),
                    ),
                  ),
                  // const SizedBox(height: 10),
                  // Row(
                  //   children: [
                  //     _MiniPill(
                  //       text: 'Premium UI',
                  //       icon: Icons.auto_awesome_rounded,
                  //       gradient: const [Color(0xFF2E7DFF), Color(0xFF5B5CF6)],
                  //     ),
                  //     const SizedBox(width: 10),
                  //     _MiniPill(
                  //       text: 'Private',
                  //       icon: Icons.lock_rounded,
                  //       gradient: const [Color(0xFF0EA5E9), Color(0xFF00D4FF)],
                  //     ),
                  //   ],
                  // ),
                ],
              ),
            ),
            if (onQuickEmail != null) ...[
              const SizedBox(width: 10),
              _RoundAction(
                icon: Icons.mail_rounded,
                onTap: onQuickEmail!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.75),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE6EAF2)),
          ),
          child: Icon(icon, color: const Color(0xFF0B1220).withOpacity(0.85), size: 20),
        ),
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  const _MiniPill({
    required this.text,
    required this.icon,
    required this.gradient,
  });

  final String text;
  final IconData icon;
  final List<Color> gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withOpacity(0.18),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassSection extends StatelessWidget {
  const _GlassSection({
    required this.title,
    required this.caption,
    required this.child,
    this.trailing,
  });

  final String title;
  final String caption;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TranslatedText(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0B1220),
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        caption,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF6B7280).withOpacity(0.95),
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.72),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE6EAF2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 24,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

enum _Tone { blue, indigo, green, violet }

Color _toneColor(_Tone t) {
  switch (t) {
    case _Tone.blue:
      return const Color(0xFF2E7DFF);
    case _Tone.indigo:
      return const Color(0xFF5B5CF6);
    case _Tone.green:
      return const Color(0xFF10B981);
    case _Tone.violet:
      return const Color(0xFF8B5CF6);
  }
}

class _SmartTile extends StatelessWidget {
  const _SmartTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tone,
    this.onTap,
    this.trailingText,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final _Tone tone;
  final VoidCallback? onTap;
  final String? trailingText;

  @override
  Widget build(BuildContext context) {
    final c = _toneColor(tone);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE6EAF2)),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    colors: [c.withOpacity(0.16), c.withOpacity(0.08)],
                  ),
                  border: Border.all(color: c.withOpacity(0.14)),
                ),
                child: Icon(icon, color: c, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0B1220),
                        letterSpacing: -0.15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF6B7280).withOpacity(0.95),
                      ),
                    ),
                  ],
                ),
              ),
              if (trailingText != null) ...[
                // Container(
                //   padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                //   decoration: BoxDecoration(
                //     gradient: LinearGradient(colors: [c, c.withOpacity(0.85)]),
                //     borderRadius: BorderRadius.circular(999),
                //     boxShadow: [
                //       BoxShadow(
                //         color: c.withOpacity(0.18),
                //         blurRadius: 14,
                //         offset: const Offset(0, 8),
                //       ),
                //     ],
                //   ),
                //   child: Text(
                //     trailingText!,
                //     style: const TextStyle(
                //       fontSize: 11,
                //       fontWeight: FontWeight.w900,
                //       color: Colors.white,
                //     ),
                //   ),
                // ),
                const SizedBox(width: 8),
              ],
              Icon(Icons.chevron_right_rounded, color: const Color(0xFF6B7280).withOpacity(0.9)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DangerGlassCard extends StatelessWidget {
  const _DangerGlassCard({required this.onCloseAccount});
  final VoidCallback onCloseAccount;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFDC2626).withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDC2626).withOpacity(0.16)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFEF4444).withOpacity(0.16),
                      const Color(0xFFB91C1C).withOpacity(0.08),
                    ],
                  ),
                  border: Border.all(color: const Color(0xFFDC2626).withOpacity(0.18)),
                ),
                child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626)),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TranslatedText(
                      'Close Account',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0B1220),
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Permanently delete your account',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'This action is permanent and cannot be undone. Your progress and enrollments will be deleted.',
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF6B7280).withOpacity(0.95),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onCloseAccount,
              icon: const Icon(Icons.delete_forever_rounded, size: 18, color: Color(0xFFDC2626)),
              label: const TranslatedText(
                'Close Account',
                style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFDC2626)),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: const Color(0xFFDC2626).withOpacity(0.35)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: gradient),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: gradient.first.withOpacity(0.22),
                blurRadius: 20,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              TranslatedText(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FrostDialog extends StatelessWidget {
  const _FrostDialog({
    required this.title,
    required this.subtitle,
    required this.primaryLabel,
    required this.primaryColor,
    required this.onPrimary,
    required this.secondaryLabel,
    required this.onSecondary,
  });

  final String title;
  final String subtitle;
  final String primaryLabel;
  final Color primaryColor;
  final VoidCallback onPrimary;
  final String secondaryLabel;
  final VoidCallback onSecondary;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.78),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE6EAF2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.10),
                  blurRadius: 26,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TranslatedText(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0B1220),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF6B7280).withOpacity(0.95),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onSecondary,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFE6EAF2)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: TranslatedText(
                          secondaryLabel,
                          style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0B1220)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onPrimary,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: TranslatedText(
                          primaryLabel,
                          style: const TextStyle(fontWeight: FontWeight.w900),
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
    );
  }
}

class _PremiumErrorState extends StatelessWidget {
  const _PremiumErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                color: const Color(0xFF2E7DFF).withOpacity(0.10),
                border: Border.all(color: const Color(0xFF2E7DFF).withOpacity(0.18)),
              ),
              child: const Icon(Icons.wifi_off_rounded, color: Color(0xFF2E7DFF), size: 30),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF0B1220),
                fontSize: 13.5,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Please check your connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFF6B7280).withOpacity(0.95),
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => onRetry(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7DFF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
