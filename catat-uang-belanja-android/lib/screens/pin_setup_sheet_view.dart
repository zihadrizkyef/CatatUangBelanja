import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/sheet_padding.dart';
import '../widgets/numeric_keypad.dart';
import 'pin_setup_sheet.dart' show PinSetupStage;

/// Pure layout for [PinSetupSheet]'s enter→confirm PIN flow: 6-dot progress
/// indicator, an optional forgot-PIN warning banner, and [NumericKeypad] for
/// entry. All data/callbacks come from the [PinSetupSheet] container — this
/// widget never touches [FinanceRepository] or [Navigator] itself.
class PinSetupSheetView extends StatelessWidget {
  const PinSetupSheetView({
    super.key,
    required this.stage,
    required this.digitsEntered,
    required this.errorText,
    required this.showForgotPinWarning,
    required this.onKeyTap,
    required this.onClose,
  });

  final PinSetupStage stage;
  final int digitsEntered;
  final String? errorText;
  final bool showForgotPinWarning;
  final ValueChanged<String> onKeyTap;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final title = stage == PinSetupStage.enter ? 'Buat PIN Baru' : 'Konfirmasi PIN';
    final subtitle = stage == PinSetupStage.enter
        ? 'Masukkan 6 digit PIN untuk mengunci aplikasi, Bun'
        : 'Masukkan sekali lagi PIN yang tadi, Bun';

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
      decoration: BoxDecoration(
        color: palette.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(18, 18, 18, sheetBottomPadding(context)),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: AppTheme.heading(fontSize: 17, color: palette.textPrimary)),
                Material(
                  color: palette.warningBg,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onClose,
                    child: SizedBox(width: 38, height: 38, child: Icon(Icons.close, size: 20, color: palette.textPrimary)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(subtitle, style: AppTheme.body(fontSize: 13, color: palette.textSecondary)),
            if (showForgotPinWarning) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: palette.warningBg, borderRadius: BorderRadius.circular(12)),
                child: Text(
                  'Karena belum masuk akun, PIN ini tidak bisa direset kalau lupa — satu-satunya jalan adalah hapus semua data lewat Pengaturan.',
                  style: AppTheme.body(fontSize: 12, fontWeight: FontWeight.bold, color: palette.warningText),
                ),
              ),
            ],
            const SizedBox(height: 20),
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
            if (errorText != null) ...[
              const SizedBox(height: 10),
              Text(
                errorText!,
                textAlign: TextAlign.center,
                style: AppTheme.body(fontSize: 12, fontWeight: FontWeight.bold, color: palette.warningText),
              ),
            ],
            const SizedBox(height: 20),
            NumericKeypad(confirmColor: AppColors.accent, palette: palette, onKeyTap: onKeyTap),
          ],
        ),
      ),
    );
  }
}

@Preview(name: 'PinSetupSheetView · masukkan')
Widget previewPinSetupSheetViewEnter() {
  return PinSetupSheetView(
    stage: PinSetupStage.enter,
    digitsEntered: 3,
    errorText: null,
    showForgotPinWarning: true,
    onKeyTap: (_) {},
    onClose: () {},
  );
}

@Preview(name: 'PinSetupSheetView · konfirmasi tidak cocok')
Widget previewPinSetupSheetViewMismatch() {
  return PinSetupSheetView(
    stage: PinSetupStage.confirm,
    digitsEntered: 0,
    errorText: 'PIN tidak sama, coba lagi ya, Bun',
    showForgotPinWarning: false,
    onKeyTap: (_) {},
    onClose: () {},
  );
}
