import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uangku/services/biometric_service.dart';
import 'package:uangku/services/database_service.dart';
import 'widgets/liquid_glass_background.dart';
import 'widgets/glass_card.dart';
import 'widgets/add_transaction_sheet.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'screens/lock_screen.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';

// Notifikasi Nilai Global Reaktif
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);
final ValueNotifier<bool> biometricEnabledNotifier = ValueNotifier(false);
final ValueNotifier<bool> notificationsEnabledNotifier = ValueNotifier(false);

void main() {
  runApp(const UangkuApp());
}

class UangkuApp extends StatelessWidget {
  const UangkuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, currentThemeMode, __) {
        return MaterialApp(
          title: 'Uangku',
          debugShowCheckedModeBanner: false,
          themeMode: currentThemeMode,
          theme: ThemeData(
            brightness: Brightness.light,
            fontFamily: GoogleFonts.outfit().fontFamily,
            useMaterial3: true,
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF00ADB5),
              secondary: Color(0xFFF355DA),
              surface: Color(0xFFF4F6F9),
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            fontFamily: GoogleFonts.outfit().fontFamily,
            useMaterial3: true,
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF00F2FE),
              secondary: Color(0xFFF355DA),
              surface: Color(0xFF0E1122),
            ),
          ),
          home: const MainNavigationShell(),
        );
      },
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;
  bool _isUnlocked = false; // Kunci startup biometrik sukses

  // Tampilkan form penambahan transaksi cepat
  void _showAddTransactionForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddTransactionSheet(),
    );
  }

  void _handleLogout() async {
    await AuthService().logout();
    setState(() {
      _currentIndex = 0;
      _isUnlocked = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    // 1. Jika belum login, paksa tampilkan LoginScreen bertema Liquid Glass
    if (!authService.isLoggedIn) {
      return LoginScreen(
        onLoginSuccess: () {
          setState(() {
            // Memicu pengecekan biometrik sesudah login sukses jika diaktifkan sebelumnya
            _isUnlocked = !biometricEnabledNotifier.value;
          });
        },
      );
    }

    // 2. Jika sudah login tetapi biometrik aktif dan belum dibuka kunci
    if (biometricEnabledNotifier.value && !_isUnlocked) {
      return LockScreen(
        onUnlockSuccess: () {
          setState(() {
            _isUnlocked = true;
          });
        },
      );
    }

    // 3. Alur konten halaman utama
    final List<Widget> pages = [
      DashboardScreen(onAddTransactionPressed: _showAddTransactionForm),
      const _AnalyticsTab(),
      const _BudgetsTab(),
      _SettingsTab(onLogout: _handleLogout),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LiquidGlassBackground(
        child: Stack(
          children: [
            // Konten halaman aktif
            pages[_currentIndex],

            // Floating Navigation Bar melayang bertema premium glass
            Positioned(
              left: 20,
              right: 20,
              bottom: 24,
              child: _buildFloatingNavigationBar(),
            ),
          ],
        ),
      ),
    );
  }

  // Bar Navigasi Melayang dengan Efek Kaca Transparan & Orbs Tengah Bercahaya
  Widget _buildFloatingNavigationBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 75,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(isDark ? 0.08 : 0.65),
                Colors.white.withOpacity(isDark ? 0.02 : 0.35),
              ],
            ),
            border: Border.all(
              color: Colors.white.withOpacity(isDark ? 0.12 : 0.4),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, LucideIcons.house, 'Home'),
              _buildNavItem(1, LucideIcons.chart_pie, 'Analisis'),
              
              // Tombol Tambah Tengah yang menonjol dan bercahaya
              GestureDetector(
                onTap: _showAddTransactionForm,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF00ADB5),
                        Color(0xFF7000FF),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00ADB5).withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    LucideIcons.plus,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),

              _buildNavItem(2, LucideIcons.target, 'Anggaran'),
              _buildNavItem(3, LucideIcons.settings, 'Setelan'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Warna aktif & tidak aktif menyesuaikan kecerahan tema
    final activeColor = index == 1 || index == 0 
        ? (isDark ? const Color(0xFF00F2FE) : const Color(0xFF00ADB5)) 
        : const Color(0xFFF355DA);
    final inactiveColor = isDark ? Colors.white38 : Colors.black38;

    return InkWell(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? activeColor : inactiveColor,
            size: 22,
          ),
          const SizedBox(height: 5),
          // Micro Indicator (Garis Kecil Aktif)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 3,
            width: isSelected ? 16 : 0,
            decoration: BoxDecoration(
              color: activeColor,
              borderRadius: BorderRadius.circular(2),
              boxShadow: [
                BoxShadow(
                  color: activeColor.withOpacity(0.6),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- WIDGET HALAMAN SETELAN (SETTINGS SCREEN) REAL ---

class _SettingsTab extends StatefulWidget {
  final VoidCallback onLogout;

  const _SettingsTab({required this.onLogout});

  @override
  State<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<_SettingsTab> {
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
                  icon: Icon(LucideIcons.log_out, color: Colors.redAccent, size: 22),
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
                          Icon(LucideIcons.fingerprint_pattern, color: const Color(0xFF00ADB5), size: 22),
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
                          // Prompt user to verify biometrics before enabling
                          final success = await BiometricService().authenticate();
                          if (success) {
                            biometricEnabledNotifier.value = true;
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Proteksi biometrik berhasil diaktifkan!')),
                              );
                            }
                          } else {
                            biometricEnabledNotifier.value = false;
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Verifikasi biometrik gagal!')),
                              );
                            }
                          }
                        } else {
                          biometricEnabledNotifier.value = false;
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
                          Icon(LucideIcons.bell_ring, color: const Color(0xFFF355DA), size: 22),
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
                      onChanged: (value) {
                        notificationsEnabledNotifier.value = value;
                        // Jadwalkan notifikasi lokal
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
        Icon(LucideIcons.chevron_right, color: Colors.white30, size: 16),
      ],
    );
  }
}

// --- WIDGET HALAMAN ANALISIS REALTIME ---

class _AnalyticsTab extends StatefulWidget {
  const _AnalyticsTab();

  @override
  State<_AnalyticsTab> createState() => _AnalyticsTabState();
}

class _AnalyticsTabState extends State<_AnalyticsTab> {
  final _dbService = DatabaseService();
  final _authService = AuthService();

  bool _isLoading = true;
  double _income = 0.0;
  double _expense = 0.0;
  Map<String, double> _categoryExpenses = {};

  final Map<String, Map<String, dynamic>> _catStyles = {
    'F&B': {'color': const Color(0xFFFFB300), 'icon': LucideIcons.coffee},
    'Transport': {'color': const Color(0xFF00E676), 'icon': LucideIcons.car},
    'Hiburan': {'color': const Color(0xFFE50914), 'icon': LucideIcons.play},
    'Shopping': {'color': const Color(0xFF00F2FE), 'icon': LucideIcons.shopping_bag},
    'Tagihan': {'color': const Color(0xFFFF5252), 'icon': LucideIcons.receipt},
    'Lainnya': {'color': const Color(0xFFA5B4FC), 'icon': LucideIcons.ellipsis},
  };

  @override
  void initState() {
    super.initState();
    _loadData();
    DatabaseService.changeNotifier.addListener(_loadData);
  }

  @override
  void dispose() {
    DatabaseService.changeNotifier.removeListener(_loadData);
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    final email = _authService.currentUser?.email ?? 'adrian@uangku.com';
    final summary = await _dbService.getSummaryForUser(email);
    final breakdown = await _dbService.getExpenseByCategory(email);

    if (mounted) {
      setState(() {
        _income = summary['income'] ?? 0.0;
        _expense = summary['expense'] ?? 0.0;
        _categoryExpenses = breakdown;
        _isLoading = false;
      });
    }
  }

  String _formatRupiah(double val) {
    final str = val.toStringAsFixed(0);
    final reg = RegExp(r'\B(?=(\d{3})+(?!\d))');
    final formatted = str.replaceAllMapped(reg, (Match m) => '.');
    return 'Rp $formatted';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subTextColor = isDark ? Colors.white60 : const Color(0xFF475569);

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF00ADB5)),
      );
    }

    final totalSpent = _expense;

    // Filter categories dengan pengeluaran positif, urutkan dari yang terbesar
    final activeCategories = _categoryExpenses.entries
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analisis Arus Kas',
            style: TextStyle(
              color: textColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 20),

          // 1. Ringkasan Pemasukan vs Pengeluaran Card
          GlassCard(
            borderRadius: 24,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('RINGKASAN CASH FLOW', style: TextStyle(color: subTextColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    const Icon(LucideIcons.chart_spline, color: Color(0xFF00ADB5), size: 16),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Pemasukan', style: TextStyle(color: Colors.greenAccent, fontSize: 11)),
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(_formatRupiah(_income), style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                    Container(height: 30, width: 1, color: isDark ? Colors.white12 : Colors.black12),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Pengeluaran', style: TextStyle(color: Colors.redAccent, fontSize: 11)),
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(_formatRupiah(_expense), style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Dual Gradient Slider
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    height: 8,
                    width: double.infinity,
                    color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05),
                    child: totalSpent + _income == 0
                        ? Container()
                        : FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: _income / (_income + totalSpent),
                            child: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xFF00ADB5), Color(0xFF00E676)],
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          if (totalSpent == 0) ...[
            // Tampilan Kosong yang Elegan
            GlassCard(
              borderRadius: 24,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              child: Column(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00ADB5).withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF00ADB5).withOpacity(0.3)),
                    ),
                    child: const Icon(LucideIcons.chart_pie, color: Color(0xFF00ADB5), size: 30),
                  ),
                  const SizedBox(height: 20),
                  Text('Belum Ada Transaksi Pengeluaran', style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    'Catat transaksi pengeluaran pertama Anda di halaman depan untuk memetakan diagram analisis pengeluaran.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: subTextColor, fontSize: 12, height: 1.5),
                  ),
                ],
              ),
            ),
          ] else ...[
            // 2. Ring Chart (Donut Chart) Card
            GlassCard(
              borderRadius: 24,
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Sisi Kiri: Donut Chart Custom Paint
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: CustomPaint(
                      painter: _DonutChartPainter(
                        categoryExpenses: _categoryExpenses,
                        styles: _catStyles,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Sisi Kanan: Legend Dinamis
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: activeCategories.take(3).map((e) {
                        final style = _catStyles[e.key] ?? _catStyles['Lainnya']!;
                        final color = style['color'] as Color;
                        final percent = (e.value / totalSpent) * 100;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  e.key,
                                  style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text('${percent.toStringAsFixed(0)}%', style: TextStyle(color: subTextColor, fontSize: 11)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 3. Rincian per Kategori
            Text(
              'RINCIAN PENGELUARAN',
              style: TextStyle(color: subTextColor, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.2),
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activeCategories.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final entry = activeCategories[index];
                final catName = entry.key;
                final amount = entry.value;
                final style = _catStyles[catName] ?? _catStyles['Lainnya']!;
                final icon = style['icon'] as IconData;
                final color = style['color'] as Color;
                final percent = amount / totalSpent;

                return GlassCard(
                  borderRadius: 20,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.12),
                              shape: BoxShape.circle,
                              border: Border.all(color: color.withOpacity(0.3)),
                            ),
                            child: Icon(icon, color: color, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(catName, style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 2),
                                Text('${(percent * 100).toStringAsFixed(0)}% dari total pengeluaran', style: TextStyle(color: subTextColor, fontSize: 11)),
                              ],
                            ),
                          ),
                          Text(_formatRupiah(amount), style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Progress Bar Kategori
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: percent,
                          backgroundColor: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
          const SizedBox(height: 120),
        ],
      ),
    );
  }
}

// Painter Custom Donut Chart Premium
class _DonutChartPainter extends CustomPainter {
  final Map<String, double> categoryExpenses;
  final Map<String, Map<String, dynamic>> styles;

  _DonutChartPainter({required this.categoryExpenses, required this.styles});

  @override
  void paint(Canvas canvas, Size size) {
    final double total = categoryExpenses.values.fold(0, (sum, val) => sum + val);
    if (total == 0) return;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    double startAngle = -3.14 / 2;

    for (var entry in categoryExpenses.entries) {
      if (entry.value == 0) continue;
      final style = styles[entry.key] ?? styles['Lainnya']!;
      paint.color = style['color'] as Color;

      final sweepAngle = (entry.value / total) * 3.14 * 2;
      canvas.drawArc(rect, startAngle, sweepAngle - 0.08, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// --- WIDGET HALAMAN ANGGARAN REALTIME ---

class _BudgetsTab extends StatefulWidget {
  const _BudgetsTab();

  @override
  State<_BudgetsTab> createState() => _BudgetsTabState();
}

class _BudgetsTabState extends State<_BudgetsTab> {
  final _dbService = DatabaseService();
  final _authService = AuthService();

  bool _isLoading = true;
  List<Map<String, dynamic>> _budgets = [];
  Map<String, double> _categoryExpenses = {};

  final Map<String, Map<String, dynamic>> _catStyles = {
    'F&B': {'color': const Color(0xFFFFB300), 'icon': LucideIcons.coffee},
    'Transport': {'color': const Color(0xFF00E676), 'icon': LucideIcons.car},
    'Hiburan': {'color': const Color(0xFFE50914), 'icon': LucideIcons.play},
    'Shopping': {'color': const Color(0xFF00F2FE), 'icon': LucideIcons.shopping_bag},
    'Tagihan': {'color': const Color(0xFFFF5252), 'icon': LucideIcons.receipt},
    'Lainnya': {'color': const Color(0xFFA5B4FC), 'icon': LucideIcons.ellipsis},
  };

  @override
  void initState() {
    super.initState();
    _loadData();
    DatabaseService.changeNotifier.addListener(_loadData);
  }

  @override
  void dispose() {
    DatabaseService.changeNotifier.removeListener(_loadData);
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    final email = _authService.currentUser?.email ?? 'adrian@uangku.com';
    final budgetList = await _dbService.getBudgetsForUser(email);
    final breakdown = await _dbService.getExpenseByCategory(email);

    if (mounted) {
      setState(() {
        _budgets = budgetList;
        _categoryExpenses = breakdown;
        _isLoading = false;
      });
    }
  }

  String _formatRupiah(double val) {
    final str = val.toStringAsFixed(0);
    final reg = RegExp(r'\B(?=(\d{3})+(?!\d))');
    final formatted = str.replaceAllMapped(reg, (Match m) => '.');
    return 'Rp $formatted';
  }

  void _showSetBudgetForm([String? existingCategory, double? existingAmount]) {
    final TextEditingController amountController = TextEditingController(
      text: existingAmount != null ? existingAmount.toStringAsFixed(0) : '',
    );
    String selectedCategory = existingCategory ?? 'F&B';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
        final subTextColor = isDark ? Colors.white60 : const Color(0xFF475569);
        final inputBgColor = isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03);
        final inputBorderColor = isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.08);

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
              child: Container(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 10,
                  bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
                ),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0E1122).withOpacity(0.85) : const Color(0xFFF1F5F9).withOpacity(0.92),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                  border: Border(
                    top: BorderSide(
                      color: isDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.08),
                      width: 1.5,
                    ),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 50,
                        height: 5,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.black26,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      existingCategory != null ? 'Edit Batas Anggaran' : 'Setel Batas Anggaran',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Dropdown Kategori
                    Text('KATEGORI BELANJA', style: TextStyle(color: subTextColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: inputBgColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: inputBorderColor),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedCategory,
                          dropdownColor: isDark ? const Color(0xFF0F1223) : Colors.white,
                          icon: Icon(Icons.arrow_drop_down, color: subTextColor),
                          style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.bold),
                          onChanged: existingCategory != null ? null : (String? newValue) {
                            if (newValue != null) {
                              setSheetState(() {
                                selectedCategory = newValue;
                              });
                            }
                          },
                          items: _catStyles.keys.map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Batas Anggaran (Amount)
                    Text('LIMIT ANGGARAN BULANAN (RP)', style: TextStyle(color: subTextColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: inputBgColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: inputBorderColor),
                      ),
                      child: TextField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(LucideIcons.target, color: Color(0xFFF355DA), size: 20),
                          prefixIconConstraints: const BoxConstraints(minWidth: 46),
                          hintText: 'Contoh: 1000000',
                          hintStyle: TextStyle(color: subTextColor.withOpacity(0.5), fontSize: 14),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Simpan Button
                    GestureDetector(
                      onTap: () async {
                        final valText = amountController.text.trim();
                        if (valText.isEmpty) return;

                        final limit = double.tryParse(valText) ?? 0.0;
                        if (limit <= 0) return;

                        final email = _authService.currentUser?.email ?? 'adrian@uangku.com';
                        await _dbService.insertOrUpdateBudget(selectedCategory, limit, email);

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Batas anggaran berhasil diperbarui!')),
                          );
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00ADB5), Color(0xFFF355DA)],
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'Simpan Anggaran',
                            style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _deleteBudget(String category) async {
    final email = _authService.currentUser?.email ?? 'adrian@uangku.com';
    await _dbService.deleteBudget(category, email);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Batas anggaran berhasil dihapus.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subTextColor = isDark ? Colors.white60 : const Color(0xFF475569);

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFF355DA)),
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Batas Anggaran',
                style: TextStyle(
                  color: textColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              // Tombol Tambah Anggaran
              GestureDetector(
                onTap: () => _showSetBudgetForm(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00ADB5), Color(0xFFF355DA)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF355DA).withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Row(
                    children: [
                      Icon(LucideIcons.plus, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Set Anggaran',
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (_budgets.isEmpty) ...[
            // Onboarding Card jika kosong
            GlassCard(
              borderRadius: 24,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              child: Column(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF355DA).withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFF355DA).withOpacity(0.3)),
                    ),
                    child: const Icon(LucideIcons.target, color: Color(0xFFF355DA), size: 30),
                  ),
                  const SizedBox(height: 20),
                  Text('Belum Ada Anggaran Disetel', style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    'Pasang batasan limit belanja per kategori agar keuangan Anda terkontrol secara cerdas dan terhindar dari perilaku boros.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: subTextColor, fontSize: 12, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () => _showSetBudgetForm(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFF355DA).withOpacity(0.5)),
                        color: const Color(0xFFF355DA).withOpacity(0.1),
                      ),
                      child: const Text('Buat Anggaran Pertama Anda', style: TextStyle(color: Color(0xFFF355DA), fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _budgets.length,
              separatorBuilder: (context, index) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final budget = _budgets[index];
                final catName = budget['category'] as String;
                final limitAmount = budget['amount'] as double;
                final spentAmount = _categoryExpenses[catName] ?? 0.0;
                final percent = limitAmount > 0 ? (spentAmount / limitAmount) : 0.0;

                final style = _catStyles[catName] ?? _catStyles['Lainnya']!;
                final icon = style['icon'] as IconData;
                final baseColor = style['color'] as Color;

                // Hitung warna progres dinamis
                Color progressBarColor = baseColor;
                bool isWarning = false;
                bool isExceeded = false;

                if (percent > 1.0) {
                  progressBarColor = const Color(0xFFFF5252);
                  isExceeded = true;
                } else if (percent > 0.8) {
                  progressBarColor = const Color(0xFFFFB300);
                  isWarning = true;
                }

                return GlassCard(
                  borderRadius: 22,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: baseColor.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icon, color: baseColor, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(catName, style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.bold)),
                                    if (isExceeded) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(color: const Color(0xFFFF5252).withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                                        child: const Text('Over Limit!', style: TextStyle(color: Color(0xFFFF5252), fontSize: 9, fontWeight: FontWeight.bold)),
                                      ),
                                    ] else if (isWarning) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(color: const Color(0xFFFFB300).withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                                        child: const Text('Hampir Habis!', style: TextStyle(color: Color(0xFFFFB300), fontSize: 9, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(_formatRupiah(spentAmount), style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold)),
                                    Text(' / ${_formatRupiah(limitAmount)}', style: TextStyle(color: subTextColor, fontSize: 12)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Edit & Delete Actions
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(LucideIcons.pencil, color: Colors.white54, size: 16),
                                onPressed: () => _showSetBudgetForm(catName, limitAmount),
                              ),
                              IconButton(
                                icon: const Icon(LucideIcons.trash_2, color: Colors.redAccent, size: 16),
                                onPressed: () => _deleteBudget(catName),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Progress Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: percent > 1.0 ? 1.0 : percent,
                          backgroundColor: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
                          valueColor: AlwaysStoppedAnimation<Color>(progressBarColor),
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${(percent * 100).toStringAsFixed(0)}% terpakai',
                          style: TextStyle(color: isExceeded ? const Color(0xFFFF5252) : subTextColor, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
          const SizedBox(height: 120),
        ],
      ),
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final String description;

  const _PlaceholderScreen({
    required this.title,
    required this.icon,
    required this.color,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subTextColor = isDark ? Colors.white54 : const Color(0xFF64748B);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Glowing Icon Header
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Icon(icon, color: color, size: 36),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(
              color: textColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: subTextColor,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 30),
          GlassCard(
            borderRadius: 20,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Icon(LucideIcons.info, color: color, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Fitur offline penuh sedang disiapkan di atas database SQLite lokal.',
                    style: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF334155), fontSize: 12, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
