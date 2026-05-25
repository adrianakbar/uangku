import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/text_style_helper.dart';
import '../widgets/liquid_glass_background.dart';
import '../widgets/glass_card.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  final VoidCallback onRegisterSuccess;

  const RegisterScreen({super.key, required this.onRegisterSuccess});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  final _authService = AuthService();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Semua field wajib diisi!';
      });
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        _errorMessage = 'Konfirmasi password tidak cocok!';
      });
      return;
    }

    if (password.length < 6) {
      setState(() {
        _errorMessage = 'Password minimal 6 karakter!';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await _authService.register(name, email, password);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      if (success) {
        widget.onRegisterSuccess();
      } else {
        setState(() {
          _errorMessage = 'Email sudah digunakan!';
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
    final inputBg = isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03);
    final inputBorder = isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.08);

    return LiquidGlassBackground(
      child: Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              // 1. Logo/Judul
              Container(
                width: 65,
                height: 65,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00ADB5), Color(0xFF7000FF)],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Image.asset(
                    'lib/assets/images/uangku_logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'BUAT AKUN LOKAL',
                style: poppinsStyle(
                  color: textColor,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 25),

              // 2. Kartu Registrasi (Glassmorphic)
              GlassCard(
                borderRadius: 28,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daftar Baru',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Field Nama
                    _buildLabel('NAMA LENGKAP', subTextColor),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _nameController,
                      icon: LucideIcons.user,
                      hint: 'Adrian Akbar',
                      inputBg: inputBg,
                      inputBorder: inputBorder,
                      textColor: textColor,
                      fadedTextColor: subTextColor,
                    ),
                    const SizedBox(height: 16),

                    // Field Email
                    _buildLabel('EMAIL', subTextColor),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _emailController,
                      icon: LucideIcons.mail,
                      hint: 'adrian@uangku.com',
                      inputBg: inputBg,
                      inputBorder: inputBorder,
                      textColor: textColor,
                      fadedTextColor: subTextColor,
                    ),
                    const SizedBox(height: 16),

                    // Field Password
                    _buildLabel('PASSWORD', subTextColor),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _passwordController,
                      icon: LucideIcons.lock,
                      hint: 'minimal 6 karakter',
                      isObscure: true,
                      inputBg: inputBg,
                      inputBorder: inputBorder,
                      textColor: textColor,
                      fadedTextColor: subTextColor,
                    ),
                    const SizedBox(height: 16),

                    // Field Konfirmasi Password
                    _buildLabel('KONFIRMASI PASSWORD', subTextColor),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _confirmPasswordController,
                      icon: LucideIcons.shield_alert,
                      hint: 'masukkan kembali password',
                      isObscure: true,
                      inputBg: inputBg,
                      inputBorder: inputBorder,
                      textColor: textColor,
                      fadedTextColor: subTextColor,
                    ),

                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                    const SizedBox(height: 24),

                    // Tombol Daftar
                    GestureDetector(
                      onTap: _isLoading ? null : _handleRegister,
                      child: Container(
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00ADB5), Color(0xFF7000FF)],
                          ),
                        ),
                        child: Center(
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Text(
                                  'Registrasi',
                                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              // 3. Tombol Kembali ke Login
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Sudah punya akun? ', style: TextStyle(color: subTextColor, fontSize: 13)),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Masuk Di Sini',
                      style: TextStyle(
                        color: Color(0xFF00ADB5),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label, Color color) {
    return Text(
      label,
      style: TextStyle(
        color: color,
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    bool isObscure = false,
    required Color inputBg,
    required Color inputBorder,
    required Color textColor,
    required Color fadedTextColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: inputBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: inputBorder),
      ),
      child: TextField(
        controller: controller,
        obscureText: isObscure,
        style: TextStyle(color: textColor, fontSize: 14),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: fadedTextColor, size: 18),
          hintText: hint,
          hintStyle: TextStyle(color: fadedTextColor.withOpacity(0.5), fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
      ),
    );
  }
}
