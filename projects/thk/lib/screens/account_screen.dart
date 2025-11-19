import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_client.dart';
import '../services/session_service.dart';
import '../widgets/translated_text.dart';
import '../widgets/lottie_loader.dart';
import 'login_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool _loading = true;
  _UserProfile? _profile;

  @override
  void initState() {
    super.initState();
    _hydrateProfile();
  }

  Future<void> _hydrateProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final rawUser = prefs.getString('thinkcyber_user');
    SignupUser? user;

    if (rawUser != null && rawUser.isNotEmpty) {
      try {
        final json = jsonDecode(rawUser);
        if (json is Map<String, dynamic>) {
          user = SignupUser.fromJson(json);
        }
      } catch (_) {
        // Ignore malformed JSON and fall back to individual keys.
      }
    }

    final name =
        user?.name ?? prefs.getString('thinkcyber_user_name') ?? 'Explorer';
    final email = user?.email ?? prefs.getString('thinkcyber_email') ?? '';
    final role = user?.role ?? prefs.getString('thinkcyber_user_role') ?? '';
    final status =
        user?.status ?? prefs.getString('thinkcyber_user_status') ?? '';
    final avatar = user?.avatar;
    final sessionToken = prefs.getString('thinkcyber_session_token');
    final id = user?.id ?? 0;

    if (!mounted) return;

    setState(() {
      _profile = email.isEmpty && (user == null)
          ? null
          : _UserProfile(
              id: id,
              name: name,
              email: email,
              role: role.isNotEmpty ? role : 'student',
              status: status.isNotEmpty ? status : 'pending',
              avatarUrl: avatar,
              sessionToken: sessionToken,
            );
      _loading = false;
    });
  }

  Future<void> _handleLogout() async {
    // Clear session using the session service
    await SessionService.clearSession();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F7FA),
        body: FullScreenLottieLoader(message: 'Loading profile...'),
      );
    }

    if (_profile == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          title: const TranslatedText('Account'),
          backgroundColor: const Color(0xFFF5F7FA),
          elevation: 0,
        ),
        body: _AccountEmptyState(onSignIn: _handleLogout),
      );
    }

    final profile = _profile!;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const TranslatedText('Account'),
        backgroundColor: const Color(0xFFF5F7FA),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _hydrateProfile,
        color: const Color(0xFF2E7DFF),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            _ProfileHeader(profile: profile),
            const SizedBox(height: 24),
            _AccountInfoCard(profile: profile),
            const SizedBox(height: 24),

            _LogoutButton(onLogout: _handleLogout),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile});

  final _UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          _AvatarView(name: profile.name, avatarUrl: profile.avatarUrl),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  profile.email,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    _TagChip(label: profile.role.toUpperCase()),
                    _TagChip(
                      label: profile.status.toUpperCase(),
                      color: profile.status.toLowerCase() == 'active'
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFFFB020),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountInfoCard extends StatelessWidget {
  const _AccountInfoCard({required this.profile});

  final _UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TranslatedText(
            'Profile details',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          _InfoRow(
            label: 'Member ID',
            value: profile.id == 0 ? '—' : '#${profile.id}',
            translateLabel: true,
          ),
          _InfoRow(label: 'Name', value: profile.name, translateLabel: true),
          _InfoRow(label: 'Email', value: profile.email, translateLabel: true),
          _InfoRow(label: 'Role', value: profile.role, translateLabel: true, translateValue: true),
          _InfoRow(label: 'Status', value: profile.status, translateLabel: true, translateValue: true),
        ],
      ),
    );
  }
}


String _tokenPreview(String token) {
  if (token.length <= 8) {
    return token;
  }
  final prefix = token.substring(0, 4);
  final suffix = token.substring(token.length - 4);
  return '$prefix...$suffix';
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.translateLabel = false,
    this.translateValue = false,
  });

  final String label;
  final String value;
  final bool translateLabel;
  final bool translateValue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: translateLabel
                ? TranslatedText(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w600,
                    ),
                  )
                : Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: translateValue
                ? TranslatedText(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF1F2937),
                      fontWeight: FontWeight.w600,
                    ),
                  )
                : Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF1F2937),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _AvatarView extends StatelessWidget {
  const _AvatarView({required this.name, this.avatarUrl});

  final String name;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final initials = name.isNotEmpty ? name.trim()[0].toUpperCase() : 'U';
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 64,
        height: 64,
        color: const Color(0xFF2E7DFF).withValues(alpha: 0.1),
        child: avatarUrl != null && avatarUrl!.isNotEmpty
            ? Image.network(
                avatarUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _Initials(initials: initials),
              )
            : _Initials(initials: initials),
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initials,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: Color(0xFF2E7DFF),
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color ?? const Color(0xFF2E7DFF);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: resolvedColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TranslatedText(
        label,
        style: TextStyle(
          color: resolvedColor,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onLogout,
      icon: const Icon(Icons.logout, color: Color(0xFFFF5757)),
      label: const TranslatedText(
        'Log out',
        style: TextStyle(color: Color(0xFFFF5757), fontWeight: FontWeight.w700),
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xFFFF5757)),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class _AccountEmptyState extends StatelessWidget {
  const _AccountEmptyState({required this.onSignIn});

  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const TranslatedText(
              'No profile found',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2937),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            TranslatedText(
              'Sign in again to load your ThinkCyber profile.',
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onSignIn,
              child: const TranslatedText('Go to login'),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserProfile {
  const _UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    this.avatarUrl,
    this.sessionToken,
  });

  final int id;
  final String name;
  final String email;
  final String role;
  final String status;
  final String? avatarUrl;
  final String? sessionToken;
}
