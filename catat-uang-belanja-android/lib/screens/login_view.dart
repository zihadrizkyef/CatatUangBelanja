import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import '../widgets/google_sign_in_button.dart';
import '../widgets/openmoji_icon.dart';

/// Pure layout for [LoginScreen]: warm welcome copy + a single "Masuk
/// dengan Google" button (doc 4.10/6.1 — Google Sign-In is the only login
/// method, no password/OTP fields to build). All data/callbacks come from
/// the [LoginScreen] container.
class LoginView extends StatelessWidget {
  const LoginView({super.key, required this.isSigningIn, required this.errorText, required this.onTapGoogleSignIn});

  final bool isSigningIn;
  final String? errorText;
  final VoidCallback onTapGoogleSignIn;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Scaffold(
      backgroundColor: palette.screenBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(color: Color(0xFFFCE0E1), shape: BoxShape.circle),
                alignment: Alignment.center,
                child: OpenMojiIcon(AppIcons.wallet, size: 46),
              ),
              const SizedBox(height: 24),
              Text(
                'Yuk, mulai catat belanja, Bun!',
                textAlign: TextAlign.center,
                style: AppTheme.heading(fontSize: 22, color: palette.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                'Masuk dengan Google supaya catatanmu aman dan bisa dibuka lagi dari HP mana pun.',
                textAlign: TextAlign.center,
                style: AppTheme.body(fontSize: 13, color: palette.textSecondary),
              ),
              const SizedBox(height: 32),
              GoogleSignInButton(isLoading: isSigningIn, onTap: isSigningIn ? null : onTapGoogleSignIn),
              if (errorText != null) ...[
                const SizedBox(height: 12),
                Text(
                  errorText!,
                  textAlign: TextAlign.center,
                  style: AppTheme.body(fontSize: 12, fontWeight: FontWeight.bold, color: palette.warningText),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

@Preview(name: 'LoginView - default')
Widget previewLoginView() {
  return LoginView(isSigningIn: false, errorText: null, onTapGoogleSignIn: () {});
}

@Preview(name: 'LoginView - signing in')
Widget previewLoginViewSigningIn() {
  return LoginView(isSigningIn: true, errorText: null, onTapGoogleSignIn: () {});
}

@Preview(name: 'LoginView - error')
Widget previewLoginViewError() {
  return LoginView(
    isSigningIn: false,
    errorText: 'Google tidak mengembalikan token — coba lagi, Bun.',
    onTapGoogleSignIn: () {},
  );
}
