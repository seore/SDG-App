import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/motion.dart';
import '../services/auth_service.dart';
import 'auth_screen.dart' show friendlyAuthError;

class ResetPasswordScreen extends StatefulWidget {
  /// One-time token from the emailed link.
  final String token;

  const ResetPasswordScreen({super.key, required this.token});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() => _loading = true);
    try {
      await AuthService.instance.resetPassword(
        token: widget.token,
        password: _passwordCtrl.text.trim(),
      );
      messenger.showSnackBar(
        const SnackBar(content: Text('Password updated. You can log in now.')),
      );
      navigator.pushNamedAndRemoveUntil('/auth', (r) => false);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(friendlyAuthError(e))));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScaffold(
      title: 'Reset password',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          ContentWidth(
            child: FadeSlideIn(
              child: AppCard(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: IconTile(
                          icon: Icons.lock_reset_rounded,
                          color: AppColors.primary,
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Set a new password',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Choose a new password for your SDG Journey account.',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      TextFormField(
                        controller: _passwordCtrl,
                        obscureText: _obscure,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.newPassword],
                        validator: (v) => (v?.trim().length ?? 0) < 6
                            ? 'Use at least 6 characters'
                            : null,
                        decoration: InputDecoration(
                          labelText: 'New password',
                          prefixIcon:
                              const Icon(Icons.lock_outline_rounded, size: 20),
                          suffixIcon: IconButton(
                            tooltip:
                                _obscure ? 'Show password' : 'Hide password',
                            icon: Icon(_obscure
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _confirmCtrl,
                        obscureText: _obscure,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _loading ? null : _submit(),
                        validator: (v) =>
                            v?.trim() != _passwordCtrl.text.trim()
                                ? "Passwords don't match"
                                : null,
                        decoration: const InputDecoration(
                          labelText: 'Confirm password',
                          prefixIcon: Icon(Icons.lock_outline_rounded, size: 20),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      FilledButton(
                        onPressed: _loading ? null : _submit,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Save new password'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
