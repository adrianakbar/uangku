import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../widgets/liquid_glass_background.dart';
import '../widgets/glass_card.dart';
import '../services/biometric_service.dart';

class LockScreen extends StatefulWidget {
  final VoidCallback onUnlockSuccess;

  const LockScreen({super.key, required this.onUnlockSuccess});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final _biometricService = BiometricService();
  bool _isAuthenticating = false;
  bool _authFailed = false;

  @override
  void initState() {
    super.initState();
    // Jalankan autentikasi otomatis sesaat setelah halaman dirender
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authenticate();
    });
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;

    setState(() {
      _isAuthenticating = true;
      _authFailed = false;
    });

    try {
      final success = await _biometricService.authenticate();
      if (mounted) {
        if (success) {
          widget.onUnlockSuccess();
        } else {
          setState(() {
            _authFailed = true;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _authFailed = true;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Warna teks dinamis
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subTextColor = isDark ? Colors.white60 : const Color(0xFF475569);

    return LiquidGlassBackground(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Glowing Biometric Shield Badge
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  LucideIcons.fingerprint_pattern,
                  color: Theme.of(context).colorScheme.primary,
                  size: 48,
                ),
              ),
              const SizedBox(height: 30),
              Text(
                'Uangku Terkunci',
                style: TextStyle(
                  color: textColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Verifikasi identitas sidik jari atau wajah Anda untuk mengakses catatan pengeluaran.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: subTextColor,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 30),

              // Glass Warning Box if Authenticating Canceled/Failed
              if (_authFailed) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.triangle_alert, color: Colors.orangeAccent, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Autentikasi dibatalkan / gagal',
                      style: TextStyle(color: isDark ? Colors.orangeAccent : const Color(0xFFC2410C), fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ] else ...[
                const SizedBox(height: 40),
              ],

              // Glass Retry Button
              GestureDetector(
                onTap: _authenticate,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: (_authFailed ? const Color(0xFFFF5252) : Theme.of(context).colorScheme.primary).withOpacity(0.15),
                        blurRadius: 15,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: GlassCard(
                    borderRadius: 20,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _isAuthenticating
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: Theme.of(context).colorScheme.primary,
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                _authFailed ? LucideIcons.refresh_cw : LucideIcons.shield_check,
                                color: _authFailed ? const Color(0xFFFF5252) : Theme.of(context).colorScheme.primary,
                                size: 20,
                              ),
                        const SizedBox(width: 12),
                        Text(
                          _isAuthenticating
                              ? 'Sedang Memindai...'
                              : (_authFailed ? 'Coba Lagi (Pindai Ulang)' : 'Buka Kunci Biometrik'),
                          style: TextStyle(
                            color: textColor,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
