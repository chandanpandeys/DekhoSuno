import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

class SemanticsHelper {
  static void announce(String message) {
    SemanticsService.announce(message, TextDirection.ltr);
  }

  static Widget wrap({
    required Widget child,
    required String label,
    String? hint,
    bool isButton = false,
    VoidCallback? onTap,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      button: isButton,
      enabled: true,
      onTap: onTap,
      excludeSemantics: true,
      child: child,
    );
  }
}
