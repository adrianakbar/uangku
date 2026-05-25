import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uangku/services/biometric_service.dart';
import 'package:uangku/services/database_service.dart';
import 'widgets/liquid_glass_background.dart';
import 'widgets/glass_card.dart';
import 'widgets/add_transaction_sheet.dart';
import 'widgets/floating_navigation_bar.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'screens/lock_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/history_screen.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/widget_service.dart';

// Notifikasi Nilai Global Reaktif
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);
final ValueNotifier<bool> biometricEnabledNotifier = ValueNotifier(false);
final ValueNotifier<bool> notificationsEnabledNotifier = ValueNotifier(false);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();
  await WidgetService.init();
  runApp(const UangkuApp());
}

class UangkuApp extends StatelessWidget {
  const UangkuApp({super.key});

  String? _getFontFamily() {
    try {
      if (Platform.environment.containsKey('FLUTTER_TEST')) {
        return null;
      }
    } catch (_) {}
    return GoogleFonts.inter().fontFamily;
  }

  @override
  Widget build(BuildContext context) {
    final font = _getFontFamily();
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, currentThemeMode, __) {
        return MaterialApp(
          title: 'Uangku',
          debugShowCheckedModeBanner: false,
          themeMode: currentThemeMode,
          theme: ThemeData(
            brightness: Brightness.light,
            fontFamily: font,
            useMaterial3: true,
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF00ADB5),
              secondary: Color(0xFFF355DA),
              surface: Color(0xFFF4F6F9),
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            fontFamily: font,
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
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _initPersistentState();
  }

  Future<void> _initPersistentState() async {
    final db = DatabaseService();
    
    // 1. Pulihkan sesi login dari SQLite
    await AuthService().restoreSession();

    // 2. Pulihkan setelan biometrik
    final bioEnabled = await db.getSetting('biometric_enabled');
    biometricEnabledNotifier.value = bioEnabled == 'true';
    
    // 3. Pulihkan setelan notifikasi
    final notifEnabled = await db.getSetting('notifications_enabled');
    notificationsEnabledNotifier.value = notifEnabled == 'true';

    // 4. Pulihkan setelan tema aplikasi (Terang, Gelap, Sistem)
    final savedTheme = await db.getSetting('theme_mode');
    if (savedTheme == 'light') {
      themeNotifier.value = ThemeMode.light;
    } else if (savedTheme == 'dark') {
      themeNotifier.value = ThemeMode.dark;
    } else {
      themeNotifier.value = ThemeMode.system;
    }
    
    // 5. Push data terbaru ke widget Android (jika sudah login)
    WidgetService().updateWidget();

    if (mounted) {
      setState(() {
        _isUnlocked = !biometricEnabledNotifier.value;
        _isInitializing = false;
      });
    }
  }

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
    await WidgetService().clearWidget();
    setState(() {
      _currentIndex = 0;
      _isUnlocked = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    if (_isInitializing) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: LiquidGlassBackground(
          child: Center(
            child: CircularProgressIndicator(color: Color(0xFF00ADB5)),
          ),
        ),
      );
    }

    // 1. Jika belum login, paksa tampilkan LoginScreen bertema Liquid Glass
    if (!authService.isLoggedIn) {
      return LoginScreen(
        onLoginSuccess: () {
          WidgetService().updateWidget();
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
      const AnalyticsScreen(),
      const HistoryScreen(),
      SettingsScreen(onLogout: _handleLogout),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false,
      body: LiquidGlassBackground(
        child: Stack(
          children: [
            // Konten halaman aktif diposisikan memenuhi layar agar Stack tetap full screen
            Positioned.fill(
              child: pages[_currentIndex],
            ),

            // Floating Navigation Bar melayang bertema premium glass
            Positioned(
              left: 20,
              right: 20,
              bottom: 24,
              child: FloatingNavigationBar(
                currentIndex: _currentIndex,
                onTap: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                onAddTap: _showAddTransactionForm,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
