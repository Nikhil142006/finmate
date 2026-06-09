import 'dart:ui';
import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.borderRadius = 32.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
