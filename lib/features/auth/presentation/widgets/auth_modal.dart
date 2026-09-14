import 'dart:ui';
import 'package:flutter/material.dart';
import '../../domain/entities/auth_user.dart';
import '../controllers/auth_controller.dart';

class AuthModal extends StatefulWidget {
  final AuthController? authController;
  final VoidCallback? onAuthSuccess;

  const AuthModal({
    super.key,
    this.authController,
    this.onAuthSuccess,
  });

  static Future<void> show(
    BuildContext context, {
    AuthController? authController,
    VoidCallback? onAuthSuccess,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AuthModal(
        authController: authController,
        onAuthSuccess: onAuthSuccess,
      ),
    );
  }

  @override
  State<AuthModal> createState() => _AuthModalState();
}

class _AuthModalState extends State<AuthModal> with SingleTickerProviderStateMixin {
  late AuthController _auth;
  late TabController _tabController;

  final TextEditingController _emailController = TextEditingController(text: 'reader@scribbleverse.io');
  final TextEditingController _passwordController = TextEditingController(text: 'reader2026');
  final TextEditingController _nameController = TextEditingController(text: 'Arjun');
  final TextEditingController _adminPasskeyController = TextEditingController();

  bool _isSignUp = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _auth = widget.authController ?? AuthController.instance;
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _adminPasskeyController.dispose();
    super.dispose();
  }

  void _handleSignInOrSignUp() async {
    bool success = false;
    if (_isSignUp) {
      success = await _auth.signUpWithEmailPassword(
        email: _emailController.text,
        password: _passwordController.text,
        displayName: _nameController.text,
      );
    } else {
      success = await _auth.signInWithEmailPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
    }

    if (success && mounted) {
      widget.onAuthSuccess?.call();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Welcome, ${_auth.currentUser.displayName}!'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    }
  }

  void _handleGuestSignIn() async {
    final success = await _auth.signInAsGuest();
    if (success && mounted) {
      widget.onAuthSuccess?.call();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Browsing as Guest Reader 🌱'),
          backgroundColor: Color(0xFF6B7280),
        ),
      );
    }
  }

  void _handleAdminSignIn() async {
    final success = await _auth.signInWithAdminPasskey(
      adminPasskey: _adminPasskeyController.text.isEmpty ? 'admin123' : _adminPasskeyController.text,
    );
    if (success && mounted) {
      widget.onAuthSuccess?.call();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('👑 Curator / Admin access granted!'),
          backgroundColor: Color(0xFF8B5CF6),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgGradient = isDark
        ? [const Color(0xFF12141A), const Color(0xFF1A1C24)]
        : [const Color(0xFFF9FAFB), const Color(0xFFF3F4F6)];
    final textColor = isDark ? Colors.white : const Color(0xFF111827);
    final subColor = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF4B5563);
    final cardBg = isDark ? const Color(0xFF1E212B) : Colors.white;
    final borderCol = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08);

    return AnimatedBuilder(
      animation: _auth,
      builder: (context, _) {
        final currentUser = _auth.currentUser;

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.88,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: bgGradient,
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(color: borderCol),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 30,
                  offset: const Offset(0, -10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 44,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Active User Banner
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: currentUser.isAdmin
                        ? const Color(0xFF8B5CF6).withValues(alpha: 0.15)
                        : currentUser.isGuest
                            ? Colors.grey.withValues(alpha: 0.15)
                            : const Color(0xFFD4A373).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: currentUser.isAdmin
                          ? const Color(0xFF8B5CF6).withValues(alpha: 0.4)
                          : currentUser.isGuest
                              ? Colors.grey.withValues(alpha: 0.3)
                              : const Color(0xFFD4A373).withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: cardBg,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          currentUser.avatarEmoji,
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentUser.displayName,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              currentUser.email ?? 'Offline guest session',
                              style: TextStyle(fontSize: 11, color: subColor),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          currentUser.roleBadge,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: currentUser.isAdmin
                                ? const Color(0xFF8B5CF6)
                                : currentUser.isGuest
                                    ? Colors.grey
                                    : const Color(0xFFD4A373),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Error Message if any
                if (_auth.errorMessage != null)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 16, color: Color(0xFFEF4444)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _auth.errorMessage!,
                            style: const TextStyle(fontSize: 12, color: Color(0xFFEF4444)),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _auth.clearError(),
                          child: const Icon(Icons.close_rounded, size: 14, color: Color(0xFFEF4444)),
                        ),
                      ],
                    ),
                  ),

                // Tab Bar
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderCol),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: const Color(0xFFD4A373),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    labelColor: Colors.black,
                    unselectedLabelColor: subColor,
                    labelStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                    tabs: const [
                      Tab(text: 'Member Auth'),
                      Tab(text: 'Guest Mode'),
                      Tab(text: 'Admin Portal'),
                    ],
                  ),
                ),

                // Tab Content
                Flexible(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // 1. Member Auth Tab
                      _buildMemberAuthTab(context, cardBg, borderCol, textColor, subColor),

                      // 2. Guest Mode Tab
                      _buildGuestModeTab(context, cardBg, borderCol, textColor, subColor),

                      // 3. Admin Portal Tab
                      _buildAdminPortalTab(context, cardBg, borderCol, textColor, subColor),
                    ],
                  ),
                ),

                // Quick Demo Persona Switcher Bar at the bottom
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: cardBg.withValues(alpha: 0.5),
                    border: Border(top: BorderSide(color: borderCol)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Demo Switch:',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: subColor),
                      ),
                      Wrap(
                        spacing: 6,
                        children: [
                          _buildRoleChip('🌱 Guest', UserRole.guest, currentUser.role),
                          _buildRoleChip('✨ Member', UserRole.user, currentUser.role),
                          _buildRoleChip('👑 Admin', UserRole.admin, currentUser.role),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRoleChip(String label, UserRole role, UserRole activeRole) {
    final isSelected = activeRole == role;
    return GestureDetector(
      onTap: () async {
        await _auth.switchRole(role);
        if (mounted) {
          widget.onAuthSuccess?.call();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD4A373) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFFD4A373) : Colors.white24,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.black : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildMemberAuthTab(
    BuildContext context,
    Color cardBg,
    Color borderCol,
    Color textColor,
    Color subColor,
  ) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      shrinkWrap: true,
      children: [
        if (_isSignUp) ...[
          TextField(
            controller: _nameController,
            style: TextStyle(color: textColor, fontSize: 14),
            decoration: _inputDecoration('Full Name', Icons.person_outline_rounded, cardBg, borderCol),
          ),
          const SizedBox(height: 10),
        ],
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: TextStyle(color: textColor, fontSize: 14),
          decoration: _inputDecoration('Email Address', Icons.email_outlined, cardBg, borderCol),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          style: TextStyle(color: textColor, fontSize: 14),
          decoration: _inputDecoration(
            'Password',
            Icons.lock_outline_rounded,
            cardBg,
            borderCol,
            suffix: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                size: 18,
                color: subColor,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _auth.isLoading ? null : _handleSignInOrSignUp,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD4A373),
            foregroundColor: Colors.black,
            minimumSize: const Size(double.infinity, 46),
            shape: RoundedRectangleApp(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          child: _auth.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                )
              : Text(
                  _isSignUp ? 'Create Cloud Account' : 'Sign In as Member',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
        ),
        const SizedBox(height: 10),
        Center(
          child: TextButton(
            onPressed: () => setState(() => _isSignUp = !_isSignUp),
            child: Text(
              _isSignUp ? 'Already have an account? Sign In' : 'New reader? Create an account',
              style: const TextStyle(fontSize: 12.5, color: Color(0xFFD4A373)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGuestModeTab(
    BuildContext context,
    Color cardBg,
    Color borderCol,
    Color textColor,
    Color subColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderCol),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shield_outlined, color: Color(0xFF10B981), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Local & Anonymous Reading',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '• Read EPUBs, PDFs & Scanned documents locally.\n'
                  '• Offline multi-voice TTS narration is 100% active.\n'
                  '• No personal email or cloud registration required.',
                  style: TextStyle(fontSize: 12, height: 1.5, color: subColor),
                ),
              ],
            ),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: _auth.isLoading ? null : _handleGuestSignIn,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF374151),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 46),
              shape: RoundedRectangleApp(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: const Text(
              'Continue as Guest Explorer 🌱',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildAdminPortalTab(
    BuildContext context,
    Color cardBg,
    Color borderCol,
    Color textColor,
    Color subColor,
  ) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      shrinkWrap: true,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF8B5CF6), size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Curator & Catalog Access',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF8B5CF6)),
                    ),
                    Text(
                      'Unlock shelf creation, remote catalog sync, and book publishing.',
                      style: TextStyle(fontSize: 11.5, color: subColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _adminPasskeyController,
          obscureText: true,
          style: TextStyle(color: textColor, fontSize: 14),
          decoration: _inputDecoration(
            'Admin Passkey (e.g. admin123)',
            Icons.vpn_key_rounded,
            cardBg,
            borderCol,
          ),
        ),
        const SizedBox(height: 14),
        ElevatedButton(
          onPressed: _auth.isLoading ? null : _handleAdminSignIn,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8B5CF6),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 46),
            shape: RoundedRectangleApp(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          child: _auth.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text(
                  'Unlock Admin Capabilities 👑',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(
    String hint,
    IconData icon,
    Color bg,
    Color border, {
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
      prefixIcon: Icon(icon, size: 18, color: const Color(0xFFD4A373)),
      suffixIcon: suffix,
      filled: true,
      fillColor: bg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFD4A373), width: 1.5),
      ),
    );
  }
}

class RoundedRectangleApp extends RoundedRectangleBorder {
  const RoundedRectangleApp({super.borderRadius});
}
