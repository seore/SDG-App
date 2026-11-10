import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/mission_progress_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/brand.dart';
import '../widgets/motion.dart';

/// Turns API/network exceptions into a sentence a user can act on.
/// The server already sends user-facing messages.
String friendlyAuthError(Object e) {
  if (e is ApiException) return e.message;
  return 'Something went wrong. Please try again.';
}

String? _validateEmail(String? v) {
  final value = v?.trim() ?? '';
  if (value.isEmpty) return 'Enter your email';
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
    return 'Enter a valid email';
  }
  return null;
}

String? _validatePassword(String? v) {
  if ((v ?? '').length < 6) return 'Use at least 6 characters';
  return null;
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;

  void _setMode(bool login) {
    if (login == _isLogin) return;
    HapticFeedback.selectionClick();
    setState(() => _isLogin = login);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: [
                  const FadeSlideIn(child: BrandMark(size: 60)),
                  const SizedBox(height: AppSpacing.lg),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 60),
                    child: Text(
                      'SDG Journey',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 100),
                    child: AnimatedSwitcher(
                      duration: AppDurations.medium,
                      child: Text(
                        _isLogin
                            ? 'Welcome back. Pick up where you left off.'
                            : 'Small actions, global impact. Join in.',
                        key: ValueKey(_isLogin),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const SdgColorBar(),
                  const SizedBox(height: AppSpacing.xl),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 160),
                    child: AppCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _ModeToggle(isLogin: _isLogin, onChanged: _setMode),
                          const SizedBox(height: AppSpacing.xl),
                          AnimatedSize(
                            duration: AppDurations.spring,
                            curve: AppMotion.gentleSpring,
                            alignment: Alignment.topCenter,
                            child: AnimatedSwitcher(
                              duration: AppDurations.medium,
                              transitionBuilder: (child, anim) =>
                                  FadeTransition(
                                opacity: anim,
                                child: SlideTransition(
                                  position: Tween(
                                    begin: Offset(_isLogin ? -0.04 : 0.04, 0),
                                    end: Offset.zero,
                                  ).animate(anim),
                                  child: child,
                                ),
                              ),
                              layoutBuilder: (current, previous) => Stack(
                                alignment: Alignment.topCenter,
                                children: [...previous, ?current],
                              ),
                              child: _isLogin
                                  ? const _LoginForm(key: ValueKey('login'))
                                  : const _SignUpForm(key: ValueKey('signup')),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextButton(
                    onPressed: () => _setMode(!_isLogin),
                    child: Text(
                      _isLogin
                          ? "New here? Create an account"
                          : 'Already have an account? Log in',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Two-option toggle with a sliding, spring-driven indicator.
class _ModeToggle extends StatelessWidget {
  final bool isLogin;
  final ValueChanged<bool> onChanged;

  const _ModeToggle({required this.isLogin, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget option(String label, bool value) => Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onChanged(value),
            child: Center(
              child: AnimatedDefaultTextStyle(
                duration: AppDurations.medium,
                style: TextStyle(
                  fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isLogin == value
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
                child: Text(label),
              ),
            ),
          ),
        );

    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            alignment: isLogin ? Alignment.centerLeft : Alignment.centerRight,
            duration: AppDurations.spring,
            curve: AppMotion.spring,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.sm + 2),
                  boxShadow: AppShadows.card,
                ),
              ),
            ),
          ),
          Row(
            children: [
              option('Log in', true),
              option('Sign up', false),
            ],
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────── Login Form ─────────────────────────────

class _LoginForm extends StatefulWidget {
  const _LoginForm({super.key});

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _loading = true);
    try {
      await AuthService.instance.logIn(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      await MissionProgressService.instance.loadToday();
      navigator.pushNamedAndRemoveUntil('/home', (route) => false);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(friendlyAuthError(e))));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onForgotPassword() async {
    final messenger = ScaffoldMessenger.of(context);
    final email = _emailCtrl.text.trim();
    if (_validateEmail(email) != null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Enter your email above first.')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await AuthService.instance.requestPasswordReset(email);
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
              "If that email has an account, we've sent a reset link. Check your inbox."),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(friendlyAuthError(e))));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            validator: _validateEmail,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.mail_outline_rounded, size: 20),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _passwordCtrl,
            obscureText: _obscure,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            validator: _validatePassword,
            onFieldSubmitted: (_) => _loading ? null : _login(),
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
              suffixIcon: IconButton(
                tooltip: _obscure ? 'Show password' : 'Hide password',
                icon: Icon(_obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _loading ? null : _onForgotPassword,
              child: const Text('Forgot password?'),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _SubmitButton(label: 'Log in', loading: _loading, onPressed: _login),
        ],
      ),
    );
  }
}

// ───────────────────────────── Sign Up Form ────────────────────────────

class _SignUpForm extends StatefulWidget {
  const _SignUpForm({super.key});

  @override
  State<_SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<_SignUpForm> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _loading = true);

    try {
      await AuthService.instance.signUp(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        username: _usernameCtrl.text.trim(),
      );
      navigator.pushNamedAndRemoveUntil('/onboarding', (route) => false);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(friendlyAuthError(e))));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _usernameCtrl,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.newUsername],
            validator: (v) {
              final value = v?.trim() ?? '';
              if (value.length < 2) return 'Choose a username (2+ characters)';
              if (value.length > 24) return 'Keep it under 24 characters';
              return null;
            },
            decoration: const InputDecoration(
              labelText: 'Username',
              prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            validator: _validateEmail,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.mail_outline_rounded, size: 20),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _passwordCtrl,
            obscureText: _obscure,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.newPassword],
            validator: _validatePassword,
            onFieldSubmitted: (_) => _loading ? null : _signUp(),
            decoration: InputDecoration(
              labelText: 'Password',
              helperText: 'At least 6 characters',
              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
              suffixIcon: IconButton(
                tooltip: _obscure ? 'Show password' : 'Hide password',
                icon: Icon(_obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _SubmitButton(
            label: 'Create account',
            loading: _loading,
            onPressed: _signUp,
          ),
        ],
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onPressed;

  const _SubmitButton({
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: loading ? null : onPressed,
      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
      child: AnimatedSwitcher(
        duration: AppDurations.medium,
        child: loading
            ? const SizedBox(
                key: ValueKey('loading'),
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(label, key: ValueKey(label)),
      ),
    );
  }
}
