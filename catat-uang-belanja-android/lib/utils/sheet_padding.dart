import 'package:flutter/widgets.dart';

/// Bottom padding for a modal bottom sheet's content, shared by every
/// add/edit sheet in the app (wallet/budget/transfer/transaction/category).
/// Must clear whichever is taller: the on-screen keyboard
/// ([MediaQueryData.viewInsets]) or the persistent system nav/gesture bar
/// ([MediaQueryData.viewPadding]) — using only [MediaQueryData.viewInsets]
/// leaves the sheet's bottom-most content (e.g. a delete button) sitting
/// under the system nav bar when the keyboard is closed, where taps get
/// intercepted by the OS instead of reaching Flutter.
double sheetBottomPadding(BuildContext context, {double base = 22}) {
  final mediaQuery = MediaQuery.of(context);
  return base + (mediaQuery.viewInsets.bottom > mediaQuery.viewPadding.bottom ? mediaQuery.viewInsets.bottom : mediaQuery.viewPadding.bottom);
}
