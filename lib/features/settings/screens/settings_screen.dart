import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rituals_app/theme/app_theme.dart';
import 'package:rituals_app/services/auth_service.dart';
import 'package:rituals_app/services/gamification_service.dart';
import 'package:rituals_app/data/models/user_profile.dart';
import 'package:rituals_app/features/settings/services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Services
  final GamificationService _gamificationService = GamificationService();
  final SettingsService _settingsService = SettingsService();

  // State
  UserProfile? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final profile = await _gamificationService.getMyProfile();
      if (mounted) {
        setState(() {
          _profile = profile;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _togglePremium() async {
    setState(() => _isLoading = true);
    try {
      await AuthService.togglePremium();
      await _loadData(); // Refresh to see changes
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Premium status updated!')),
        );
      }
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout(BuildContext context) async {
    await AuthService.logout();
    if (context.mounted) {
      context.go('/welcome');
    }
  }

  void _navigateToEditProfile() async {
    final result = await context.push('/settings/edit-profile');
    if (result == true) {
      _loadData(); // Refresh data if updated
    }
  }

  void _showSecurityDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text('Security', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Reset Password',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'We will send a password reset link to ${_profile?.email ?? "your email"}.',
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              if (_profile?.email != null) {
                await AuthService.forgotPassword(_profile!.email!);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Reset link sent!')),
                  );
                }
              }
            },
            child: const Text('Reset', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text('About Rituals', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.rocket_launch, color: Colors.cyanAccent, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Rituals App v1.0.2',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Build better habits, manipulate your dopaminergic system, and gamify your life.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.cyanAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _profile == null) {
      return Scaffold(
         backgroundColor: AppTheme.darkBackground1,
         body: const Center(child: CircularProgressIndicator(color: Colors.cyan)),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.darkBackground1,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        centerTitle: true,
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // User Header
              _buildUserHeader(),
              
              const SizedBox(height: 24),
              
              // Unlock Pro Banner
              if (_profile?.isPremium == false) 
                _buildProBanner(),
              
              const SizedBox(height: 32),
              
              // General Section
              _buildSectionHeader('GENERAL'),
              _buildSettingsTile(
                icon: Icons.person,
                title: 'Edit Profile',
                onTap: _navigateToEditProfile,
                showArrow: true,
              ),
              _buildSettingsTile(
                icon: Icons.lock,
                title: 'Security',
                onTap: _showSecurityDialog,
                showArrow: true,
              ),
              
              const SizedBox(height: 24),
              
              // App Experience Section
              _buildSectionHeader('APP EXPERIENCE'),
              _buildSwitchTile(
                icon: Icons.volume_up,
                title: 'Sound Effects',
                getValue: () => _settingsService.soundEffects,
                onChanged: (val) async {
                  await _settingsService.setSoundEffects(val);
                  setState(() {});
                },
              ),
              _buildSettingsTile(
                icon: Icons.dark_mode,
                title: 'Appearance',
                trailing: Text(
                  'Dark', // Static for now as app is dark-only
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
                ),
                showArrow: true,
                onTap: () {},
              ),
              
              const SizedBox(height: 24),
              
              // Support Section
              _buildSectionHeader('SUPPORT & INFO'),
              _buildSettingsTile(
                icon: Icons.help,
                title: 'Help Center',
                trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white.withOpacity(0.5)),
                onTap: () => context.push('/settings/help'),
              ),
              _buildSettingsTile(
                icon: Icons.info,
                title: 'About Rituals',
                showArrow: true,
                onTap: _showAboutDialog,
              ),
              
              const SizedBox(height: 40),
              
              // Footer
              Text(
                'Version 1.0.2',
                style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => _logout(context),
                child: const Text(
                  'Log Out',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserHeader() {
    final username = _profile?.username ?? 'User';
    final title = _profile?.levelTitle ?? 'Novice';
    final level = _profile?.level ?? 1;
    final photoUrl = _profile?.avatarUrl;

    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  width: 2,
                  color: Colors.cyanAccent,
                ),
              ),
              padding: const EdgeInsets.all(4),
              child: CircleAvatar(
                radius: 40,
                backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                onBackgroundImageError: photoUrl != null ? (exception, stackTrace) {} : null,
                backgroundColor: Colors.grey[800], 
                child: photoUrl == null 
                    ? Text(username.isNotEmpty ? username[0].toUpperCase() : '?', style: const TextStyle(fontSize: 30, color: Colors.white)) 
                    : null,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.cyan,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'LVL $level',
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          username,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
            color: Colors.cyanAccent,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildProBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF2C5364), // Dark Teal
            Color(0xFF0F2027), // Deep Dark
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.emoji_events, color: Colors.amber, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Unlock Full Potential',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Join the elite club of habit masters.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () => context.push('/premium'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 0,
            ),
            child: const Text(
              'Unlock',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Widget? trailing,
    bool showArrow = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blueGrey.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.blueAccent.withOpacity(0.8), size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        trailing: trailing ?? (showArrow ? Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white.withOpacity(0.5)) : null),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required bool Function() getValue,
    required Function(bool) onChanged,
    Color activeColor = Colors.cyan,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: activeColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: activeColor, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        trailing: Switch(
          value: getValue(),
          onChanged: onChanged,
          activeColor: activeColor,
          activeTrackColor: activeColor.withOpacity(0.3),
        ),
      ),
    );
  }
}
