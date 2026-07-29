import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// "Masuk dengan Google" button used by [LoginScreen] (doc 4.10/6.1).
///
/// The "G" mark is a plain styled [Text], not an [OpenMojiIcon] — it's
/// Google's own brand mark, not one of the app's household/category icons,
/// so it deliberately doesn't go through [AppIcons] like the rest of the
/// app's iconography. There's no bundled asset for the real four-color
/// Google "G" logo; this is a lightweight stand-in.
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({super.key, required this.isLoading, required this.onTap});

  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: palette.cardBg,
          side: BorderSide(color: palette.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('G', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF4285F4))),
                  const SizedBox(width: 10),
                  Text(
                    'Masuk dengan Google',
                    style: AppTheme.body(fontSize: 14, fontWeight: FontWeight.bold, color: palette.textPrimary),
                  ),
                ],
              ),
      ),
    );
  }
}

@Preview(name: 'GoogleSignInButton - default')
Widget previewGoogleSignInButton() {
  return GoogleSignInButton(isLoading: false, onTap: () {});
}

@Preview(name: 'GoogleSignInButton - loading')
Widget previewGoogleSignInButtonLoading() {
  return GoogleSignInButton(isLoading: true, onTap: null);
}
