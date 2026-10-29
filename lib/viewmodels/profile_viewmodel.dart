import 'package:flutter/foundation.dart';

import '../data/repositories/user_repository.dart';
import 'auth_viewmodel.dart';
import 'safe_change_notifier.dart';

/// Pengaturan akun dan sesi: tampil profil, ganti nama, logout.
class ProfileViewModel extends ChangeNotifier with SafeChangeNotifier {
  ProfileViewModel({
    required AuthViewModel authViewModel,
    required UserRepository userRepository,
  })  : _auth = authViewModel,
        _userRepository = userRepository {
    _auth.addListener(_onAuthChanged);
  }

  final AuthViewModel _auth;
  final UserRepository _userRepository;

  bool _isSaving = false;
  String? _errorMessage;
  String? _successMessage;

  String get name => _auth.currentUser?.name ?? '';
  String get email => _auth.currentUser?.email ?? '';
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  Future<bool> updateName(String newName) async {
    final int? userId = _auth.currentUser?.id;
    if (userId == null || _isSaving) return false;

    final String? validationError = AuthViewModel.validateName(newName);
    if (validationError != null) {
      _errorMessage = validationError;
      _successMessage = null;
      safeNotify();
      return false;
    }

    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    safeNotify();

    try {
      final bool updated =
          await _userRepository.updateName(userId: userId, name: newName);
      if (!updated) {
        _errorMessage = 'Gagal memperbarui nama.';
      } else {
        await _auth.refreshCurrentUser();
        _successMessage = 'Nama berhasil diperbarui.';
      }
    } catch (_) {
      _errorMessage = 'Gagal memperbarui nama. Silakan coba lagi.';
    }

    _isSaving = false;
    safeNotify();
    return _errorMessage == null;
  }

  Future<void> logout() => _auth.logout();

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    safeNotify();
  }

  void _onAuthChanged() => safeNotify();

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }
}
