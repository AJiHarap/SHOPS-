import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:reusehub/core/constants/app_theme.dart';
import 'package:reusehub/features/auth/data/auth_repository.dart';
import 'package:reusehub/shared/widgets/app_button.dart';
import 'package:reusehub/shared/widgets/app_snackbar.dart';
import 'package:reusehub/shared/widgets/app_text_field.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _locationController = TextEditingController();
  XFile? _avatarFile;
  bool _isLoading = false;
  bool _initialized = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _fullNameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (image != null) setState(() => _avatarFile = image);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    setState(() => _isLoading = true);

    try {
      var profile = await ref.read(authRepositoryProvider).getProfile(currentUser.id);
      if (profile == null) return;

      String? avatarUrl = profile.avatarUrl;
      if (_avatarFile != null) {
        final bytes = await _avatarFile!.readAsBytes();
        final ext = _avatarFile!.name.split('.').last;
        final path = '${currentUser.id}/avatar.$ext';
        final client = ref.read(supabaseClientProvider);
        await client.storage.from('avatars').uploadBinary(
              path,
              bytes,
              fileOptions: const FileOptions(upsert: true),
            );
        avatarUrl = client.storage.from('avatars').getPublicUrl(path);
      }

      final updated = profile.copyWith(
        username: _usernameController.text.trim(),
        fullName: _fullNameController.text.trim(),
        bio: _bioController.text.trim(),
        location: _locationController.text.trim(),
        avatarUrl: avatarUrl,
      );

      await ref.read(authRepositoryProvider).upsertProfile(updated);

      if (mounted) {
        AppSnackbar.success(context, 'Profile updated.');
        context.pop();
      }
    } catch (e) {
      if (mounted) AppSnackbar.error(context, 'Failed to update profile: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentProfileProvider);

    return profileAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Edit profile')),
        body: Center(child: Text('Error: $e')),
      ),
      data: (profile) {
        if (profile == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Edit profile')),
            body: const Center(child: Text('Profile not found.')),
          );
        }
        if (!_initialized) {
          _initialized = true;
          _usernameController.text = profile.username;
          _fullNameController.text = profile.fullName ?? '';
          _bioController.text = profile.bio ?? '';
          _locationController.text = profile.location ?? '';
        }

        return Scaffold(
          backgroundColor: AppColors.warmWhite,
          appBar: AppBar(title: const Text('Edit profile')),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              children: [
                Center(
                  child: GestureDetector(
                    onTap: _pickAvatar,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 48,
                          backgroundColor: AppColors.parchment,
                          backgroundImage: _avatarFile != null
                              ? FileImage(File(_avatarFile!.path))
                              : (profile.avatarUrl?.isNotEmpty == true
                                  ? NetworkImage(profile.avatarUrl!) as ImageProvider
                                  : null),
                          child: _avatarFile == null && (profile.avatarUrl?.isEmpty != false)
                              ? Text(
                                  profile.displayName[0].toUpperCase(),
                                  style: AppTypography.displayMedium,
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: AppColors.ember,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt_outlined,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                AppTextField(
                  controller: _fullNameController,
                  label: 'Full name',
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _usernameController,
                  label: 'Username',
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Username is required';
                    if (v.trim().length < 3) return 'At least 3 characters';
                    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v.trim())) {
                      return 'Only letters, numbers, and underscores';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _bioController,
                  label: 'Bio (optional)',
                  hint: 'Tell buyers about yourself or your materials...',
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _locationController,
                  label: 'Location (optional)',
                  hint: 'e.g. Bandung, Jawa Barat',
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 32),
                AppButton(
                  label: 'Save profile',
                  onPressed: _save,
                  isLoading: _isLoading,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
