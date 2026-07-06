import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
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

class _NavItem {
  const _NavItem(this.icon, this.label);
  final String icon;
  final String label;
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  List<Widget> get _screens => [
        HomeScreen(onGoToSummary: () => setState(() => _currentIndex = 2)),
        const WalletScreen(),
        const SummaryScreen(),
        const SettingsScreen(),
      ];

  static const _navItems = [
    _NavItem(AppIcons.home, 'Beranda'),
    _NavItem(AppIcons.wallet, 'Dompet'),
    _NavItem(AppIcons.summary, 'Rangkuman'),
    _NavItem(AppIcons.settings, 'Pengaturan'),
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
    final palette = AppPalette.of(context);
    final showFab = _currentIndex == 0 || _currentIndex == 1;

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      floatingActionButton: showFab
          ? FloatingActionButton(
              onPressed: _openTransactionSheet,
              tooltip: 'Catat transaksi',
              backgroundColor: AppColors.accent,
              child: const Text(
                '+',
                style: TextStyle(fontSize: 26, color: Colors.white),
              ),
            )
          : null,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.navBg,
          border: Border(top: BorderSide(color: palette.border)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                for (var i = 0; i < _navItems.length; i++)
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _currentIndex = i),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Opacity(
                              opacity: _currentIndex == i ? 1 : 0.45,
                              child: TwemojiIcon(_navItems[i].icon, size: 20),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _navItems[i].label,
                              style: AppTheme.body(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _currentIndex == i
                                    ? AppColors.accent
                                    : palette.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
