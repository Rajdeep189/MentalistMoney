import 'package:flutter/material.dart';

/// Shows a bottom sheet whose content pops in with an easeOutBack
/// (spring) curve on top of the standard modal slide.
Future<T?> showSpringBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  Color? barrierColor,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: barrierColor ?? Colors.black.withOpacity(0.35),
    builder: (ctx) {
      final route = ModalRoute.of(ctx);
      final Animation<double> anim = route == null
          ? kAlwaysCompleteAnimation
          : CurvedAnimation(parent: route.animation, curve: Curves.easeOutBack);
      return FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.94, end: 1.0).animate(anim),
          child: builder(ctx),
        ),
      );
    },
  );
}
