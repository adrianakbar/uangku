import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/glass_card.dart';
import '../widgets/text_style_helper.dart';
import '../main.dart'; // Akses themeNotifier global
import '../services/database_service.dart';
import '../services/auth_service.dart';

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

    // Pastikan database terisi data awal demo jika baru terdaftar
    await _dbService.seedDefaultDataForUser(email);

    final summary = await _dbService.getSummaryForUser(email);
    final txs = await _dbService.getTransactionsForUser(email);

    if (mounted) {
      setState(() {
        _balance = summary['balance'] ?? 0.0;
        _income = summary['income'] ?? 0.0;
        _expense = summary['expense'] ?? 0.0;
        _transactions = txs;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Warna teks dinamis
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);

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
              ? const SizedBox(
                  height: 180,
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFF00ADB5)),
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
                'Arus Kas Pekan Ini',
                style: plusJakartaStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const Icon(
                LucideIcons.trending_up,
                color: Color(0xFF00ADB5),
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 15),
          const _LiquidAnalyticsWave(),
          const SizedBox(height: 25),

          // 4. Riwayat Transaksi Terbaru
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Transaksi Terbaru',
                style: plusJakartaStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const Icon(
                LucideIcons.circle_dollar_sign,
                color: Color(0xFF00ADB5),
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 15),
          _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF00ADB5)),
                )
              : _RecentTransactionsList(transactions: _transactions),
          const SizedBox(height: 100), // Spasi agar tidak tertutup Bottom Bar
        ],
      ),
    );
  }
}

// --- WIDGET HEADER ---
class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subTextColor = isDark ? Colors.white54 : const Color(0xFF475569);
    final buttonBg = (isDark ? Colors.white : Colors.black).withOpacity(0.06);
    final buttonIconColor = isDark ? Colors.white : const Color(0xFF1E293B);

    final user = AuthService().currentUser;
    final displayName = user?.displayName ?? 'Adrian';
    final firstLetter = displayName.isNotEmpty
        ? displayName.substring(0, 1).toUpperCase()
        : 'A';
    final photoUrl = user?.photoUrl;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              // Glowing Avatar Ring
              Container(
                padding: const EdgeInsets.all(2.5),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF00ADB5), Color(0xFFF355DA)],
                  ),
                ),
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xFF0E1122),
                  backgroundImage: photoUrl != null
                      ? NetworkImage(photoUrl)
                      : null,
                  child: photoUrl == null
                      ? Text(
                          firstLetter,
                          style: const TextStyle(
                            color: Color(0xFF00ADB5),
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Kelola uangmu dengan bijak!',
                      style: TextStyle(
                        color: subTextColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
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

    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final cardTitleColor = isDark ? Colors.white70 : const Color(0xFF475569);
    final subTextColor = isDark ? Colors.white54 : const Color(0xFF64748B);

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
                'TOTAL SALDO',
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
                  color: const Color(0xFF00ADB5).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF00ADB5).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      LucideIcons.shield_check,
                      color: Color(0xFF00ADB5),
                      size: 14,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Offline',
                      style: TextStyle(
                        color: Color(0xFF00ADB5),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _formatRupiah(balance),
            style: spaceGroteskStyle(
              color: textColor,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 24),
          Divider(color: isDark ? Colors.white12 : Colors.black12, height: 1),
          const SizedBox(height: 20),
          Row(
            children: [
              // Ringkasan Pemasukan
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E676).withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF00E676).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        LucideIcons.arrow_up_right,
                        color: Color(0xFF00E676),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pemasukan',
                            style: TextStyle(color: subTextColor, fontSize: 12),
                          ),
                          Text(
                            _formatRupiah(income),
                            style: spaceGroteskStyle(
                              color: textColor,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Divider Vertikal
              Container(
                height: 35,
                width: 1,
                color: isDark ? Colors.white12 : Colors.black12,
              ),
              const SizedBox(width: 10),
              // Ringkasan Pengeluaran
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF3D00).withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFFF3D00).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        LucideIcons.arrow_down_left,
                        color: Color(0xFFFF3D00),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pengeluaran',
                            style: TextStyle(color: subTextColor, fontSize: 12),
                          ),
                          Text(
                            _formatRupiah(expense),
                            style: spaceGroteskStyle(
                              color: textColor,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- WIDGET GRAFIK GELOMBANG CAIR (CUSTOM PAINTER) ---
class _LiquidAnalyticsWave extends StatelessWidget {
  const _LiquidAnalyticsWave();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subTextColor = isDark ? Colors.white54 : const Color(0xFF64748B);
    final labelColor = isDark ? Colors.white38 : const Color(0xFF94A3B8);

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
                      'Rp 550.000',
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
                    '7 Hari Terakhir',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : const Color(0xFF334155),
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
            child: CustomPaint(painter: _WaveChartPainter(isDark: isDark)),
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

// Painter Gelombang Kustom dengan Gradien Neon Glowing
class _WaveChartPainter extends CustomPainter {
  final bool isDark;

  _WaveChartPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Definisikan Gradien Pengisian (Fill Gradient)
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF00ADB5).withOpacity(0.35),
          const Color(0xFF7000FF).withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    // 2. Definisikan Paint Stroke untuk Garis Atas Gelombang (Glowing Path)
    final strokePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF00ADB5), Color(0xFFF355DA)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // 3. Titik Koordinat Gelombang Khas (Representasi Pengeluaran)
    final points = [
      Offset(0, size.height * 0.7),
      Offset(size.width * 0.16, size.height * 0.4),
      Offset(size.width * 0.33, size.height * 0.8),
      Offset(size.width * 0.5, size.height * 0.25), // puncak
      Offset(size.width * 0.66, size.height * 0.6),
      Offset(size.width * 0.83, size.height * 0.35),
      Offset(size.width, size.height * 0.55),
    ];

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
      ..color = const Color(0xFF00ADB5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final pointPaint = Paint()
      ..color = isDark ? Colors.white : const Color(0xFF1E293B)
      ..style = PaintingStyle.fill;

    // Gambar titik di puncak tertinggi (Hari Kamis, index 3)
    final peakPoint = points[3];
    canvas.drawCircle(peakPoint, 10, glowPaint);
    canvas.drawCircle(peakPoint, 4, pointPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// --- WIDGET DAFTAR RIWAYAT TRANSAKSI ---
class _RecentTransactionsList extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;

  const _RecentTransactionsList({required this.transactions});

  Map<String, dynamic> _getCategoryStyle(String name) {
    switch (name) {
      case 'F&B':
        return {'icon': LucideIcons.coffee, 'color': const Color(0xFFFFB300)};
      case 'Transport':
        return {'icon': LucideIcons.car, 'color': const Color(0xFF00E676)};
      case 'Hiburan':
        return {'icon': LucideIcons.play, 'color': const Color(0xFFE50914)};
      case 'Shopping':
        return {
          'icon': LucideIcons.shopping_bag,
          'color': const Color(0xFF00F2FE),
        };
      case 'Tagihan':
        return {'icon': LucideIcons.receipt, 'color': const Color(0xFFFF5252)};
      case 'Gaji':
        return {'icon': LucideIcons.banknote, 'color': const Color(0xFF00E676)};
      default:
        return {'icon': LucideIcons.ellipsis, 'color': const Color(0xFFA5B4FC)};
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
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final deepFadedTextColor = isDark
        ? Colors.white38
        : const Color(0xFF64748B);

    if (transactions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Column(
            children: [
              const Icon(LucideIcons.receipt, color: Colors.white24, size: 40),
              const SizedBox(height: 12),
              Text(
                'Belum ada transaksi.',
                style: TextStyle(color: deepFadedTextColor, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transactions.length,
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
                    Text(
                      item['title'] as String,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow
                          .ellipsis, // Mencegah judul panjang overflow
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
                          maxLines: 1,
                          overflow: TextOverflow
                              .ellipsis, // Melindungi nama dompet panjang
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
                          ? const Color(0xFFFF5252)
                          : const Color(0xFF00E676),
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
                            ? Colors.white54
                            : const Color(0xFF475569),
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
