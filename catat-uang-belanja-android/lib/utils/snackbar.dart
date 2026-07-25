import 'package:flutter/material.dart';

/// Shorthand for a simple, warm-toned feedback toast — used across the
/// add/edit sheets (see UX-007) so a failed save tells the user what to fix
/// instead of silently doing nothing.
void showSnackBarMessage(BuildContext context, String message, {Duration duration = const Duration(milliseconds: 1800)}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), duration: duration));
}
