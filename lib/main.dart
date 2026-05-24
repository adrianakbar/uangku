import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'widgets/liquid_glass_background.dart';
import 'widgets/glass_card.dart';
import 'widgets/add_transaction_sheet.dart';
import 'screens/dashboard_screen.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

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
            fontFamily: 'Inter',
            useMaterial3: true,
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF00ADB5),
              secondary: Color(0xFFF355DA),
              surface: Color(0xFFF4F6F9),
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            fontFamily: 'Inter',
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

  // Tampilkan form penambahan transaksi cepat
  void _showAddTransactionForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddTransactionSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // List halaman berdasarkan indeks aktif
    final List<Widget> pages = [
      DashboardScreen(onAddTransactionPressed: _showAddTransactionForm),
      const _AnalyticsPlaceholder(),
      const _BudgetsPlaceholder(),
      const _SettingsPlaceholder(),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LiquidGlassBackground(
        child: Stack(
          children: [
            // 1. Konten Halaman Aktif
            pages[_currentIndex],

            // 2. Floating Liquid Glass Navigation Bar (Desain Melayang Super Premium)
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
                        Color(0xFF00F2FE),
                        Color(0xFF7000FF),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00F2FE).withOpacity(0.4),
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

// --- WIDGET PLACEHOLDER UNTUK HALAMAN SUB ---

class _AnalyticsPlaceholder extends StatelessWidget {
  const _AnalyticsPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const _PlaceholderScreen(
      title: 'Analisis Keuangan',
      icon: LucideIcons.chart_pie,
      color: Color(0xFF00F2FE),
      description: 'Laporan visualisasi pengeluaran dan pemasukan bulanan Anda dengan bagan interaktif yang detail.',
    );
  }
}

class _BudgetsPlaceholder extends StatelessWidget {
  const _BudgetsPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const _PlaceholderScreen(
      title: 'Batas Anggaran',
      icon: LucideIcons.target,
      color: Color(0xFFF355DA),
      description: 'Setel dan pantau batasan belanja per kategori untuk mencegah pemborosan sebelum terlambat.',
    );
  }
}

class _SettingsPlaceholder extends StatelessWidget {
  const _SettingsPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const _PlaceholderScreen(
      title: 'Pengaturan Lokal',
      icon: LucideIcons.settings,
      color: Color(0xFFA5B4FC),
      description: 'Konfigurasi biometrik lokal, backup data database SQLite, ekspor CSV, dan setelan tema visual.',
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
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white54,
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
                const Expanded(
                  child: Text(
                    'Fitur offline penuh sedang disiapkan di atas database SQLite lokal.',
                    style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
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
