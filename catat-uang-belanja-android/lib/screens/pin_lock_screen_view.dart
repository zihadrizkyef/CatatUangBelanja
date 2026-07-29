import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import '../widgets/numeric_keypad.dart';
import '../widgets/openmoji_icon.dart';

/// Pure layout for [PinLockScreen]: centered lock icon, 6-dot progress
/// indicator, [NumericKeypad], and (only when biometric mode is active) a
/// "coba lagi" retry button plus a forgot-PIN link (only when logged in).
/// All data/callbacks come from the [PinLockScreen] container — this widget
/// never touches [FinanceRepository] or [Navigator] itself.
class PinLockScreenView extends StatelessWidget {
  const PinLockScreenView({
    super.key,
    required this.isBiometric,
    required this.digitsEntered,
    required this.isVerifying,
    required this.errorText,
    required this.showForgotPin,
    required this.onKeyTap,
    required this.onRetryBiometric,
    required this.onTapForgotPin,
  });

  final bool isBiometric;
  final int digitsEntered;
  final bool isVerifying;
  final String? errorText;
  final bool showForgotPin;
  final ValueChanged<String> onKeyTap;
  final VoidCallback onRetryBiometric;
  final VoidCallback onTapForgotPin;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Scaffold(
      backgroundColor: palette.screenBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(color: Color(0xFFFCE0E1), shape: BoxShape.circle),
                alignment: Alignment.center,
                child: OpenMojiIcon(AppIcons.security, size: 34),
              ),
              const SizedBox(height: 16),
              Text('Aplikasi Terkunci', style: AppTheme.heading(fontSize: 19, color: palette.textPrimary)),
              const SizedBox(height: 6),
              Text(
                'Masukkan PIN kamu, Bun',
                style: AppTheme.body(fontSize: 13, color: palette.textSecondary),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < 6; i++)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i < digitsEntered ? AppColors.accent : palette.chipNeutral,
                        border: Border.all(color: i < digitsEntered ? AppColors.accent : palette.border, width: 1.5),
                      ),
                    ),
                ],
              ),
              if (isVerifying) ...[
                const SizedBox(height: 14),
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
                ),
              ],
              if (errorText != null) ...[
                const SizedBox(height: 10),
                Text(
                  errorText!,
                  textAlign: TextAlign.center,
                  style: AppTheme.body(fontSize: 12, fontWeight: FontWeight.bold, color: palette.warningText),
                ),
              ],
              if (isBiometric) ...[
                const SizedBox(height: 14),
                TextButton.icon(
                  onPressed: onRetryBiometric,
                  icon: OpenMojiIcon(AppIcons.biometric, size: 18),
                  label: Text('Gunakan Sidik Jari / Face ID', style: AppTheme.body(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.accent)),
                ),
              ],
              const SizedBox(height: 20),
              IgnorePointer(
                ignoring: isVerifying,
                child: Opacity(
                  opacity: isVerifying ? 0.5 : 1,
                  child: NumericKeypad(confirmColor: AppColors.accent, palette: palette, onKeyTap: onKeyTap),
                ),
              ),
              const SizedBox(height: 12),
              if (showForgotPin)
                TextButton(
                  onPressed: onTapForgotPin,
                  child: Text('Lupa PIN?', style: AppTheme.body(fontSize: 12, fontWeight: FontWeight.bold, color: palette.textSecondary)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

@Preview(name: 'PinLockScreenView · PIN')
Widget previewPinLockScreenViewPin() {
  return PinLockScreenView(
    isBiometric: false,
    digitsEntered: 2,
    isVerifying: false,
    errorText: null,
    showForgotPin: false,
    onKeyTap: (_) {},
    onRetryBiometric: () {},
    onTapForgotPin: () {},
  );
}

@Preview(name: 'PinLockScreenView · biometric + lupa PIN')
Widget previewPinLockScreenViewBiometric() {
  return PinLockScreenView(
    isBiometric: true,
    digitsEntered: 0,
    isVerifying: false,
    errorText: 'PIN salah, coba lagi ya, Bun',
    showForgotPin: true,
    onKeyTap: (_) {},
    onRetryBiometric: () {},
    onTapForgotPin: () {},
  );
}
