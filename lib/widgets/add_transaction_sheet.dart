import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class AddTransactionSheet extends StatefulWidget {
  const AddTransactionSheet({super.key});

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  bool _isExpense = true;
  String _selectedCategory = 'F&B';
  String _selectedWallet = 'Cash';
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  final List<Map<String, dynamic>> _categories = [
    {'name': 'F&B', 'icon': LucideIcons.coffee, 'color': const Color(0xFFFFB300)},
    {'name': 'Transport', 'icon': LucideIcons.car, 'color': const Color(0xFF00E676)},
    {'name': 'Hiburan', 'icon': LucideIcons.play, 'color': const Color(0xFFE50914)},
    {'name': 'Shopping', 'icon': LucideIcons.shopping_bag, 'color': const Color(0xFF00F2FE)},
    {'name': 'Tagihan', 'icon': LucideIcons.receipt, 'color': const Color(0xFFFF5252)},
    {'name': 'Lainnya', 'icon': LucideIcons.ellipsis, 'color': const Color(0xFFA5B4FC)},
  ];

  final List<String> _wallets = ['Cash', 'BCA Savings', 'Gopay Wallet'];

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
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subTextColor = isDark ? Colors.white60 : const Color(0xFF475569);
    final fadedTextColor = isDark ? Colors.white38 : const Color(0xFF64748B);
    final inputBgColor = isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03);
    final inputBorderColor = isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.08);

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
      child: Container(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 10,
          bottom: 24 + bottomInset, // Antisipasi keyboard
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
                    'Tambah Transaksi',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  // Sliding Pill Switcher
                  Container(
                    height: 38,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        _buildTypeButton('Pengeluaran', true, isDark),
                        _buildTypeButton('Pemasukan', false, isDark),
                      ],
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
                  style: TextStyle(
                    color: textColor,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      LucideIcons.wallet,
                      color: Color(0xFF00ADB5),
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
                            ? iconColor.withOpacity(0.18)
                            : inputBgColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? iconColor.withOpacity(0.6)
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

              // 5. Dompet & Catatan Bar
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
                              dropdownColor: isDark ? const Color(0xFF0F1223) : Colors.white,
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
                onTap: () {
                  Navigator.pop(context);
                },
                child: Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF00ADB5),
                        Color(0xFF7000FF),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00ADB5).withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.check, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Simpan Transaksi',
                        style: TextStyle(
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
    );
  }

  Widget _buildTypeButton(String label, bool isExpenseButton, bool isDark) {
    final isSelected = _isExpense == isExpenseButton;
    return GestureDetector(
      onTap: () {
        setState(() {
          _isExpense = isExpenseButton;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isExpenseButton ? const Color(0xFFFF5252).withOpacity(0.18) : const Color(0xFF00E676).withOpacity(0.18))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? (isExpenseButton ? const Color(0xFFFF5252).withOpacity(0.3) : const Color(0xFF00E676).withOpacity(0.3))
                : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? (isExpenseButton ? const Color(0xFFFF5252) : const Color(0xFF00E676))
                : (isDark ? Colors.white38 : Colors.black45),
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
