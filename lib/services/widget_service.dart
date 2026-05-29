import 'package:home_widget/home_widget.dart';
import 'database_service.dart';
import 'auth_service.dart';

class WidgetService {
  static const String _appGroupId = 'com.example.uangku';
  static const String _androidWidgetName = 'UangkuWidget';
  static const String _androidWidgetSmallName = 'UangkuWidgetSmall';

  final _dbService = DatabaseService();
  final _authService = AuthService();

  // Formatkan angka rupiah tanpa mengimpor Flutter UI
  String _formatRupiah(double val) {
    final isNegative = val < 0;
    final absVal = val.abs();
    final str = absVal.toStringAsFixed(0);
    final reg = RegExp(r'\B(?=(\d{3})+(?!\d))');
    final formatted = str.replaceAllMapped(reg, (m) => '.');
    return '${isNegative ? '-' : ''}Rp $formatted';
  }

  /// Ambil data dari DB dan kirim ke widget Android
  Future<void> updateWidget() async {
    try {
      final email = _authService.currentUser?.email;
      if (email == null) return;

      final now = DateTime.now();

      // Pengeluaran hari ini saja
      final todayStart = DateTime(now.year, now.month, now.day);
      final todaySummary = await _dbService.getSummaryForUserFiltered(
        email,
        startDate: todayStart,
        endDate: now,
      );
      final expenseToday = todaySummary['expense'] ?? 0.0;

      // Pengeluaran minggu ini
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final weekStart = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
      final weekSummary = await _dbService.getSummaryForUserFiltered(
        email,
        startDate: weekStart,
        endDate: now,
      );
      final expenseWeek = weekSummary['expense'] ?? 0.0;

      // Pengeluaran bulan ini
      final monthStart = DateTime(now.year, now.month, 1);
      final monthSummary = await _dbService.getSummaryForUserFiltered(
        email,
        startDate: monthStart,
        endDate: now,
      );
      final expenseMonth = monthSummary['expense'] ?? 0.0;

      // Format waktu update
      final hour = now.hour.toString().padLeft(2, '0');
      final minute = now.minute.toString().padLeft(2, '0');
      final day = now.day.toString().padLeft(2, '0');
      final months = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'];
      final monthStr = months[now.month - 1];
      final lastUpdated = '$day $monthStr, $hour:$minute';

      // Kirim ke SharedPreferences yang bisa dibaca widget native
      await HomeWidget.saveWidgetData<String>('expense_today', _formatRupiah(expenseToday));
      await HomeWidget.saveWidgetData<String>('expense_week', _formatRupiah(expenseWeek));
      await HomeWidget.saveWidgetData<String>('expense_month', _formatRupiah(expenseMonth));
      await HomeWidget.saveWidgetData<String>('last_updated', lastUpdated);

      // Minta sistem Android untuk me-refresh tampilan widget
      await HomeWidget.updateWidget(
        androidName: _androidWidgetName,
      );
      await HomeWidget.updateWidget(
        androidName: _androidWidgetSmallName,
      );
    } catch (_) {
      // Widget update gagal tidak boleh crash aplikasi utama
    }
  }

  /// Bersihkan data widget (misal saat logout untuk privasi)
  Future<void> clearWidget() async {
    try {
      await HomeWidget.saveWidgetData<String>('expense_today', 'Rp –');
      await HomeWidget.saveWidgetData<String>('expense_week', 'Rp –');
      await HomeWidget.saveWidgetData<String>('expense_month', 'Rp –');
      await HomeWidget.saveWidgetData<String>('last_updated', '–');

      await HomeWidget.updateWidget(androidName: _androidWidgetName);
      await HomeWidget.updateWidget(androidName: _androidWidgetSmallName);
    } catch (_) {}
  }

  /// Inisialisasi HomeWidget (panggil dari main())
  static Future<void> init() async {
    try {
      await HomeWidget.setAppGroupId(_appGroupId);
    } catch (_) {}
  }
}
