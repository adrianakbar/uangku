import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart' show getDatabasesPath;
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

  Future<void> _exportToCSV() async {
    try {
      final email = _authService.currentUser?.email ?? 'adrian@uangku.com';
      final list = await DatabaseService().getTransactionsForUser(email);

      if (list.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tidak ada transaksi untuk diekspor.')),
          );
        }
        return;
      }

      StringBuffer csv = StringBuffer();
      // Headers
      csv.writeln('ID,Tanggal,Kategori,Judul,Jumlah,Tipe,Metode Pembayaran');

      for (var tx in list) {
        final id = tx['id'];
        final date = tx['date'];
        final category = tx['category'];
        final title = tx['title'].toString().replaceAll('"', '""');
        final amount = tx['amount'];
        final isExpense = tx['is_expense'] == 1;
        final type = isExpense ? 'Pengeluaran' : 'Pemasukan';
        final wallet = tx['wallet'];

        csv.writeln('$id,"$date","$category","$title",$amount,"$type","$wallet"');
      }

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/ekspor_riwayat_uangku.csv');
      await file.writeAsString(csv.toString());

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Ekspor Riwayat Uangku',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengekspor data: $e')),
        );
      }
    }
  }

  Future<void> _backupDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final pathString = p.join(dbPath, 'uangku.db');
      final dbFile = File(pathString);

      if (!await dbFile.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Database tidak ditemukan.')),
          );
        }
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final backupFile = File('${tempDir.path}/uangku_backup.db');
      if (await backupFile.exists()) {
        await backupFile.delete();
      }
      await dbFile.copy(backupFile.path);

      await Share.shareXFiles(
        [XFile(backupFile.path)],
        subject: 'Backup Database Uangku',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal melakukan backup database: $e')),
        );
      }
    }
  }

  List<String> _parseCsvLine(String line) {
    final List<String> cells = [];
    StringBuffer cell = StringBuffer();
    bool inQuotes = false;
    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          cell.write('"');
          i++; // skip next quote
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        cells.add(cell.toString().trim());
        cell.clear();
      } else {
        cell.write(char);
      }
    }
    cells.add(cell.toString().trim());
    return cells;
  }

  Future<void> _importCSV() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result == null || result.files.single.path == null) {
        return;
      }

      final file = File(result.files.single.path!);
      final lines = await file.readAsLines();

      if (lines.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File CSV kosong.')),
          );
        }
        return;
      }

      // Cek header minimal
      final header = lines.first.toLowerCase();
      if (!header.contains('kategori') && !header.contains('jumlah')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Format CSV tidak valid. Harus memiliki header Kategori dan Jumlah.')),
          );
        }
        return;
      }

      final email = _authService.currentUser?.email ?? 'adrian@uangku.com';
      int importCount = 0;

      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        final cells = _parseCsvLine(line);
        if (cells.length < 6) continue;

        // format: ID,Tanggal,Kategori,Judul,Jumlah,Tipe,Metode Pembayaran
        final dateStr = cells[1];
        final category = cells[2];
        final title = cells[3];
        final amount = double.tryParse(cells[4]) ?? 0.0;
        final typeStr = cells[5].toLowerCase();
        final isExpense = typeStr.contains('pengeluaran') || typeStr.contains('expense') ? 1 : 0;
        final wallet = cells.length > 6 ? cells[6] : 'Cash';

        await DatabaseService().insertTransaction({
          'title': title,
          'category': category,
          'amount': amount,
          'is_expense': isExpense,
          'wallet': wallet,
          'date': dateStr,
          'user_email': email,
        });
        importCount++;
      }

      DatabaseService.changeNotifier.value++;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Berhasil mengimpor $importCount transaksi dari CSV.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengimpor file CSV: $e')),
        );
      }
    }
  }

  Future<void> _restoreDatabase() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF151929) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Pulihkan Database?', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text(
            'Tindakan ini akan menimpa seluruh data transaksi, anggaran, dan pengaturan Anda saat ini dengan file cadangan yang diunggah. Tindakan ini tidak dapat dibatalkan.\n\nApakah Anda yakin ingin melanjutkan?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Batal', style: TextStyle(color: isDark ? Colors.white60 : Colors.black54)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Ya, Pulihkan', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.any,
      );

      if (result == null || result.files.single.path == null) {
        return;
      }

      final pickedPath = result.files.single.path!;
      final extension = p.extension(pickedPath).toLowerCase();
      if (extension != '.db' && extension != '.sqlite') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Format file tidak valid. Pilih file database (.db atau .sqlite).')),
          );
        }
        return;
      }

      await DatabaseService().restoreDatabase(pickedPath);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Database berhasil dipulihkan dari file cadangan!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memulihkan database: $e')),
        );
      }
    }
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
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ValueListenableBuilder<bool>(
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
              ],
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(LucideIcons.arrow_left_right, color: Color(0xFF10B981), size: 22),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Aksi & Cadangan Data',
                              style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.bold),
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
                    child: DropdownButton<String>(
                      value: null,
                      hint: Text(
                        'Pilih Aksi',
                        style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      dropdownColor: isDark ? const Color(0xFF0F1223) : Colors.white,
                      icon: Icon(Icons.arrow_drop_down, color: subTextColor, size: 18),
                      style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold),
                      onChanged: (String? val) {
                        if (val == 'export_csv') {
                          _exportToCSV();
                        } else if (val == 'backup_sqlite') {
                          _backupDatabase();
                        } else if (val == 'import_csv') {
                          _importCSV();
                        } else if (val == 'restore_sqlite') {
                          _restoreDatabase();
                        }
                      },
                      items: [
                        DropdownMenuItem(
                          value: 'export_csv',
                          child: Row(
                            children: [
                              Icon(LucideIcons.file_spreadsheet, color: const Color(0xFF10B981), size: 16),
                              const SizedBox(width: 8),
                              const Text('Ekspor ke CSV'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'backup_sqlite',
                          child: Row(
                            children: [
                              Icon(LucideIcons.database, color: const Color(0xFF3B82F6), size: 16),
                              const SizedBox(width: 8),
                              const Text('Backup SQLite (.db)'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'import_csv',
                          child: Row(
                            children: [
                              Icon(LucideIcons.file_up, color: const Color(0xFFF59E0B), size: 16),
                              const SizedBox(width: 8),
                              const Text('Unggah & Impor CSV'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'restore_sqlite',
                          child: Row(
                            children: [
                              Icon(LucideIcons.upload, color: const Color(0xFFEF4444), size: 16),
                              const SizedBox(width: 8),
                              const Text('Unggah & Pulihkan SQLite'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
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
