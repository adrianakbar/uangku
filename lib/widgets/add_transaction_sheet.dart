import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../theme/design_system.dart';

class AddTransactionSheet extends StatefulWidget {
  final VoidCallback? onTransactionSaved;
  final Map<String, dynamic>? transaction;

  const AddTransactionSheet({super.key, this.onTransactionSaved, this.transaction});

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  final bool _isExpense = true;
  String _selectedCategory = 'F&B';
  String _selectedWallet = 'Cash';
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    final month = months[date.month - 1];
    final year = date.year;
    
    final daysOfWeek = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    final dayOfWeek = daysOfWeek[date.weekday - 1];
    
    return '$dayOfWeek, $day $month $year';
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
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
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  String _formatAmount(String val) {
    final clean = val.replaceAll(RegExp(r'\D'), '');
    final reg = RegExp(r'\B(?=(\d{3})+(?!\d))');
    return clean.replaceAllMapped(reg, (Match m) => '.');
  }

  @override
  void initState() {
    super.initState();
    if (widget.transaction != null) {
      final tx = widget.transaction!;
      final amount = tx['amount'];
      if (amount is double) {
        _amountController.text = _formatAmount(amount.toStringAsFixed(0));
      } else if (amount != null) {
        _amountController.text = _formatAmount(amount.toString());
      }

      final title = tx['title'] as String? ?? '';
      final category = tx['category'] as String? ?? 'F&B';
      if (title == 'Pengeluaran $category') {
        _noteController.text = '';
      } else {
        _noteController.text = title;
      }

      final hasCategory = _categories.any((c) => c['name'] == category);
      _selectedCategory = hasCategory ? category : 'Lainnya';
      _selectedWallet = tx['wallet'] as String? ?? 'Cash';

      final dateStr = tx['date'] as String?;
      if (dateStr != null) {
        _selectedDate = DateTime.tryParse(dateStr) ?? DateTime.now();
      }
    }
  }

  final List<Map<String, dynamic>> _categories = [
    {'name': 'F&B', 'icon': LucideIcons.coffee, 'color': AppColors.primaryLight},
    {'name': 'Transport', 'icon': LucideIcons.car, 'color': AppColors.secondary},
    {'name': 'Hiburan', 'icon': LucideIcons.play, 'color': AppColors.primaryLight},
    {'name': 'Shopping', 'icon': LucideIcons.shopping_bag, 'color': AppColors.secondary},
    {'name': 'Tagihan', 'icon': LucideIcons.receipt, 'color': AppColors.primaryLight},
    {'name': 'Olahraga', 'icon': LucideIcons.dumbbell, 'color': AppColors.secondary},
    {'name': 'Kesehatan', 'icon': LucideIcons.heart, 'color': AppColors.primaryLight},
    {'name': 'Edukasi', 'icon': LucideIcons.graduation_cap, 'color': AppColors.secondary},
    {'name': 'Top Up', 'icon': LucideIcons.wallet_cards, 'color': AppColors.primaryLight},
    {'name': 'Sosial', 'icon': LucideIcons.users, 'color': AppColors.secondary},
    {'name': 'Jasa', 'icon': LucideIcons.wrench, 'color': AppColors.primaryLight},
    {'name': 'Lainnya', 'icon': LucideIcons.ellipsis, 'color': AppColors.secondary},
  ];

  final List<String> _wallets = [
    'Cash',
    'BCA Savings',
    'Bank Mandiri',
    'Gopay Wallet',
    'Shopeepay',
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Sistem Desain Warna Dinamis Terang/Gelap
    final textColor = isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary;
    final subTextColor = isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary;
    final fadedTextColor = isDark ? AppColors.textDarkTertiary : AppColors.textLightTertiary;
    final inputBgColor = isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03);
    final inputBorderColor = isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.08);

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: bottomInset > 0
                ? (MediaQuery.of(context).size.height - bottomInset - 16)
                : (MediaQuery.of(context).size.height * 0.85),
          ),
          padding: const EdgeInsets.only(
            left: 24,
            right: 24,
            top: 10,
            bottom: 24,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppColors.bgDark.withValues(alpha: 0.85) : AppColors.bgLight.withValues(alpha: 0.92),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
            border: Border(
              top: BorderSide(
                color: isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.08),
                width: 1.5,
              ),
            ),
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Drag Handle Indikator
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

                // 2. Title & Switcher Tipe Transaksi
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.transaction != null ? 'EDIT PENGELUARAN' : 'TAMBAH PENGELUARAN',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),

                // 3. Input Jumlah Uang (Amount)
                Text(
                  'JUMLAH (RP)',
                  style: TextStyle(
                    color: subTextColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: inputBgColor,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: inputBorderColor,
                    ),
                  ),
                  child: TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      IndonesianCurrencyInputFormatter(),
                    ],
                    style: TextStyle(
                      color: textColor,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                        LucideIcons.wallet,
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      ),
                      prefixIconConstraints: const BoxConstraints(
                        minWidth: 50,
                      ),
                      hintText: '0',
                      hintStyle: TextStyle(color: fadedTextColor),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 4. Grid Kategori dengan Ikon Lucide
                Text(
                  'PILIH KATEGORI',
                  style: TextStyle(
                    color: subTextColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.35,
                  ),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isSelected = _selectedCategory == cat['name'];
                    final iconColor = cat['color'] as Color;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCategory = cat['name'] as String;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? iconColor.withValues(alpha: 0.18)
                              : inputBgColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? iconColor.withValues(alpha: 0.6)
                                : inputBorderColor,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              cat['icon'] as IconData,
                              color: isSelected ? iconColor : subTextColor,
                              size: 20,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              cat['name'] as String,
                              style: TextStyle(
                                color: isSelected ? textColor : subTextColor,
                                fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // 5. Pilihan Tanggal Transaksi
                Text(
                  'TANGGAL TRANSAKSI',
                  style: TextStyle(
                    color: subTextColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _selectDate(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: inputBgColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: inputBorderColor,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              LucideIcons.calendar,
                              color: Theme.of(context).colorScheme.primary,
                              size: 18,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _formatDate(_selectedDate),
                              style: TextStyle(
                                color: textColor,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Icon(
                          LucideIcons.chevron_down,
                          color: subTextColor,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 6. Dompet & Catatan Bar
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pilihan Dompet (Wallet)
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SUMBER DANA',
                            style: TextStyle(
                              color: subTextColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: inputBgColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: inputBorderColor,
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedWallet,
                                isExpanded: true,
                                dropdownColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                                icon: Icon(Icons.arrow_drop_down, color: subTextColor),
                                style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.bold),
                                onChanged: (String? newValue) {
                                  if (newValue != null) {
                                    setState(() {
                                      _selectedWallet = newValue;
                                    });
                                  }
                                },
                                items: _wallets.map<DropdownMenuItem<String>>((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Catatan Singkat (Notes)
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CATATAN',
                            style: TextStyle(
                              color: subTextColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: inputBgColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: inputBorderColor,
                              ),
                            ),
                            child: TextField(
                              controller: _noteController,
                              style: TextStyle(color: textColor, fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Keperluan belanja...',
                                hintStyle: TextStyle(color: fadedTextColor, fontSize: 13),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // 6. Glowing Neon Save Button
                GestureDetector(
                  onTap: () async {
                    final amountText = _amountController.text.trim();
                    if (amountText.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Silakan masukkan jumlah nominal!')),
                      );
                      return;
                    }

                    final parsedAmount = double.tryParse(amountText.replaceAll('.', '')) ?? 0.0;
                    if (parsedAmount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Nominal harus lebih besar dari 0!')),
                      );
                      return;
                    }

                    final title = _noteController.text.trim().isEmpty
                        ? (_isExpense ? 'Pengeluaran $_selectedCategory' : 'Pemasukan $_selectedCategory')
                        : _noteController.text.trim();

                    final userEmail = AuthService().currentUser?.email ?? 'adrian@uangku.com';

                    if (widget.transaction != null) {
                      final originalId = widget.transaction!['id'] as int;
                      final originalDateStr = widget.transaction!['date'] as String;
                      final originalDate = DateTime.tryParse(originalDateStr) ?? DateTime.now();
                      final finalDate = DateTime(
                        _selectedDate.year,
                        _selectedDate.month,
                        _selectedDate.day,
                        originalDate.hour,
                        originalDate.minute,
                        originalDate.second,
                      );

                      await DatabaseService().updateTransaction(originalId, {
                        'title': title,
                        'category': _selectedCategory,
                        'amount': parsedAmount,
                        'is_expense': _isExpense ? 1 : 0,
                        'wallet': _selectedWallet,
                        'date': finalDate.toIso8601String(),
                        'user_email': userEmail,
                      });
                    } else {
                      final now = DateTime.now();
                      final finalDate = DateTime(
                        _selectedDate.year,
                        _selectedDate.month,
                        _selectedDate.day,
                        now.hour,
                        now.minute,
                        now.second,
                      );

                      await DatabaseService().insertTransaction({
                        'title': title,
                        'category': _selectedCategory,
                        'amount': parsedAmount,
                        'is_expense': _isExpense ? 1 : 0,
                        'wallet': _selectedWallet,
                        'date': finalDate.toIso8601String(),
                        'user_email': userEmail,
                      });
                    }

                    widget.onTransactionSaved?.call();
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.secondary,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.check, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          widget.transaction != null ? 'Simpan Perubahan' : 'Simpan Transaksi',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
  }
}

class IndonesianCurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final cleanText = newValue.text.replaceAll(RegExp(r'\D'), '');
    final reg = RegExp(r'\B(?=(\d{3})+(?!\d))');
    final formattedText = cleanText.replaceAllMapped(reg, (Match m) => '.');

    int cursorPosition = newValue.selection.end;
    int digitsBeforeCursor = newValue.text.substring(0, cursorPosition).replaceAll(RegExp(r'\D'), '').length;
    
    int newCursorPosition = 0;
    int digitCount = 0;
    while (newCursorPosition < formattedText.length && digitCount < digitsBeforeCursor) {
      if (formattedText[newCursorPosition] != '.') {
        digitCount++;
      }
      newCursorPosition++;
    }

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: newCursorPosition),
    );
  }
}
