import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:uangku/theme/design_system.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/text_style_helper.dart';
import '../widgets/expandable_text.dart';
import '../widgets/add_transaction_sheet.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _dbService = DatabaseService();
  final _authService = AuthService();

  bool _isLoading = true;
  List<Map<String, dynamic>> _allTransactions = [];
  
  // State Filter
  String _searchQuery = '';
  String _selectedCategory = 'Semua';

  final List<String> _categories = [
    'Semua',
    'F&B',
    'Transport',
    'Hiburan',
    'Shopping',
    'Tagihan',
    'Gaji',
    'Lainnya'
  ];

  final Map<String, Map<String, dynamic>> _catStyles = {
    'F&B': {'color': AppColors.secondary, 'icon': LucideIcons.coffee},
    'Transport': {'color': AppColors.secondary, 'icon': LucideIcons.car},
    'Hiburan': {'color': AppColors.secondary, 'icon': LucideIcons.play},
    'Shopping': {'color': AppColors.secondary, 'icon': LucideIcons.shopping_bag},
    'Tagihan': {'color': AppColors.secondary, 'icon': LucideIcons.receipt},
    'Gaji': {'color': AppColors.secondary, 'icon': LucideIcons.arrow_up_right},
    'Lainnya': {'color': AppColors.secondary, 'icon': LucideIcons.ellipsis},
  };

  @override
  void initState() {
    super.initState();
    _loadTransactions();
    DatabaseService.changeNotifier.addListener(_loadTransactions);
  }

  @override
  void dispose() {
    DatabaseService.changeNotifier.removeListener(_loadTransactions);
    super.dispose();
  }

  Future<void> _loadTransactions() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    final email = _authService.currentUser?.email ?? 'adrian@uangku.com';
    final list = await _dbService.getTransactionsForUser(email);

    if (mounted) {
      setState(() {
        _allTransactions = list;
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

  // Filter Transaksi di Memori secara Efisien
  List<Map<String, dynamic>> get _filteredTransactions {
    return _allTransactions.where((tx) {
      // Hanya tampilkan pengeluaran
      if (tx['is_expense'] != 1) return false;

      // 1. Filter Pencarian
      final title = (tx['title'] as String).toLowerCase();
      final notes = (tx['category'] as String).toLowerCase();
      final query = _searchQuery.toLowerCase().trim();
      final matchesSearch = query.isEmpty || title.contains(query) || notes.contains(query);

      // 2. Filter Kategori
      bool matchesCategory = true;
      if (_selectedCategory != 'Semua') {
        matchesCategory = tx['category'] == _selectedCategory;
      }

      return matchesSearch && matchesCategory;
    }).toList();
  }

  // Pengelompokan Transaksi Kronologis O(N)
  Map<String, List<Map<String, dynamic>>> _groupTransactions(List<Map<String, dynamic>> list) {
    final Map<String, List<Map<String, dynamic>>> groups = {};
    for (var tx in list) {
      final dateStr = tx['date'] as String;
      final date = DateTime.tryParse(dateStr) ?? DateTime.now();
      final key = _getDateGroupKey(date);

      if (!groups.containsKey(key)) {
        groups[key] = [];
      }
      groups[key]!.add(tx);
    }
    return groups;
  }

  String _getDateGroupKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final txDate = DateTime(date.year, date.month, date.day);

    if (txDate == today) {
      return 'Hari Ini';
    } else if (txDate == yesterday) {
      return 'Kemarin';
    } else {
      final months = [
        'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
        'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    }
  }

  void _showEditTransactionForm(Map<String, dynamic> tx) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddTransactionSheet(
        transaction: tx,
        onTransactionSaved: _loadTransactions,
      ),
    );
  }

  void _confirmDeleteTransaction(int id, String title, double amount, bool isExpense) {
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
        final subTextColor = isDark ? Colors.white60 : const Color(0xFF475569);

        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AlertDialog(
            backgroundColor: isDark ? const Color(0xFF0E1122).withOpacity(0.85) : Colors.white.withOpacity(0.9),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(
                color: isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.08),
                width: 1.5,
              ),
            ),
            title: Row(
              children: [
                const Icon(LucideIcons.triangle_alert, color: Color(0xFFFF5252), size: 24),
                const SizedBox(width: 10),
                Text(
                  'Hapus Transaksi?',
                  style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            content: Text(
              'Apakah Anda yakin ingin menghapus catatan "$title" sebesar ${_formatRupiah(amount)}? Tindakan ini permanen.',
              style: TextStyle(color: subTextColor, fontSize: 14, height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Batal', style: TextStyle(color: subTextColor, fontWeight: FontWeight.bold)),
              ),
              ElevatedButton(
                onPressed: () async {
                  await _dbService.deleteTransaction(id);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Catatan transaksi berhasil dihapus.')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5252),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Hapus', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subTextColor = isDark ? Colors.white60 : const Color(0xFF475569);
    final textInputColor = isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03);
    final textInputBorderColor = isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.08);

    final filtered = _filteredTransactions;
    final grouped = _groupTransactions(filtered);

    // Hitung ringkasan dinamis dari list hasil filter saat ini
    double currentExpense = 0;
    for (var tx in filtered) {
      final amount = tx['amount'] as double;
      if (tx['is_expense'] == 1) {
        currentExpense += amount;
      }
    }

    // Build the flat list for lazy loading in CustomScrollView / SliverList
    final List<dynamic> flatList = [];
    grouped.forEach((dateKey, list) {
      flatList.add(dateKey); // string represents the header
      flatList.addAll(list); // maps represent transactions
    });

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // 1. Header Halaman
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
            child: Text(
              'Riwayat Keuangan',
              style: plusJakartaStyle(
                color: textColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),

        // 2. Summary Card Dinamis & Bercahaya
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GlassCard(
              borderRadius: 24,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF5252).withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.arrow_up_right, color: Color(0xFFFF5252), size: 16),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'TOTAL PENGELUARAN',
                        style: TextStyle(color: subTextColor, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _formatRupiah(currentExpense),
                    style: spaceGroteskStyle(
                      color: const Color(0xFFFF5252),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // 3. Search Bar Glassmorphic
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            child: Container(
              decoration: BoxDecoration(
                color: textInputColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: textInputBorderColor),
              ),
              child: TextField(
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
                style: TextStyle(color: textColor, fontSize: 14),
                decoration: InputDecoration(
                  prefixIcon: Icon(LucideIcons.search, color: subTextColor, size: 20),
                  hintText: 'Cari catatan riwayat...',
                  hintStyle: TextStyle(color: subTextColor.withOpacity(0.5), fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                ),
              ),
            ),
          ),
        ),

        // 4. Baris Filter Kategori
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: textInputColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: textInputBorderColor),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.filter_list_rounded, color: subTextColor, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Filter Kategori',
                        style: TextStyle(
                          color: subTextColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCategory,
                      dropdownColor: isDark ? const Color(0xFF0F1223) : Colors.white,
                      icon: Icon(Icons.arrow_drop_down, color: textColor, size: 20),
                      style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.bold),
                      onChanged: (String? val) {
                        if (val != null) {
                          setState(() {
                            _selectedCategory = val;
                          });
                        }
                      },
                      items: _categories.map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(
          child: SizedBox(height: 24),
        ),

        // 5. Daftar Transaksi Terkelompok atau Empty State
        if (_isLoading)
          SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 50),
                child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
              ),
            ),
          )
        else if (filtered.isEmpty)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverToBoxAdapter(
              child: GlassCard(
                borderRadius: 24,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                child: Column(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
                      ),
                      child: Icon(LucideIcons.search_x, color: Theme.of(context).colorScheme.primary, size: 30),
                    ),
                    const SizedBox(height: 20),
                    Text('Transaksi Tidak Ditemukan', style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      _allTransactions.isEmpty
                          ? 'Anda belum memiliki riwayat transaksi offline. Mulailah mencatat keuangan Anda sekarang!'
                          : 'Tidak ada riwayat transaksi yang cocok dengan filter pencarian dan kategori Anda.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: subTextColor, fontSize: 12, height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = flatList[index];

                  if (item is String) {
                    // Sticky / Date Header untuk Grup Tanggal
                    return Padding(
                      padding: const EdgeInsets.only(left: 4, top: 12, bottom: 8),
                      child: Text(
                        item.toUpperCase(),
                        style: TextStyle(
                          color: subTextColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    );
                  } else {
                    // Catatan Transaksi Card
                    final tx = item as Map<String, dynamic>;
                    final id = tx['id'] as int;
                    final title = tx['title'] as String;
                    final category = tx['category'] as String;
                    final wallet = tx['wallet'] as String;
                    final amount = tx['amount'] as double;
                    final isExpense = tx['is_expense'] == 1;

                    // Peroleh style visual kategori
                    final style = _catStyles[category] ?? _catStyles['Lainnya']!;
                    final icon = style['icon'] as IconData;
                    final baseColor = style['color'] as Color;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GestureDetector(
                        onTap: () => _showEditTransactionForm(tx),
                        child: GlassCard(
                          borderRadius: 20,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              // Bulatan Kategori Icon
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: baseColor.withOpacity(0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(icon, color: baseColor, size: 20),
                              ),
                              const SizedBox(width: 14),
                              
                              // Judul dan Dompet Pembayar
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ExpandableText(
                                      text: title,
                                      style: TextStyle(
                                        color: textColor,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$category • $wallet',
                                      style: TextStyle(
                                        color: subTextColor,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
  
                              // Nilai Nominal & Tombol Hapus Tempat Sampah
                              Row(
                                children: [
                                  Text(
                                    '- ${_formatRupiah(amount)}',
                                    style: spaceGroteskStyle(
                                      color: const Color(0xFFFF5252),
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: const Icon(LucideIcons.trash_2, color: Colors.redAccent, size: 16),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () => _confirmDeleteTransaction(id, title, amount, isExpense),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                },
                childCount: flatList.length,
              ),
            ),
          ),
        
        // Memberi ruang aman untuk floating bottom navigation bar
        const SliverToBoxAdapter(
          child: SizedBox(height: 120),
        ),
      ],
    );
  }
}
