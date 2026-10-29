import 'package:flutter/foundation.dart';

import '../data/models/user_model.dart';
import '../data/repositories/repository_exception.dart';
import '../data/repositories/session_repository.dart';
import '../data/repositories/user_repository.dart';
import 'safe_change_notifier.dart';

/// Tingkat kekuatan password untuk indikator di formulir registrasi.
enum PasswordStrength { empty, weak, fair, good, strong }

/// Logika masuk, daftar, keluar, dan pengecekan sesi (UC-01).
/// Juga menjadi sumber status login bagi Auth Guard pada GoRouter.
class AuthViewModel extends ChangeNotifier with SafeChangeNotifier {
  AuthViewModel({
    required UserRepository userRepository,
    required SessionRepository sessionRepository,
    DateTime Function()? clock,
  })  : _userRepository = userRepository,
        _sessionRepository = sessionRepository,
        _clock = clock ?? DateTime.now;

  final UserRepository _userRepository;
  final SessionRepository _sessionRepository;
  final DateTime Function() _clock;

  /// Percobaan login gagal beruntun sebelum akun dikunci sementara.
  static const int maxFailedAttempts = 5;
  static const Duration lockDuration = Duration(seconds: 30);

  UserModel? _currentUser;
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _infoMessage;
  int _failedAttempts = 0;
  DateTime? _lockedUntil;

  static const String _genericError = 'Terjadi kesalahan. Silakan coba lagi.';

  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  /// True setelah [checkSession] selesai dijalankan.
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get infoMessage => _infoMessage;

  /// Sisa detik penguncian login (0 bila tidak terkunci).
  int get lockSecondsRemaining {
    final DateTime? until = _lockedUntil;
    if (until == null) return 0;
    final int ms = until.difference(_clock()).inMilliseconds;
    return ms > 0 ? (ms / 1000).ceil() : 0;
  }

  // ---------------------------------------------------------- validator form

  static final RegExp _nameChars =
      RegExp(r"^[A-Za-z\u00C0-\u024F][A-Za-z\u00C0-\u024F .'\-]*$");
  static final RegExp _emailPattern = RegExp(
    r'^[A-Za-z0-9._%+\-]+@[A-Za-z0-9\-]+(?:\.[A-Za-z0-9\-]+)*\.[A-Za-z]{2,}$',
  );

  static String? validateName(String? value) {
    final String text = (value ?? '').trim().replaceAll(RegExp(r'\s+'), ' ');
    if (text.isEmpty) return 'Nama wajib diisi';
    if (text.length < 2) return 'Nama minimal 2 karakter';
    if (text.length > 50) return 'Nama maksimal 50 karakter';
    if (!_nameChars.hasMatch(text)) {
      return 'Nama hanya boleh berisi huruf, spasi, titik, apostrof, dan tanda hubung';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    final String text = (value ?? '').trim();
    if (text.isEmpty) return 'Email wajib diisi';
    if (text.length > 100) return 'Email maksimal 100 karakter';
    if (text.contains('..') || !_emailPattern.hasMatch(text)) {
      return 'Format email tidak valid (contoh: nama@email.com)';
    }
    return null;
  }

  /// Aturan password saat registrasi.
  static String? validatePassword(String? value) {
    final String text = value ?? '';
    if (text.isEmpty) return 'Password wajib diisi';
    if (text.length < 8) return 'Password minimal 8 karakter';
    if (text.length > 64) return 'Password maksimal 64 karakter';
    if (text.contains(RegExp(r'\s'))) {
      return 'Password tidak boleh mengandung spasi';
    }
    if (!passwordHasLetter(text)) return 'Password harus mengandung huruf';
    if (!passwordHasDigit(text)) return 'Password harus mengandung angka';
    return null;
  }

  /// Saat login cukup diperiksa tidak kosong; aturan lengkap hanya untuk akun baru.
  static String? validateLoginPassword(String? value) {
    if ((value ?? '').isEmpty) return 'Password wajib diisi';
    return null;
  }

  static String? validateConfirmPassword(String? password, String? confirm) {
    if ((confirm ?? '').isEmpty) return 'Konfirmasi password wajib diisi';
    if (password != confirm) return 'Konfirmasi password tidak sama';
    return null;
  }

  static bool passwordHasMinLength(String p) => p.length >= 8;
  static bool passwordHasLetter(String p) => p.contains(RegExp(r'[A-Za-z]'));
  static bool passwordHasDigit(String p) => p.contains(RegExp(r'[0-9]'));

  /// Menilai kekuatan password: panjang, huruf besar-kecil, angka, simbol.
  static PasswordStrength evaluatePassword(String password) {
    if (password.isEmpty) return PasswordStrength.empty;
    int score = 0;
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (password.contains(RegExp(r'[a-z]')) &&
        password.contains(RegExp(r'[A-Z]'))) {
      score++;
    }
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[^A-Za-z0-9]'))) score++;

    if (score <= 2) return PasswordStrength.weak;
    if (score == 3) return PasswordStrength.fair;
    if (score == 4) return PasswordStrength.good;
    return PasswordStrength.strong;
  }

  // ------------------------------------------------------------------ sesi

  /// Mengecek sesi tersimpan saat aplikasi dibuka. Panggil sebelum runApp
  /// agar router langsung mengarah ke Dasbor atau Login tanpa berkedip.
  Future<void> checkSession() async {
    try {
      final int? savedId = await _sessionRepository.getSavedUserId();
      if (savedId == null) {
        _currentUser = null;
      } else {
        final UserModel? user = await _userRepository.getById(savedId);
        if (user == null) {
          await _sessionRepository.clear();
        }
        _currentUser = user;
      }
    } catch (_) {
      _currentUser = null;
    }
    _isInitialized = true;
    safeNotify();
  }

  /// Masuk dengan email dan password. Mengembalikan true bila berhasil.
  Future<bool> login({required String email, required String password}) async {
    if (_isLoading) return false;

    final int locked = lockSecondsRemaining;
    if (locked > 0) {
      _errorMessage =
          'Terlalu banyak percobaan gagal. Coba lagi dalam $locked detik.';
      safeNotify();
      return false;
    }

    final String? emailError = validateEmail(email);
    if (emailError != null || password.isEmpty) {
      _errorMessage = emailError ?? 'Password wajib diisi';
      safeNotify();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    _infoMessage = null;
    safeNotify();

    try {
      final UserModel? user = await _userRepository.authenticate(
        email: email.trim(),
        password: password,
      );
      final int? userId = user?.id;
      if (user == null || userId == null) {
        _failedAttempts++;
        if (_failedAttempts >= maxFailedAttempts) {
          _failedAttempts = 0;
          _lockedUntil = _clock().add(lockDuration);
          _errorMessage =
              'Terlalu banyak percobaan gagal. Coba lagi dalam ${lockDuration.inSeconds} detik.';
        } else {
          final int remaining = maxFailedAttempts - _failedAttempts;
          _errorMessage = remaining <= 2
              ? 'Username atau Password salah (sisa $remaining percobaan)'
              : 'Username atau Password salah';
        }
        _isLoading = false;
        safeNotify();
        return false;
      }

      await _sessionRepository.saveUserId(userId);
      _failedAttempts = 0;
      _lockedUntil = null;
      _currentUser = user;
      _isLoading = false;
      safeNotify();
      return true;
    } catch (_) {
      _errorMessage = _genericError;
      _isLoading = false;
      safeNotify();
      return false;
    }
  }

  /// Mendaftarkan akun baru. Setelah berhasil pengguna dikembalikan ke halaman
  /// Login (tidak langsung masuk), sesuai alur UC-01.
  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    if (_isLoading) return false;

    final String? validationError = validateName(name) ??
        validateEmail(email) ??
        validatePassword(password);
    if (validationError != null) {
      _errorMessage = validationError;
      safeNotify();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    _infoMessage = null;
    safeNotify();

    try {
      await _userRepository.register(
        name: name.trim().replaceAll(RegExp(r'\s+'), ' '),
        email: email.trim(),
        password: password,
      );
      _infoMessage = 'Registrasi berhasil. Silakan login.';
      _isLoading = false;
      safeNotify();
      return true;
    } on RepositoryException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      safeNotify();
      return false;
    } catch (_) {
      _errorMessage = _genericError;
      _isLoading = false;
      safeNotify();
      return false;
    }
  }

  /// Keluar: menghapus sesi sehingga Auth Guard mengarahkan ke Login.
  Future<void> logout() async {
    try {
      await _sessionRepository.clear();
    } catch (_) {
      // Sesi di memori tetap dihapus walau penyimpanan gagal dibersihkan.
    }
    _currentUser = null;
    _errorMessage = null;
    _infoMessage = null;
    safeNotify();
  }

  /// Memuat ulang data pengguna aktif dari database (misalnya setelah ganti nama).
  Future<void> refreshCurrentUser() async {
    final int? userId = _currentUser?.id;
    if (userId == null) return;
    try {
      final UserModel? user = await _userRepository.getById(userId);
      if (user != null) {
        _currentUser = user;
        safeNotify();
      }
    } catch (_) {
      // Data lama tetap dipakai bila gagal memuat ulang.
    }
  }

  void clearMessages() {
    if (_errorMessage == null && _infoMessage == null) return;
    _errorMessage = null;
    _infoMessage = null;
    safeNotify();
  }
}
