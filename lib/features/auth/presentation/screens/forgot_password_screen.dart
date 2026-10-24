import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/auth_repository.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_snackbar.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendReset() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await ref.read(authRepositoryProvider).resetPassword(
            _emailController.text.trim(),
          );
      if (mounted) setState(() => _sent = true);
    } on AuthException catch (e) {
      if (mounted) AppSnackbar.error(context, e.message);
    } catch (e) {
      if (mounted) AppSnackbar.error(context, 'Failed to send reset email.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmWhite,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Reset password'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: _sent ? _buildConfirmation() : _buildForm(),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Forgot your\npassword?', style: AppTypography.headlineLarge),
          const SizedBox(height: 12),
          Text(
            'Enter your email and we will send a reset link.',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.warmGrey),
          ),
          const SizedBox(height: 32),
          AppTextField(
            controller: _emailController,
            label: 'Email',
            hint: 'your@email.com',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _sendReset(),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email is required';
              if (!v.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 24),
          AppButton(
            label: 'Send reset link',
            onPressed: _sendReset,
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.mark_email_read_outlined, size: 48, color: AppColors.ember),
        const SizedBox(height: 24),
        Text('Check your inbox', style: AppTypography.headlineLarge),
        const SizedBox(height: 12),
        Text(
          'A reset link was sent to ${_emailController.text.trim()}. Check your spam folder if it does not arrive.',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.warmGrey),
        ),
        const SizedBox(height: 32),
        AppButton(
          label: 'Back to sign in',
          onPressed: () => context.go('/auth/login'),
          isLoading: false,
        ),
      ],
    );
  }
}
