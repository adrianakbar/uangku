import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../widgets/glass_card.dart';

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
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
