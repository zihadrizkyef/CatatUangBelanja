import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../widgets/twemoji_icon.dart';
import '../theme/app_theme.dart';

class NavItem {
  const NavItem(this.icon, this.label);
  final String icon;
  final String label;
}

const navItems = [
  NavItem(AppIcons.home, 'Beranda'),
  NavItem(AppIcons.wallet, 'Dompet'),
  NavItem(AppIcons.summary, 'Rangkuman'),
  NavItem(AppIcons.settings, 'Pengaturan'),
];

/// Pure chrome for [AppShell]: the tab [IndexedStack], the "+" FAB (only on
/// Beranda/Dompet), and the custom bottom nav bar — all wiring/state lives in
/// the [AppShell] container.
class AppShellView extends StatelessWidget {
  const AppShellView({
    super.key,
    required this.currentIndex,
    required this.screens,
    required this.showFab,
    required this.onTapFab,
    required this.onTapNav,
  });

  final int currentIndex;
  final List<Widget> screens;
  final bool showFab;
  final VoidCallback onTapFab;
  final ValueChanged<int> onTapNav;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Scaffold(
      body: IndexedStack(index: currentIndex, children: screens),
      floatingActionButton: showFab
          ? FloatingActionButton(
              onPressed: onTapFab,
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
                for (var i = 0; i < navItems.length; i++)
                  Expanded(
                    child: InkWell(
                      onTap: () => onTapNav(i),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Opacity(
                              opacity: currentIndex == i ? 1 : 0.45,
                              child: TwemojiIcon(navItems[i].icon, size: 32),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              navItems[i].label,
                              style: AppTheme.body(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: currentIndex == i
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

@Preview(name: 'AppShellView')
Widget previewAppShellView() {
  return AppShellView(
    currentIndex: 0,
    screens: const [
      Center(child: Text('Beranda')),
      Center(child: Text('Dompet')),
      Center(child: Text('Rangkuman')),
      Center(child: Text('Pengaturan')),
    ],
    showFab: true,
    onTapFab: () {},
    onTapNav: (_) {},
  );
}
