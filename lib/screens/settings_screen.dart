import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
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
                // Avatar
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFF00ADB5), Color(0xFFF355DA)],
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 26,
                    backgroundColor: const Color(0xFF0E1122),
                    backgroundImage: user?.photoUrl != null ? NetworkImage(user!.photoUrl!) : null,
                    child: user?.photoUrl == null
                        ? Text(
                            user?.displayName.substring(0, 1).toUpperCase() ?? 'U',
                            style: const TextStyle(
                              color: Color(0xFF00ADB5),
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          )
                        : null,
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
}
