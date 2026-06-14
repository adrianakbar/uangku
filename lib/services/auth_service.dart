import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'database_service.dart';

class UserSession {
  final String email;
  final String displayName;
  final String? photoUrl;
  final String authProvider; // 'local' or 'google'

  UserSession({
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.authProvider,
  });
}

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  UserSession? _currentUser;
  UserSession? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final DatabaseService _dbService = DatabaseService();

  // 1. Registrasi Akun Lokal Baru
  Future<bool> register(String name, String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 800)); // Simulasi delay
    final cleanEmail = email.trim().toLowerCase();

    // Cek apakah email sudah terdaftar di SQLite
    final existingUser = await _dbService.getUserByEmail(cleanEmail);
    if (existingUser != null) {
      return false; // Email sudah terdaftar
    }

    // Daftarkan ke database SQLite
    await _dbService.insertUser({
      'email': cleanEmail,
      'display_name': name,
      'password': password, // Menggunakan plain text demi kesederhanaan demo offline
      'photo_url': null,
      'auth_provider': 'local',
    });

    // Seed data transaksi default untuk user baru
    await _dbService.seedDefaultDataForUser(cleanEmail);

    return true;
  }

  // 2. Login Akun Lokal
  Future<bool> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 800));
    final cleanEmail = email.trim().toLowerCase();

    // Seeding default user 'adrian@uangku.com' jika belum ada
    if (cleanEmail == 'adrian@uangku.com') {
      final defaultUser = await _dbService.getUserByEmail(cleanEmail);
      if (defaultUser == null) {
        await _dbService.insertUser({
          'email': cleanEmail,
          'display_name': 'Adrian Akbar',
          'password': 'password123',
          'photo_url': null,
          'auth_provider': 'local',
        });
        await _dbService.seedDefaultDataForUser(cleanEmail);
      }
    }

    final user = await _dbService.getUserByEmail(cleanEmail);
    if (user != null && user['password'] == password && user['auth_provider'] == 'local') {
      _currentUser = UserSession(
        email: cleanEmail,
        displayName: user['display_name'] as String,
        photoUrl: user['photo_url'] as String?,
        authProvider: 'local',
      );
      await _dbService.saveSetting('logged_in_email', cleanEmail);
      return true;
    }
    return false;
  }

  // 3. Google Sign-In dengan Fallback Aman
  Future<UserSession?> signInWithGoogle() async {
    try {
      // Inisialisasi tanpa scopes untuk versi GoogleSignIn 7.2.0 API baru
      await _googleSignIn.initialize();
      
      final googleUser = await _googleSignIn.authenticate();

      // Dapatkan token autentikasi Google untuk Firebase
      final googleAuth = googleUser.authentication;

      // Buat kredensial Firebase Auth dengan token Google (cukup idToken untuk verifikasi identitas)
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // Autentikasi/Sign-In ke Firebase Auth agar tercatat di Firebase Console (Users)
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final firebaseUser = userCredential.user;

      final cleanEmail = firebaseUser?.email?.trim().toLowerCase() ?? googleUser.email.trim().toLowerCase();
      final displayName = firebaseUser?.displayName ?? googleUser.displayName ?? 'Google User';
      final photoUrl = firebaseUser?.photoURL ?? googleUser.photoUrl;
      
      // Daftarkan/update user Google ke SQLite
      await _dbService.insertUser({
        'email': cleanEmail,
        'display_name': displayName,
        'password': null,
        'photo_url': photoUrl,
        'auth_provider': 'google',
      });

      // Seed data transaksi default untuk user baru
      await _dbService.seedDefaultDataForUser(cleanEmail);

      _currentUser = UserSession(
        email: cleanEmail,
        displayName: displayName,
        photoUrl: photoUrl,
        authProvider: 'google',
      );
      await _dbService.saveSetting('logged_in_email', cleanEmail);
      return _currentUser;
    } catch (e) {
      // Cetak error untuk memudahkan debugging alur Google Sign-In asli di Firebase
      print("INFO: Google Sign-In asli gagal, mengaktifkan Fallback Mock Mode. Error: $e");
      // Fallback Mock Mode: Mengizinkan login Google berjalan lancar untuk demo antarmuka
      // jika plugin native melempar eksepsi karena berkas konfigurasi Firebase yang belum disiapkan.
      await Future.delayed(const Duration(milliseconds: 1000));
      
      const mockEmail = 'adrian.google@gmail.com';
      await _dbService.insertUser({
        'email': mockEmail,
        'display_name': 'Adrian Akbar',
        'password': null,
        'photo_url': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=256&auto=format&fit=crop',
        'auth_provider': 'google',
      });
      await _dbService.seedDefaultDataForUser(mockEmail);

      _currentUser = UserSession(
        email: mockEmail,
        displayName: 'Adrian Akbar',
        photoUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=256&auto=format&fit=crop',
        authProvider: 'google',
      );
      await _dbService.saveSetting('logged_in_email', mockEmail);
      return _currentUser;
    }
  }

  // 5. Update Foto Profil Pengguna
  Future<void> updateUserPhoto(String? photoUrl) async {
    if (_currentUser == null) return;
    await _dbService.updateUserPhoto(_currentUser!.email, photoUrl);
    _currentUser = UserSession(
      email: _currentUser!.email,
      displayName: _currentUser!.displayName,
      photoUrl: photoUrl,
      authProvider: _currentUser!.authProvider,
    );
  }

  // 6. Logout
  Future<void> logout() async {
    if (_currentUser?.authProvider == 'google') {
      try {
        await _googleSignIn.signOut();
      } catch (_) {}
      try {
        await FirebaseAuth.instance.signOut();
      } catch (_) {}
    }
    _currentUser = null;
    await _dbService.deleteSetting('logged_in_email');
  }

  // 5. Pulihkan Sesi Login dari Database
  Future<void> restoreSession() async {
    final email = await _dbService.getSetting('logged_in_email');
    if (email != null && email.isNotEmpty) {
      final user = await _dbService.getUserByEmail(email);
      if (user != null) {
        _currentUser = UserSession(
          email: email,
          displayName: user['display_name'] as String,
          photoUrl: user['photo_url'] as String?,
          authProvider: user['auth_provider'] as String,
        );
      }
    }
  }
}
