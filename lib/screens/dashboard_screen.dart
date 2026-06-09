import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../widgets/glass_card.dart';
import '../widgets/text_style_helper.dart';
import '../widgets/expandable_text.dart';
import '../main.dart'; // Akses themeNotifier global
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../theme/design_system.dart';

// Enum untuk opsi filter periode
enum _FilterPeriod { hari, minggu, bulan, tahun, rentang }

class DashboardScreen extends StatefulWidget {
  final VoidCallback onAddTransactionPressed;

  const DashboardScreen({super.key, required this.onAddTransactionPressed});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _dbService = DatabaseService();
  final _authService = AuthService();

  bool _isLoading = true;
  double _balance = 0.0;
  double _income = 0.0;
  double _expense = 0.0;
  List<Map<String, dynamic>> _transactions = [];
  List<double> _weeklyExpenses = [0, 0, 0, 0, 0, 0, 0];
  double _weeklyAverage = 0.0;

  // State Filter
  _FilterPeriod _selectedFilter = _FilterPeriod.hari;
  DateTime? _customStart;
  DateTime? _customEnd;

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

  // Konversi enum filter → rentang tanggal
  (DateTime?, DateTime?) _getDateRange() {
    final now = DateTime.now();
    switch (_selectedFilter) {
      case _FilterPeriod.hari:
        final start = DateTime(now.year, now.month, now.day);
        return (start, now);
      case _FilterPeriod.minggu:
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final start = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        return (start, now);
      case _FilterPeriod.bulan:
        final start = DateTime(now.year, now.month, 1);
        return (start, now);
      case _FilterPeriod.tahun:
        final start = DateTime(now.year, 1, 1);
        return (start, now);
      case _FilterPeriod.rentang:
        return (_customStart, _customEnd);
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    final email = _authService.currentUser?.email ?? 'adrian@uangku.com';

    // Pastikan database terisi data awal demo jika baru terdaftar
    await _dbService.seedDefaultDataForUser(email);

    final (startDate, endDate) = _getDateRange();

    final summary = await _dbService.getSummaryForUserFiltered(
      email,
      startDate: startDate,
      endDate: endDate,
    );
    final txs = await _dbService.getTransactionsForUserFiltered(
      email,
      startDate: startDate,
      endDate: endDate,
    );

    // Hitung tren pengeluaran pekan ini (Senin s.d. Minggu)
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final weekStart = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    final weekTransactions = await _dbService.getTransactionsForUserFiltered(
      email,
      startDate: weekStart,
      endDate: now,
    );

    final List<double> weeklyTrend = List.filled(7, 0.0);
    for (var tx in weekTransactions) {
      if (tx['is_expense'] == 1) {
        final dateStr = tx['date'] as String;
        final txDate = DateTime.tryParse(dateStr);
        if (txDate != null) {
          final dayIndex = txDate.weekday - 1;
          if (dayIndex >= 0 && dayIndex < 7) {
            weeklyTrend[dayIndex] += (tx['amount'] as num).toDouble();
          }
        }
      }
    }

    final double weeklySum = weeklyTrend.reduce((a, b) => a + b);
    final int daysPassed = now.weekday;
    final double weeklyAvg = daysPassed > 0 ? weeklySum / daysPassed : 0.0;

    if (mounted) {
      setState(() {
        _balance = summary['balance'] ?? 0.0;
        _income = summary['income'] ?? 0.0;
        _expense = summary['expense'] ?? 0.0;
        _transactions = txs;
        _weeklyExpenses = weeklyTrend;
        _weeklyAverage = weeklyAvg;
        _isLoading = false;
      });
    }
  }

  // Buka date range picker untuk filter Rentang
  Future<void> _pickCustomDateRange(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: (_customStart != null && _customEnd != null)
          ? DateTimeRange(start: _customStart!, end: _customEnd!)
          : DateTimeRange(
              start: now.subtract(const Duration(days: 30)),
              end: now,
            ),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? ColorScheme.dark(
                    primary: Theme.of(context).colorScheme.primary,
                    onPrimary: Colors.white,
                    surface: AppColors.surfaceDark,
                    onSurface: Colors.white,
                  )
                : ColorScheme.light(
                    primary: Theme.of(context).colorScheme.primary,
                    onPrimary: Colors.white,
                    surface: AppColors.surfaceLight,
                    onSurface: AppColors.textLightPrimary,
                  ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _customStart = picked.start;
        _customEnd = picked.end;
      });
      await _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header (Profil, Switcher Tema & Notifikasi)
          const _DashboardHeader(),
          const SizedBox(height: 25),

          // 2. Total Balance Card (Glassmorphic Card Utama)
          _isLoading
              ? SizedBox(
                  height: 180,
                  child: Center(
                    child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
                  ),
                )
              : _BalanceCard(
                  balance: _balance,
                  income: _income,
                  expense: _expense,
                ),
          const SizedBox(height: 25),

          // 3. Section Title & Visual Liquid Analytics Wave
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tren Pengeluaran Pekan Ini',
                style: plusJakartaStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              Icon(
                LucideIcons.trending_up,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 15),
          _LiquidAnalyticsWave(
            weeklyExpenses: _weeklyExpenses,
            dailyAverage: _weeklyAverage,
          ),
          const SizedBox(height: 25),

          // 4. Filter Pengeluaran
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Riwayat Transaksi',
                style: plusJakartaStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              Icon(
                LucideIcons.circle_dollar_sign,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Filter Chip Bar
          _FilterChipBar(
            selectedFilter: _selectedFilter,
            customStart: _customStart,
            customEnd: _customEnd,
            onFilterChanged: (filter) async {
              setState(() {
                _selectedFilter = filter;
              });
              if (filter == _FilterPeriod.rentang) {
                await _pickCustomDateRange(context);
              } else {
                await _loadData();
              }
            },
            onCustomRangeTap: () => _pickCustomDateRange(context),
          ),
          const SizedBox(height: 15),

          // 5. Riwayat Transaksi Terbaru
          _isLoading
              ? Center(
                  child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
                )
              : _RecentTransactionsList(transactions: _transactions),
          const SizedBox(height: 100), // Spasi agar tidak tertutup Bottom Bar
        ],
      ),
    );
  }
}

// --- WIDGET FILTER CHIP BAR ---
class _FilterChipBar extends StatelessWidget {
  final _FilterPeriod selectedFilter;
  final DateTime? customStart;
  final DateTime? customEnd;
  final ValueChanged<_FilterPeriod> onFilterChanged;
  final VoidCallback onCustomRangeTap;

  const _FilterChipBar({
    required this.selectedFilter,
    required this.customStart,
    required this.customEnd,
    required this.onFilterChanged,
    required this.onCustomRangeTap,
  });

  String _rangeLabel() {
    if (customStart == null || customEnd == null) return 'Rentang';
    final months = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'];
    final s = customStart!;
    final e = customEnd!;
    if (s.year == e.year && s.month == e.month) {
      return '${s.day}–${e.day} ${months[s.month - 1]}';
    }
    return '${s.day} ${months[s.month - 1]} – ${e.day} ${months[e.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filters = [
      (_FilterPeriod.hari, 'Hari Ini'),
      (_FilterPeriod.minggu, 'Minggu'),
      (_FilterPeriod.bulan, 'Bulan'),
      (_FilterPeriod.tahun, 'Tahun'),
      (_FilterPeriod.rentang, _rangeLabel()),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: filters.map((entry) {
          final (filter, label) = entry;
          final isSelected = selectedFilter == filter;
          final isRentang = filter == _FilterPeriod.rentang;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                if (isSelected && isRentang) {
                  onCustomRangeTap();
                } else {
                  onFilterChanged(filter);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.primary.withOpacity(0.7)],
                        )
                      : null,
                  color: isSelected
                      ? null
                      : (isDark ? Colors.white.withOpacity(0.07) : Colors.black.withOpacity(0.05)),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : (isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.08)),
                    width: 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isRentang) ...[
                      Icon(
                        LucideIcons.calendar_range,
                        size: 12,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? AppColors.textDarkTertiary : AppColors.textLightTertiary),
                      ),
                      const SizedBox(width: 5),
                    ],
                    Text(
                      label,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : (isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary),
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// --- WIDGET HEADER ---
class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader();

  // Helper: Menentukan sumber gambar avatar
  ImageProvider? _buildAvatarImage(String? photoUrl) {
    if (photoUrl == null) return null;
    if (photoUrl.startsWith('http://') || photoUrl.startsWith('https://')) {
      return NetworkImage(photoUrl);
    }
    return FileImage(File(photoUrl));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary;
    final subTextColor = isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary;
    final buttonBg = (isDark ? Colors.white : Colors.black).withOpacity(0.06);
    final buttonIconColor = isDark ? Colors.white : AppColors.textLightPrimary;

    final user = AuthService().currentUser;
    final displayName = user?.displayName ?? 'Adrian';
    final firstLetter = displayName.isNotEmpty
        ? displayName.substring(0, 1).toUpperCase()
        : 'A';
    final photoUrl = user?.photoUrl;
    final avatarImage = _buildAvatarImage(photoUrl);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              // Glowing Avatar Ring
              Container(
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary],
                  ),
                ),
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.bgDark,
                  backgroundImage: avatarImage,
                  child: avatarImage == null
                      ? Text(
                          firstLetter,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Halo, $displayName',
                      style: plusJakartaStyle(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Kelola uangmu dengan bijak!',
                      style: TextStyle(
                        color: subTextColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),

        // Row of buttons: Theme Switcher & Notifications
        Row(
          children: [
            // Dynamic Theme Switcher Button
            ClipOval(
              child: Container(
                color: buttonBg,
                child: IconButton(
                  icon: Icon(
                    isDark ? LucideIcons.sun : LucideIcons.moon,
                    color: buttonIconColor,
                    size: 22,
                  ),
                  onPressed: () async {
                    final nextMode = isDark ? ThemeMode.light : ThemeMode.dark;
                    themeNotifier.value = nextMode;
                    await DatabaseService().saveSetting(
                      'theme_mode',
                      nextMode == ThemeMode.light ? 'light' : 'dark',
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Notification Bell Button
            ClipOval(
              child: Container(
                color: buttonBg,
                child: IconButton(
                  icon: Icon(
                    LucideIcons.bell,
                    color: buttonIconColor,
                    size: 22,
                  ),
                  onPressed: () {},
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

String _formatRupiah(double val) {
  final isNegative = val < 0;
  final absVal = val.abs();
  final str = absVal.toStringAsFixed(0);
  final reg = RegExp(r'\B(?=(\d{3})+(?!\d))');
  final formatted = str.replaceAllMapped(reg, (Match m) => '.');
  return '${isNegative ? '-' : ''}Rp $formatted';
}

// --- WIDGET KARTU SALDO ---
class _BalanceCard extends StatelessWidget {
  final double balance;
  final double income;
  final double expense;

  const _BalanceCard({
    required this.balance,
    required this.income,
    required this.expense,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final textColor = isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary;
    final cardTitleColor = isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary;

    return GlassCard(
      borderRadius: 28,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOTAL PENGELUARAN',
                style: TextStyle(
                  color: cardTitleColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.danger.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.danger.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.arrow_down_left,
                      color: AppColors.danger,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Pengeluaran',
                      style: TextStyle(
                        color: AppColors.danger,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _formatRupiah(expense),
            style: spaceGroteskStyle(
              color: textColor,
              fontSize: 34,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// --- WIDGET GRAFIK GELOMBANG CAIR (CUSTOM PAINTER) ---
class _LiquidAnalyticsWave extends StatelessWidget {
  final List<double> weeklyExpenses;
  final double dailyAverage;

  const _LiquidAnalyticsWave({
    required this.weeklyExpenses,
    required this.dailyAverage,
  });

  String _formatRupiah(double val) {
    final str = val.toStringAsFixed(0);
    final reg = RegExp(r'\B(?=(\d{3})+(?!\d))');
    final formatted = str.replaceAllMapped(reg, (Match m) => '.');
    return 'Rp $formatted';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary;
    final subTextColor = isDark ? AppColors.textDarkTertiary : AppColors.textLightTertiary;
    final labelColor = isDark ? AppColors.textDarkTertiary : AppColors.textLightTertiary;

    return GlassCard(
      borderRadius: 24,
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rata-rata Harian',
                      style: TextStyle(color: subTextColor, fontSize: 12),
                    ),
                    Text(
                      _formatRupiah(dailyAverage),
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black).withOpacity(
                      0.06,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Pekan Ini',
                    style: TextStyle(
                      color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Custom Painted Wave Chart
          SizedBox(
            height: 120,
            width: double.infinity,
            child: CustomPaint(
              painter: _WaveChartPainter(
                isDark: isDark,
                expenses: weeklyExpenses,
                primaryColor: Theme.of(context).colorScheme.primary,
                secondaryColor: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Labels Tanggal
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Sen', style: TextStyle(color: labelColor, fontSize: 11)),
                Text('Sel', style: TextStyle(color: labelColor, fontSize: 11)),
                Text('Rab', style: TextStyle(color: labelColor, fontSize: 11)),
                Text('Kam', style: TextStyle(color: labelColor, fontSize: 11)),
                Text('Jum', style: TextStyle(color: labelColor, fontSize: 11)),
                Text('Sab', style: TextStyle(color: labelColor, fontSize: 11)),
                Text('Min', style: TextStyle(color: labelColor, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Painter Gelombang Kustom dengan Gradien Neon Glowing (Data Pengeluaran Aktual)
class _WaveChartPainter extends CustomPainter {
  final bool isDark;
  final List<double> expenses;
  final Color primaryColor;
  final Color secondaryColor;

  _WaveChartPainter({
    required this.isDark,
    required this.expenses,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Definisikan Gradien Pengisian (Fill Gradient)
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          primaryColor.withOpacity(0.35),
          secondaryColor.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    // 2. Definisikan Paint Stroke untuk Garis Atas Gelombang (Glowing Path)
    final strokePaint = Paint()
      ..shader = LinearGradient(
        colors: [primaryColor, secondaryColor],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // 3. Titik Koordinat Gelombang Khas (Skala Pengeluaran Aktual)
    final maxVal = expenses.reduce((a, b) => a > b ? a : b);
    final points = <Offset>[];
    final double stepWidth = size.width / 6;
    for (int i = 0; i < 7; i++) {
      final val = expenses[i];
      final double normalized = maxVal > 0 ? val / maxVal : 0.0;
      // y-coordinate scaled: size.height is bottom, size.height * 0.2 is top
      final double y = size.height - (size.height * 0.15) - (normalized * size.height * 0.65);
      points.add(Offset(i * stepWidth, y));
    }

    // 4. Konstruksi Jalur Gelombang menggunakan Bezier Curves (Smooth Curves)
    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final controlPoint1 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p0.dy);
      final controlPoint2 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p1.dy);
      path.cubicTo(
        controlPoint1.dx,
        controlPoint1.dy,
        controlPoint2.dx,
        controlPoint2.dy,
        p1.dx,
        p1.dy,
      );
    }

    // 5. Gambar Fill Di Bawah Garis
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(fillPath, fillPaint);

    // 6. Gambar Garis Stroke di Atasnya
    canvas.drawPath(path, strokePaint);

    // 7. Tambahkan Efek Titik Puncak Glowing (Highlight)
    final glowPaint = Paint()
      ..color = primaryColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final pointPaint = Paint()
      ..color = isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary
      ..style = PaintingStyle.fill;

    // Gambar titik di puncak pengeluaran tertinggi
    int maxIndex = 0;
    double peakVal = 0.0;
    for (int i = 0; i < 7; i++) {
      if (expenses[i] > peakVal) {
        peakVal = expenses[i];
        maxIndex = i;
      }
    }
    final peakPoint = points[peakVal > 0 ? maxIndex : 3];
    canvas.drawCircle(peakPoint, 10, glowPaint);
    canvas.drawCircle(peakPoint, 4, pointPaint);
  }

  @override
  bool shouldRepaint(covariant _WaveChartPainter oldDelegate) {
    return oldDelegate.expenses != expenses || oldDelegate.isDark != isDark;
  }
}

// --- WIDGET DAFTAR RIWAYAT TRANSAKSI ---
class _RecentTransactionsList extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;

  const _RecentTransactionsList({required this.transactions});

  Map<String, dynamic> _getCategoryStyle(String name) {
    switch (name) {
      case 'F&B':
        return {'icon': LucideIcons.coffee, 'color': AppColors.primaryLight};
      case 'Transport':
        return {'icon': LucideIcons.car, 'color': AppColors.secondary};
      case 'Hiburan':
        return {'icon': LucideIcons.play, 'color': AppColors.tertiaryLight};
      case 'Shopping':
        return {
          'icon': LucideIcons.shopping_bag,
          'color': AppColors.primaryLight,
        };
      case 'Tagihan':
        return {'icon': LucideIcons.receipt, 'color': AppColors.secondary};
      case 'Gaji':
        return {'icon': LucideIcons.banknote, 'color': AppColors.primaryLight};
      default:
        return {'icon': LucideIcons.ellipsis, 'color': AppColors.tertiaryLight};
    }
  }

  String _formatFriendlyDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0 && date.day == now.day) {
        final hour = date.hour.toString().padLeft(2, '0');
        final minute = date.minute.toString().padLeft(2, '0');
        return 'Hari ini, $hour:$minute';
      } else if (difference.inDays <= 1 &&
          date.day == now.subtract(const Duration(days: 1)).day) {
        final hour = date.hour.toString().padLeft(2, '0');
        final minute = date.minute.toString().padLeft(2, '0');
        return 'Kemarin, $hour:$minute';
      } else {
        final day = date.day.toString().padLeft(2, '0');
        final months = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'Mei',
          'Jun',
          'Jul',
          'Agu',
          'Sep',
          'Okt',
          'Nov',
          'Des',
        ];
        final month = months[date.month - 1];
        final year = date.year;
        return '$day $month $year';
      }
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Warna teks dinamis
    final textColor = isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary;
    final deepFadedTextColor = isDark
        ? AppColors.textDarkTertiary
        : AppColors.textLightTertiary;

    if (transactions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Column(
            children: [
              const Icon(LucideIcons.receipt, color: Colors.white24, size: 40),
              const SizedBox(height: 12),
              Text(
                'Belum ada transaksi pada periode ini.',
                style: TextStyle(color: deepFadedTextColor, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    final displayCount = transactions.length > 10 ? 10 : transactions.length;

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: displayCount,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = transactions[index];
        final isExpense = item['is_expense'] == 1;
        final amountVal = item['amount'] as double;
        final categoryName = item['category'] as String;
        final style = _getCategoryStyle(categoryName);
        final iconColor = style['color'] as Color;
        final iconData = style['icon'] as IconData;

        return GlassCard(
          borderRadius: 20,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Glowing Icon Badge
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: iconColor.withOpacity(0.3),
                    width: 1.2,
                  ),
                ),
                child: Icon(iconData, color: iconColor, size: 20),
              ),
              const SizedBox(width: 15),
              // Detail Deskripsi
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ExpandableText(
                      text: item['title'] as String,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Wrap Widget yang 100% Overflow-Proof untuk detail tanggal & sumber dana
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Text(
                          _formatFriendlyDate(item['date'] as String),
                          style: TextStyle(
                            color: deepFadedTextColor,
                            fontSize: 11,
                          ),
                        ),
                        Icon(
                          Icons.fiber_manual_record,
                          size: 4,
                          color: isDark ? Colors.white24 : Colors.black26,
                        ),
                        Text(
                          item['wallet'] as String,
                          style: TextStyle(
                            color: deepFadedTextColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Jumlah Nominal
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isExpense ? "-" : "+"}${_formatRupiah(amountVal)}',
                    style: TextStyle(
                      color: isExpense
                          ? AppColors.danger
                          : AppColors.success,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.white : Colors.black).withOpacity(
                        0.05,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      categoryName,
                      style: TextStyle(
                        color: isDark
                            ? AppColors.textDarkTertiary
                            : AppColors.textLightSecondary,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
