import 'package:flutter/material.dart';

import 'app_shell_view.dart';
import 'home_screen.dart';
import 'settings_screen.dart';
import 'summary_screen.dart';
import 'transaction_sheet.dart';
import 'wallet_screen.dart';

/// Hosts the four bottom-nav tabs (Beranda/Dompet/Rangkuman/Pengaturan) in an
/// IndexedStack so tab state survives switching, a custom bottom nav bar and
/// "+" FAB matching the Claude Design mockup's chrome (`App.dc.html`), plus
/// the "+" FAB that opens [TransactionSheet].
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  List<Widget> get _screens => [
        const HomeScreen(),
        const WalletScreen(),
        const SummaryScreen(),
        const SettingsScreen(),
      ];

  void _openTransactionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const TransactionSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppShellView(
      currentIndex: _currentIndex,
      screens: _screens,
      showFab: _currentIndex == 0 || _currentIndex == 1,
      onTapFab: _openTransactionSheet,
      onTapNav: (i) => setState(() => _currentIndex = i),
    );
  }
}
