import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../services/biometric_service.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../widgets/glass_card.dart';
import '../main.dart'; // To access biometricEnabledNotifier and notificationsEnabledNotifier

class SettingsScreen extends StatefulWidget {
  final VoidCallback onLogout;

  const SettingsScreen({super.key, required this.onLogout});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _authService = AuthService();
  bool _isUpdatingPhoto = false;

  Future<void> _pickProfilePhoto(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF151929) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.07),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Ganti Foto Profil',
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF1E293B),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF00ADB5).withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.image, color: Color(0xFF00ADB5), size: 22),
              ),
              title: Text(
                'Pilih dari Galeri',
                style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B), fontWeight: FontWeight.w600),
              ),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF355DA).withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.camera, color: Color(0xFFF355DA), size: 22),
              ),
              title: Text(
                'Ambil Foto',
                style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B), fontWeight: FontWeight.w600),
              ),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            if (_authService.currentUser?.photoUrl != null)
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.trash_2, color: Colors.redAccent, size: 22),
                ),
                title: Text(
                  'Hapus Foto',
                  style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B), fontWeight: FontWeight.w600),
                ),
                onTap: () => Navigator.pop(context, null),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    if (!context.mounted) return;

    // Jika user memilih hapus foto
    if (source == null && _authService.currentUser?.photoUrl != null) {
      setState(() => _isUpdatingPhoto = true);
      await _authService.updateUserPhoto(null);
      DatabaseService.changeNotifier.value++;
      if (mounted) setState(() => _isUpdatingPhoto = false);
      return;
    }

    if (source == null) return;

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 512,
    );

    if (pickedFile == null) return;
    if (!context.mounted) return;

    setState(() => _isUpdatingPhoto = true);
    await _authService.updateUserPhoto(pickedFile.path);
    DatabaseService.changeNotifier.value++;
    if (mounted) setState(() => _isUpdatingPhoto = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = _authService.currentUser;
    
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subTextColor = isDark ? Colors.white60 : const Color(0xFF475569);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Setelan Lokal',
            style: TextStyle(
              color: textColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 20),

          // 1. Profil Pengguna Card
          GlassCard(
            borderRadius: 24,
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Avatar dengan tombol edit
                GestureDetector(
                  onTap: () => _pickProfilePhoto(context),
                  child: Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFF00ADB5), Color(0xFFF355DA)],
                          ),
                        ),
                        child: _isUpdatingPhoto
                            ? const CircleAvatar(
                                radius: 26,
                                backgroundColor: Color(0xFF0E1122),
                                child: CircularProgressIndicator(
                                  color: Color(0xFF00ADB5),
                                  strokeWidth: 2,
                                ),
                              )
                            : CircleAvatar(
                                radius: 26,
                                backgroundColor: const Color(0xFF0E1122),
                                backgroundImage: _buildAvatarImage(user?.photoUrl),
                                child: _buildAvatarChild(user),
                              ),
                      ),
                      // Badge edit kamera
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00ADB5), Color(0xFFF355DA)],
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(color: isDark ? const Color(0xFF0E1122) : Colors.white, width: 2),
                          ),
                          child: const Icon(LucideIcons.camera, color: Colors.white, size: 11),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Nama & Email Kredensial
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.displayName ?? 'Pengguna Uangku',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? 'offline-mode@uangku.com',
                        style: TextStyle(color: subTextColor, fontSize: 12),
                      ),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () => _pickProfilePhoto(context),
                        child: Text(
                          'Ubah foto profil',
                          style: TextStyle(
                            color: const Color(0xFF00ADB5),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Logout Button
                IconButton(
                  icon: const Icon(LucideIcons.log_out, color: Colors.redAccent, size: 22),
                  onPressed: widget.onLogout,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 2. Keamanan & Perangkat Settings Section
          _buildSectionTitle('KEAMANAN & PRIVASI', subTextColor),
          const SizedBox(height: 10),
          GlassCard(
            borderRadius: 20,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: ValueListenableBuilder<bool>(
              valueListenable: biometricEnabledNotifier,
              builder: (context, enabled, _) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(LucideIcons.fingerprint_pattern, color: Color(0xFF00ADB5), size: 22),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Proteksi Biometrik',
                                  style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Minta Sidik Jari/Face ID saat buka aplikasi',
                                  style: TextStyle(color: subTextColor, fontSize: 11),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Switch(
                      value: enabled,
                      activeColor: const Color(0xFF00ADB5),
                      onChanged: (value) async {
                        if (value) {
                          final success = await BiometricService().authenticate();
                          if (success) {
                            biometricEnabledNotifier.value = true;
                            await DatabaseService().saveSetting('biometric_enabled', 'true');
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Proteksi biometrik berhasil diaktifkan!')),
                              );
                            }
                          } else {
                            biometricEnabledNotifier.value = false;
                            await DatabaseService().saveSetting('biometric_enabled', 'false');
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Verifikasi biometrik gagal!')),
                              );
                            }
                          }
                        } else {
                          biometricEnabledNotifier.value = false;
                          await DatabaseService().saveSetting('biometric_enabled', 'false');
                        }
                      },
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // 3. Preferensi Notifikasi Section
          _buildSectionTitle('PEMBERITAHUAN', subTextColor),
          const SizedBox(height: 10),
          GlassCard(
            borderRadius: 20,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: ValueListenableBuilder<bool>(
              valueListenable: notificationsEnabledNotifier,
              builder: (context, enabled, _) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(LucideIcons.bell_ring, color: Color(0xFFF355DA), size: 22),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pengingat Pencatatan Harian',
                                  style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Kirim notifikasi pengingat setiap pukul 20:00',
                                  style: TextStyle(color: subTextColor, fontSize: 11),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Switch(
                      value: enabled,
                      activeColor: const Color(0xFFF355DA),
                      onChanged: (value) async {
                        notificationsEnabledNotifier.value = value;
                        await DatabaseService().saveSetting('notifications_enabled', value ? 'true' : 'false');
                        NotificationService().scheduleDailyReminder(value);
                      },
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // Tampilan & Tema Section
          _buildSectionTitle('TAMPILAN & TEMA', subTextColor),
          const SizedBox(height: 10),
          GlassCard(
            borderRadius: 20,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: ValueListenableBuilder<ThemeMode>(
              valueListenable: themeNotifier,
              builder: (context, currentMode, _) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(LucideIcons.palette, color: Color(0xFF00ADB5), size: 22),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                  Text(
                                  'Tema Aplikasi',
                                  style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _getThemeModeLabel(currentMode),
                                  style: TextStyle(color: subTextColor, fontSize: 11),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.06),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<ThemeMode>(
                          value: currentMode,
                          dropdownColor: isDark ? const Color(0xFF0F1223) : Colors.white,
                          icon: Icon(Icons.arrow_drop_down, color: subTextColor, size: 18),
                          style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold),
                          onChanged: (ThemeMode? val) async {
                            if (val != null) {
                              themeNotifier.value = val;
                              String dbValue = 'system';
                              if (val == ThemeMode.light) {
                                dbValue = 'light';
                              } else if (val == ThemeMode.dark) {
                                dbValue = 'dark';
                              }
                              await DatabaseService().saveSetting('theme_mode', dbValue);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Tema aplikasi berhasil diperbarui!')),
                                );
                              }
                            }
                          },
                          items: const [
                            DropdownMenuItem(
                              value: ThemeMode.system,
                              child: Text('Ikuti Sistem'),
                            ),
                            DropdownMenuItem(
                              value: ThemeMode.light,
                              child: Text('Tema Terang'),
                            ),
                            DropdownMenuItem(
                              value: ThemeMode.dark,
                              child: Text('Tema Gelap'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // 4. Cadangan Data & Database Section
          _buildSectionTitle('DATA & CADANGAN', subTextColor),
          const SizedBox(height: 10),
          GlassCard(
            borderRadius: 20,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildSettingsRow(
                  icon: LucideIcons.file_spreadsheet,
                  color: const Color(0xFF10B981),
                  title: 'Ekspor Riwayat ke CSV',
                  subtitle: 'Simpan file laporan lokal berupa tabel Excel',
                  textColor: textColor,
                  subTextColor: subTextColor,
                ),
                const Divider(color: Colors.white10, height: 20),
                _buildSettingsRow(
                  icon: LucideIcons.database,
                  color: const Color(0xFF3B82F6),
                  title: 'Backup Database SQLite (.db)',
                  subtitle: 'Simpan salinan database offline perangkat',
                  textColor: textColor,
                  subTextColor: subTextColor,
                ),
              ],
            ),
          ),
          const SizedBox(height: 120), // Memberi ruang bottom bar melayang
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String label, Color color) {
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

  Widget _buildSettingsRow({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required Color textColor,
    required Color subTextColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(color: subTextColor, fontSize: 11)),
            ],
          ),
        ),
        const Icon(LucideIcons.chevron_right, color: Colors.white30, size: 16),
      ],
    );
  }

  String _getThemeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'Tema saat ini: Mengikuti pengaturan sistem';
      case ThemeMode.light:
        return 'Tema saat ini: Terang (Light Mode)';
      case ThemeMode.dark:
        return 'Tema saat ini: Gelap (Dark Mode)';
    }
  }

  // Helper: Menentukan sumber gambar avatar (lokal file atau network)
  ImageProvider? _buildAvatarImage(String? photoUrl) {
    if (photoUrl == null) return null;
    if (photoUrl.startsWith('http://') || photoUrl.startsWith('https://')) {
      return NetworkImage(photoUrl);
    }
    return FileImage(File(photoUrl));
  }

  // Helper: Widget inisial huruf jika tidak ada foto
  Widget? _buildAvatarChild(UserSession? user) {
    if (user?.photoUrl != null) return null;
    final letter = user?.displayName.isNotEmpty == true
        ? user!.displayName.substring(0, 1).toUpperCase()
        : 'U';
    return Text(
      letter,
      style: const TextStyle(
        color: Color(0xFF00ADB5),
        fontWeight: FontWeight.bold,
        fontSize: 20,
      ),
    );
  }
}
