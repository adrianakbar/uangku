import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../widgets/glass_card.dart';
import '../main.dart'; // Akses themeNotifier global

class DashboardScreen extends StatelessWidget {
  final VoidCallback onAddTransactionPressed;

  const DashboardScreen({
    super.key,
    required this.onAddTransactionPressed,
  });

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
          const _BalanceCard(),
          const SizedBox(height: 25),

          // 3. Section Title & Visual Liquid Analytics Wave
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Arus Kas Pekan Ini',
                style: TextStyle(
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
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const Text(
                'Lihat Semua',
                style: TextStyle(
                  color: Color(0xFF8B5CF6), // Purple accent
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          const _RecentTransactionsList(),
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

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            // Glowing Avatar Ring
            Container(
              padding: const EdgeInsets.all(2.5),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF00ADB5),
                    Color(0xFFF355DA),
                  ],
                ),
              ),
              child: const CircleAvatar(
                radius: 22,
                backgroundColor: Color(0xFF0E1122),
                child: Text(
                  'A',
                  style: TextStyle(
                    color: Color(0xFF00ADB5),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Halo, Adrian',
                  style: TextStyle(
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
          ],
        ),
        
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
                  onPressed: () {
                    themeNotifier.value = isDark ? ThemeMode.light : ThemeMode.dark;
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
                  icon: Icon(LucideIcons.bell, color: buttonIconColor, size: 22),
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

// --- WIDGET KARTU SALDO ---
class _BalanceCard extends StatelessWidget {
  const _BalanceCard();

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
                'TOTAL SALDO LOKAL',
                style: TextStyle(
                  color: cardTitleColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
            'Rp 8.450.000',
            style: TextStyle(
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
                            style: TextStyle(
                              color: subTextColor,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'Rp 12.3M',
                            style: TextStyle(
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
                            style: TextStyle(
                              color: subTextColor,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'Rp 3.85M',
                            style: TextStyle(
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black).withOpacity(0.06),
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
            child: CustomPaint(
              painter: _WaveChartPainter(isDark: isDark),
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
        colors: [
          Color(0xFF00ADB5),
          Color(0xFFF355DA),
        ],
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
  const _RecentTransactionsList();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Warna teks dinamis
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final deepFadedTextColor = isDark ? Colors.white38 : const Color(0xFF64748B);

    // Data Mocks Transaksi
    final List<Map<String, dynamic>> items = [
      {
        'title': 'Kopi Cappuccino',
        'category': 'F&B',
        'amount': '-Rp 35.000',
        'isExpense': true,
        'wallet': 'Cash',
        'icon': LucideIcons.coffee,
        'color': const Color(0xFFFFB300), // Amber/Orange
        'date': 'Hari ini, 15:30',
      },
      {
        'title': 'Gaji Pokok Bulanan',
        'category': 'Gaji',
        'amount': '+Rp 7.500.000',
        'isExpense': false,
        'wallet': 'BCA Savings',
        'icon': LucideIcons.banknote,
        'color': const Color(0xFF00E676), // Green
        'date': 'Kemarin, 09:00',
      },
      {
        'title': 'Langganan Netflix Premium Bulanan',
        'category': 'Hiburan',
        'amount': '-Rp 186.000',
        'isExpense': true,
        'wallet': 'Gopay Wallet Utama',
        'icon': LucideIcons.play,
        'color': const Color(0xFFE50914), // Netflix Red
        'date': '22 Mei 2026',
      },
      {
        'title': 'Beli Bahan Makanan',
        'category': 'Groceries',
        'amount': '-Rp 245.000',
        'isExpense': true,
        'wallet': 'Cash',
        'icon': LucideIcons.shopping_bag,
        'color': const Color(0xFF00ADB5), // Turquoise/Cyan
        'date': '20 Mei 2026',
      },
    ];

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        final isExpense = item['isExpense'] as bool;
        final iconColor = item['color'] as Color;

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
                child: Icon(
                  item['icon'] as IconData,
                  color: iconColor,
                  size: 20,
                ),
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
                      overflow: TextOverflow.ellipsis, // Mencegah judul panjang overflow
                    ),
                    const SizedBox(height: 4),
                    // Wrap Widget yang 100% Overflow-Proof untuk detail tanggal & sumber dana
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Text(
                          item['date'] as String,
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
                          overflow: TextOverflow.ellipsis, // Melindungi nama dompet panjang
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
                    item['amount'] as String,
                    style: TextStyle(
                      color: isExpense ? const Color(0xFFFF5252) : const Color(0xFF00E676),
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item['category'] as String,
                      style: TextStyle(
                        color: isDark ? Colors.white54 : const Color(0xFF475569),
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
