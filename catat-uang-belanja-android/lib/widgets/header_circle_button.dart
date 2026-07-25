import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

/// A translucent circular icon button on an accent-colored header — used by
/// [WalletDetailView] for both its back and edit actions.
class HeaderCircleButton extends StatelessWidget {
  const HeaderCircleButton({super.key, required this.icon, required this.onTap, this.iconSize = 22});

  final IconData icon;
  final VoidCallback onTap;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.22),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(width: 32, height: 32, child: Icon(icon, color: Colors.white, size: iconSize)),
      ),
    );
  }
}

@Preview(name: 'HeaderCircleButton')
Widget previewHeaderCircleButton() {
  return ColoredBox(
    color: const Color(0xFFE8637C),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: HeaderCircleButton(icon: Icons.edit_rounded, iconSize: 16, onTap: () {}),
    ),
  );
}
