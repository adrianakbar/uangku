import 'dart:ui';
import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color? color;
  final double blur;
  final BorderSide? border;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 24.0,
    this.color,
    this.blur = 20.0,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            // Pantulan cahaya kaca menggunakan gradien linier transparan putih (lebih tebal di tema terang)
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                (color ?? Colors.white).withOpacity(isDark ? 0.08 : 0.65),
                (color ?? Colors.white).withOpacity(isDark ? 0.02 : 0.35),
              ],
            ),
            // Border kaca lebih tebal di tema terang untuk refleksi fisik yang baik
            border: Border.all(
              color: Colors.white.withOpacity(isDark ? 0.12 : 0.45),
              width: 1.2,
            ),
            // Bayangan halus di tema terang agar terlihat melayang di atas orbs pastel
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          child: child,
        ),
      ),
    );
  }
}
