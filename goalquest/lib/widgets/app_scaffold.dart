import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Standard page shell: neutral background and a clean, flat app bar.
class AppScaffold extends StatelessWidget {
  final String? title;
  final Widget body;
  final List<Widget>? actions;
  final bool showAppBar;
  final Color? backgroundColor;

  /// Set false on top-level tabs so no back button appears.
  final bool showBackButton;

  const AppScaffold({
    super.key,
    this.title,
    required this.body,
    this.actions,
    this.showAppBar = true,
    this.backgroundColor,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor ?? AppColors.background,
      appBar: showAppBar
          ? AppBar(
              title: title == null ? null : Text(title!),
              automaticallyImplyLeading: showBackButton,
              actions: actions,
              backgroundColor: backgroundColor ?? AppColors.background,
            )
          : null,
      body: SafeArea(top: !showAppBar, bottom: false, child: body),
    );
  }
}

/// Centres content and caps its width at [AppSpacing.maxContentWidth].
class ContentWidth extends StatelessWidget {
  final Widget child;
  const ContentWidth({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints:
            const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
        child: child,
      ),
    );
  }
}
