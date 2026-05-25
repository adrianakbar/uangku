import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  // 1. Inisialisasi Layanan Notifikasi Lokal
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // Inisialisasi zona waktu untuk penjedwalan notifikasi harian
      tz.initializeTimeZones();

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          // Logika saat notifikasi diklik (opsional)
        },
      );
      _isInitialized = true;
    } catch (_) {
      // Abaikan jika tidak didukung (misal running di desktop Linux/Windows)
      _isInitialized = false;
    }
  }

  // 2. Kirim Notifikasi Instan (Trigger saat Transaksi Disimpan)
  Future<void> showInstantNotification({required String title, required String body}) async {
    await init();
    if (!_isInitialized) return;

    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'uangku_transactions',
        'Transaksi Uangku',
        channelDescription: 'Notifikasi pencatatan transaksi masuk dan keluar',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'ticker',
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notificationsPlugin.show(
        DateTime.now().millisecond, // ID unik berdasarkan waktu
        title,
        body,
        platformDetails,
      );
    } catch (_) {
      // Gagal memicu notifikasi native
    }
  }

  // 3. Jadwalkan Notifikasi Pengingat Harian (Pukul 20:00)
  Future<void> scheduleDailyReminder(bool active) async {
    await init();
    if (!_isInitialized) return;

    try {
      // Batalkan notifikasi harian lama jika ada
      await _notificationsPlugin.cancel(888);

      if (!active) return; // Jika setelan dinonaktifkan

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'uangku_daily_reminder',
        'Pengingat Harian',
        channelDescription: 'Mengingatkan pencatatan pengeluaran harian',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(),
      );

      // Set waktu notifikasi setiap hari jam 20:00 (8 Malam)
      final tz.TZDateTime scheduledTime = _nextInstanceOfEightPM();

      await _notificationsPlugin.zonedSchedule(
        888,
        'Catatan Pengeluaran Hari Ini 📝',
        'Sudahkah kamu mencatat pengeluaran atau pemasukan hari ini? Yuk luangkan waktu 1 menit!',
        scheduledTime,
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // Berulang setiap hari
      );
    } catch (_) {
      // Gagal menjadwalkan notifikasi
    }
  }

  tz.TZDateTime _nextInstanceOfEightPM() {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, 20, 0);
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
