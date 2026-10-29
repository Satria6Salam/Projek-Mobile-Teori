/// Kesalahan yang aman ditampilkan ke pengguna (pesan sudah berbahasa Indonesia).
class RepositoryException implements Exception {
  const RepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}
