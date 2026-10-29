import 'package:flutter/foundation.dart';

/// Mencegah pemanggilan notifyListeners() setelah ViewModel di-dispose
/// (dapat terjadi ketika proses asinkron selesai setelah layar ditutup).
mixin SafeChangeNotifier on ChangeNotifier {
  bool _isDisposed = false;

  bool get isDisposed => _isDisposed;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void safeNotify() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }
}
