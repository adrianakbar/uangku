import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/text_style_helper.dart';
import '../theme/design_system.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final _dbService = DatabaseService();
  final _authService = AuthService();

  bool _isLoading = true;
  double _income = 0.0;
  double _expense = 0.0;
  Map<String, double> _categoryExpenses = {};

  final Map<String, Map<String, dynamic>> _catStyles = {
    'F&B': {'color': AppColors.primaryLight, 'icon': LucideIcons.coffee},
    'Transport': {'color': AppColors.secondary, 'icon': LucideIcons.car},
    'Hiburan': {'color': AppColors.tertiaryLight, 'icon': LucideIcons.play},
    'Shopping': {'color': AppColors.primaryLight, 'icon': LucideIcons.shopping_bag},
    'Tagihan': {'color': AppColors.secondary, 'icon': LucideIcons.receipt},
    'Olahraga': {'color': AppColors.tertiaryLight, 'icon': LucideIcons.dumbbell},
    'Kesehatan': {'color': const Color(0xFFE57373), 'icon': LucideIcons.heart},
    'Edukasi': {'color': const Color(0xFF64B5F6), 'icon': LucideIcons.graduation_cap},
    'Top Up': {'color': const Color(0xFF81C784), 'icon': LucideIcons.wallet_cards},
    'Sosial': {'color': const Color(0xFFFFB74D), 'icon': LucideIcons.users},
    'Jasa': {'color': const Color(0xFFBA68C8), 'icon': LucideIcons.wrench},
    'Lainnya': {'color': AppColors.tertiaryLight, 'icon': LucideIcons.ellipsis},
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
    final textColor = isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary;
    final subTextColor = isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary;

    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
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
            style: plusJakartaStyle(
              color: textColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 20),

          // 1. Ringkasan Analisis Pengeluaran Card
          GlassCard(
            borderRadius: 24,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('RINGKASAN ANALISIS PENGELUARAN', style: TextStyle(color: subTextColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    Icon(LucideIcons.chart_pie, color: Theme.of(context).colorScheme.primary, size: 16),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Pengeluaran', style: TextStyle(color: Colors.redAccent, fontSize: 11)),
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(_formatRupiah(_expense), style: spaceGroteskStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
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
                          Text('Kategori Pengeluaran', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 11)),
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text('${activeCategories.length}', style: spaceGroteskStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ],
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
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
                    ),
                    child: Icon(LucideIcons.chart_pie, color: Theme.of(context).colorScheme.primary, size: 30),
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
                      painter: DonutChartPainter(
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
                  blur: 0,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                              border: Border.all(color: color.withValues(alpha: 0.3)),
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
                          Text(_formatRupiah(amount), style: spaceGroteskStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Progress Bar Kategori
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: percent,
                          backgroundColor: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
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
class DonutChartPainter extends CustomPainter {
  final Map<String, double> categoryExpenses;
  final Map<String, Map<String, dynamic>> styles;

  DonutChartPainter({required this.categoryExpenses, required this.styles});

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
