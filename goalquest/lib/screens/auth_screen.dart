import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/privacy.dart';
import '../services/mission_progress_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/brand.dart';
import '../widgets/motion.dart';
import '../l10n/l10n.dart';

/// Turns API/network exceptions into a sentence a user can act on.
/// The server already sends user-facing messages.
String friendlyAuthError(Object e) {
  if (e is ApiException) return e.message;
  return l10nNow().authGenericError;
}

String? _validateEmail(String? v) {
  final value = v?.trim() ?? '';
  if (value.isEmpty) return l10nNow().enterEmail;
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
    return l10nNow().enterValidEmail;
  }
  return null;
}

String? _validatePassword(String? v) {
  if ((v ?? '').length < 6) return l10nNow().passwordTooShort;
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
                            ? context.l10n.welcomeBack
                            : context.l10n.joinTagline,
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
                          ? context.l10n.newHereCreateAccount
                          : context.l10n.haveAccountLogIn,
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
              option(context.l10n.logIn, true),
              option(context.l10n.signUp, false),
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
        SnackBar(content: Text(context.l10n.enterEmailFirst)),
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
            decoration: InputDecoration(
              labelText: context.l10n.email,
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
              labelText: context.l10n.password,
              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
              suffixIcon: IconButton(
                tooltip: _obscure ? context.l10n.showPassword : context.l10n.hidePassword,
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
              child: Text(context.l10n.forgotPassword),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _SubmitButton(label: context.l10n.logIn, loading: _loading, onPressed: _login),
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
  final _birthYearCtrl = TextEditingController();
  final _parentEmailCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  bool _acceptedPrivacy = false;

  int? get _birthYear => int.tryParse(_birthYearCtrl.text.trim());
  bool get _needsParent =>
      _birthYear != null && _birthYear! > 1900 && needsParentalConsent(_birthYear!);

  @override
  void dispose() {
    _birthYearCtrl.dispose();
    _parentEmailCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    if (!_acceptedPrivacy) {
      messenger.showSnackBar(
        SnackBar(content: Text(context.l10n.agreePrivacyFirst)),
      );
      return;
    }
    setState(() => _loading = true);

    try {
      await AuthService.instance.signUp(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        username: _usernameCtrl.text.trim(),
        birthYear: _birthYear!,
        acceptPrivacy: true,
        parentEmail: _needsParent ? _parentEmailCtrl.text.trim() : null,
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
              if (value.length < 2) return context.l10n.usernameTooShort;
              if (value.length > 24) return context.l10n.usernameTooLong;
              return null;
            },
            decoration: InputDecoration(
              labelText: context.l10n.username,
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
            decoration: InputDecoration(
              labelText: context.l10n.email,
              prefixIcon: Icon(Icons.mail_outline_rounded, size: 20),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _birthYearCtrl,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            maxLength: 4,
            onChanged: (_) => setState(() {}),
            validator: (v) {
              final y = int.tryParse(v?.trim() ?? '');
              final now = DateTime.now().year;
              if (y == null || y < now - 120 || y > now) return context.l10n.enterBirthYear;
              return null;
            },
            decoration: InputDecoration(
              labelText: context.l10n.birthYear,
              hintText: 'e.g. 2011',
              counterText: '',
              prefixIcon: Icon(Icons.cake_outlined, size: 20),
            ),
          ),
          AnimatedSize(
            duration: AppDurations.spring,
            curve: AppMotion.gentleSpring,
            child: !_needsParent
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: Text(
                            "Because you're under $consentAge, a parent or guardian needs to "
                            "approve your account. Until then you can learn and play, but "
                            "nothing is shared with other users.",
                            style: TextStyle(fontSize: 13, color: AppColors.primaryDark),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          controller: _parentEmailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: (v) {
                            final err = _validateEmail(v);
                            if (err != null) return "Enter a parent's email";
                            if (v!.trim().toLowerCase() ==
                                _emailCtrl.text.trim().toLowerCase()) {
                              return "Use your parent's email, not your own";
                            }
                            return null;
                          },
                          decoration: const InputDecoration(
                            labelText: "Parent or guardian's email",
                            prefixIcon: Icon(Icons.family_restroom_rounded, size: 20),
                          ),
                        ),
                      ],
                    ),
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
              labelText: context.l10n.password,
              helperText: context.l10n.passwordHelper,
              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
              suffixIcon: IconButton(
                tooltip: _obscure ? context.l10n.showPassword : context.l10n.hidePassword,
                icon: Icon(_obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Checkbox(
                value: _acceptedPrivacy,
                onChanged: (v) => setState(() => _acceptedPrivacy = v ?? false),
              ),
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(context.l10n.iAgreeToThe, style: const TextStyle(fontSize: 13)),
                    InkWell(
                      onTap: openPrivacyPolicy,
                      child: Text(
                        context.l10n.privacyPolicyLink,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _SubmitButton(
            label: context.l10n.createAccount,
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
