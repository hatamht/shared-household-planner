import 'package:flutter/material.dart';

/// Wraps the application to automatically dismiss the soft keyboard
/// whenever the user taps anywhere outside the currently focused input field.
class GlobalKeyboardDismiss extends StatelessWidget {
  final Widget? child;

  const GlobalKeyboardDismiss({super.key, this.child});

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (PointerDownEvent event) {
        final currentFocus = FocusManager.instance.primaryFocus;
        if (currentFocus != null && currentFocus.context != null) {
          final renderObject = currentFocus.context!.findRenderObject();
          if (renderObject is RenderBox && renderObject.hasSize) {
            final position = renderObject.localToGlobal(Offset.zero);
            final bounds = position & renderObject.size;
            if (!bounds.contains(event.position)) {
              currentFocus.unfocus();
            }
          } else {
            currentFocus.unfocus();
          }
        }
      },
      child: child,
    );
  }
}
