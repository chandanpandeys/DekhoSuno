import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class KeyboardShortcuts extends StatefulWidget {
  final Widget child;
  final VoidCallback? onReadText; // 1 or R
  final VoidCallback? onDescribeScene; // 2 or D
  final VoidCallback? onFindObject; // 3 or F
  final VoidCallback? onSettings; // 4 or S
  final VoidCallback? onToggleListen; // Ctrl+L
  final VoidCallback? onCapture; // Ctrl+C or Space
  final VoidCallback? onEscape; // Esc
  final Function(int)? onMenuNavigate; // Arrow keys or Tab

  const KeyboardShortcuts({
    super.key,
    required this.child,
    this.onReadText,
    this.onDescribeScene,
    this.onFindObject,
    this.onSettings,
    this.onToggleListen,
    this.onCapture,
    this.onEscape,
    this.onMenuNavigate,
  });

  @override
  State<KeyboardShortcuts> createState() => _KeyboardShortcutsState();
}

class _KeyboardShortcutsState extends State<KeyboardShortcuts> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          return _handleKeyPress(event);
        }
        return KeyEventResult.ignored;
      },
      child: widget.child,
    );
  }

  KeyEventResult _handleKeyPress(KeyDownEvent event) {
    final key = event.logicalKey;

    // Number keys for quick menu selection
    if (key == LogicalKeyboardKey.digit1 && widget.onReadText != null) {
      widget.onReadText!();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.digit2 && widget.onDescribeScene != null) {
      widget.onDescribeScene!();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.digit3 && widget.onFindObject != null) {
      widget.onFindObject!();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.digit4 && widget.onSettings != null) {
      widget.onSettings!();
      return KeyEventResult.handled;
    }

    // Letter shortcuts
    if (key == LogicalKeyboardKey.keyR && widget.onReadText != null) {
      widget.onReadText!();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyD && widget.onDescribeScene != null) {
      widget.onDescribeScene!();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyF && widget.onFindObject != null) {
      widget.onFindObject!();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyS &&
        !HardwareKeyboard.instance.isControlPressed &&
        widget.onSettings != null) {
      widget.onSettings!();
      return KeyEventResult.handled;
    }

    // Space or Enter for capture/activate
    if ((key == LogicalKeyboardKey.space || key == LogicalKeyboardKey.enter) &&
        widget.onCapture != null) {
      widget.onCapture!();
      return KeyEventResult.handled;
    }

    // Escape key
    if (key == LogicalKeyboardKey.escape && widget.onEscape != null) {
      widget.onEscape!();
      return KeyEventResult.handled;
    }

    // Ctrl+L for listen toggle
    if (key == LogicalKeyboardKey.keyL &&
        HardwareKeyboard.instance.isControlPressed &&
        widget.onToggleListen != null) {
      widget.onToggleListen!();
      return KeyEventResult.handled;
    }

    // Ctrl+C for capture
    if (key == LogicalKeyboardKey.keyC &&
        HardwareKeyboard.instance.isControlPressed &&
        widget.onCapture != null) {
      widget.onCapture!();
      return KeyEventResult.handled;
    }

    // Arrow keys or Tab for menu navigation
    if (widget.onMenuNavigate != null) {
      if (key == LogicalKeyboardKey.arrowDown ||
          (key == LogicalKeyboardKey.tab &&
              !HardwareKeyboard.instance.isShiftPressed)) {
        widget.onMenuNavigate!(1); // Next
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.arrowUp ||
          (key == LogicalKeyboardKey.tab &&
              HardwareKeyboard.instance.isShiftPressed)) {
        widget.onMenuNavigate!(-1); // Previous
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }
}
