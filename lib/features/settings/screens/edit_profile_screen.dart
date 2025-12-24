import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rituals_app/theme/app_theme.dart';
import 'package:rituals_app/services/gamification_service.dart';
import 'package:rituals_app/data/models/user_profile.dart';
import 'package:rituals_app/providers/theme_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();

  final GamificationService _gamificationService = GamificationService();
  final ImagePicker _picker = ImagePicker();

  UserProfile? _profile;
  bool _isLoading = true;
  String? _newAvatarBase64;
  File? _newAvatarFile;

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
          _nameController.text = profile?.name ?? '';
          _usernameController.text = profile?.username ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 70, // Convert to JPEG and compress
    );
    if (image != null) {
      final bytes = await File(image.path).readAsBytes();
      final base64String = base64Encode(bytes);

      setState(() {
        _newAvatarFile = File(image.path);
        _newAvatarBase64 = base64String;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      bool success = true;
      String message = 'Profile updated!';

      // 1. Update text fields
      // 1. Update text fields
      final newName = _nameController.text.trim();
      final newUsername = _usernameController.text.trim();

      if (newName != (_profile?.name ?? '') ||
          newUsername != (_profile?.username ?? '')) {
        final textSuccess = await _gamificationService.updateProfile(
          name: newName != (_profile?.name ?? '') ? newName : null,
          username: newUsername != (_profile?.username ?? '')
              ? newUsername
              : null,
        );
        if (!textSuccess) {
          success = false;
          message = 'Failed to update info.';
        }
      }

      // 2. Upload Avatar
      if (_newAvatarBase64 != null) {
        final avatarUrl = await _gamificationService.uploadProfilePicture(
          _newAvatarBase64!,
        );
        if (avatarUrl == null) {
          success = false;
          message = 'Info updated, but avatar failed.';
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: success ? Colors.green : Colors.redAccent,
          ),
        );
        if (success) {
          context.pop(true); // Return result to refresh previous screen
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch theme provider to rebuild on theme changes
    ref.watch(themeModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading && _profile == null) {
      return Scaffold(
        backgroundColor: isDark
            ? AppTheme.darkBackground1
            : AppTheme.lightBackground,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: BackButton(
            color: isDark ? Colors.white : AppTheme.lightTextPrimary,
          ),
        ),
        body: Center(
          child: CircularProgressIndicator(
            color: isDark ? Colors.cyan : AppTheme.primaryColor,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark
          ? AppTheme.darkBackground1
          : AppTheme.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: isDark ? Colors.white : AppTheme.lightTextPrimary),
          onPressed: () => context.pop(),
        ),
        centerTitle: true,
        title: Text(
          'Edit Profile',
          style: TextStyle(color: isDark ? Colors.white : AppTheme.lightTextPrimary),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: isDark ? Colors.cyan : AppTheme.primaryColor,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    'Save',
                    style: TextStyle(
                      color: isDark ? Colors.cyanAccent : AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark ? Colors.cyanAccent : AppTheme.primaryColor,
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: isDark ? Colors.grey[800] : Colors.grey[300],
                          backgroundImage: _newAvatarFile != null
                              ? FileImage(_newAvatarFile!) as ImageProvider
                              : (_profile?.avatarUrl != null
                                    ? NetworkImage(_profile!.avatarUrl!)
                                    : null),
                          onBackgroundImageError:
                              (_newAvatarFile != null ||
                                  _profile?.avatarUrl != null)
                              ? (exception, stackTrace) {}
                              : null,
                          child:
                              (_newAvatarFile == null &&
                                  _profile?.avatarUrl == null)
                              ? Icon(
                                  Icons.person,
                                  size: 50,
                                  color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                                )
                              : null,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.blueAccent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                _buildTextField(
                  controller: _nameController,
                  label: 'Name',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: _usernameController,
                  label: 'Username',
                  icon: Icons.alternate_email,
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'Username required';
                    if (value.length < 3) return 'Too short';
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      controller: controller,
      validator: validator,
      style: TextStyle(color: isDark ? Colors.white : AppTheme.lightTextPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isDark ? Colors.white.withOpacity(0.6) : AppTheme.lightTextSecondary),
        prefixIcon: Icon(icon, color: isDark ? Colors.cyanAccent : AppTheme.primaryColor),
        filled: true,
        fillColor: isDark ? AppTheme.cardColor : AppTheme.lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? Colors.cyanAccent : AppTheme.primaryColor),
        ),
      ),
    );
  }
}
