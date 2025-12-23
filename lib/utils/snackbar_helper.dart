import 'package:flutter/material.dart';

/// Utility for showing SnackBars immediately by removing any currently
/// visible SnackBar before showing the new one.
class SnackBarHelper {
  /// Show [snackBar] immediately, removing the current SnackBar first.
  static void show(BuildContext context, SnackBar snackBar) {
    final messenger = ScaffoldMessenger.of(context);
    // remove current so the new message appears immediately
    messenger.removeCurrentSnackBar();
    messenger.showSnackBar(snackBar);
  }

  /// Convenience helper to show a simple text message.
  static void showMessage(BuildContext context, String message,
      {Duration duration = const Duration(seconds: 2)}) {
    final snack = SnackBar(content: Text(message), duration: duration);
    show(context, snack);
  }
}
