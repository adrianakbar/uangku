import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

class LiquidGlassBackground extends StatefulWidget {
  final Widget child;

  const LiquidGlassBackground({super.key, required this.child});

  @override
  State<LiquidGlassBackground> createState() => _LiquidGlassBackgroundState();
}

class _LiquidGlassBackgroundState extends State<LiquidGlassBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Animasi lambat selama 20 detik (berputar/mengapung perlahan)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF090D19) : const Color(0xFFE8EEF5), // Dynamic Slate Canvas
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // 1. Orbs Latar Belakang yang Mengalir/Mengapung
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final value = _controller.value * 2 * math.pi;

              // Hitung pergeseran posisi orbs menggunakan fungsi sin/cos agar halus
              final orb1Offset = Offset(
                math.sin(value) * 40,
                math.cos(value) * 30,
              );
              final orb2Offset = Offset(
                math.cos(value + 1) * 30,
                math.sin(value + 1) * 40,
              );
              final orb3Offset = Offset(
                math.sin(value + 2) * 50,
                math.cos(value + 2) * 40,
              );

              return Stack(
                children: [
                  // Orb 1: Royal Purple / Light Lavender (Top-Left)
                  Positioned(
                    top: size.height * 0.05 + orb1Offset.dy,
                    left: -size.width * 0.1 + orb1Offset.dx,
                    child: Container(
                      width: size.width * 0.8,
                      height: size.width * 0.8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            isDark ? const Color(0x80F355DA) : const Color(0x35B388FF),
                            isDark ? const Color(0x307000FF) : const Color(0x087000FF),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Orb 2: Cyan Blue / Soft Teal (Center-Right)
                  Positioned(
                    top: size.height * 0.35 + orb2Offset.dy,
                    right: -size.width * 0.2 + orb2Offset.dx,
                    child: Container(
                      width: size.width * 0.9,
                      height: size.width * 0.9,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            isDark ? const Color(0x7000F2FE) : const Color(0x3580DEEA),
                            isDark ? const Color(0x254FACFE) : const Color(0x0800ADB5),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Orb 3: Coral Pink / Rose Gold (Bottom-Left)
                  Positioned(
                    bottom: size.height * 0.08 + orb3Offset.dy,
                    left: -size.width * 0.15 + orb3Offset.dx,
                    child: Container(
                      width: size.width * 0.75,
                      height: size.width * 0.75,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            isDark ? const Color(0x65FF0080) : const Color(0x30FF8A80),
                            isDark ? const Color(0x20FF8C00) : const Color(0x08FF8C00),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // 2. Lapisan Blur Kaca Terintegrasi (Glassmorphic Backdrop Filter)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
              child: Container(
                color: isDark ? Colors.black.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.3), // Milky vs Dark overlay
              ),
            ),
          ),

          // 3. Konten Utama
          SafeArea(
            bottom: false,
            child: widget.child,
          ),
        ],
      ),
    );
  }
}
