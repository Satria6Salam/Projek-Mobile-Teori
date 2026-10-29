import '../../core/constants/db_constants.dart';
import '../../core/utils/db_date_utils.dart';

/// Representasi tabel `users`.
class UserModel {
  const UserModel({
    this.id,
    required this.name,
    required this.email,
    required this.passwordHash,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final String name;
  final String email;
  final String passwordHash;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory UserModel.fromMap(Map<String, Object?> map) {
    return UserModel(
      id: map[UserCols.id] as int?,
      name: map[UserCols.name] as String? ?? '',
      email: map[UserCols.email] as String? ?? '',
      passwordHash: map[UserCols.passwordHash] as String? ?? '',
      createdAt: DbDateUtils.parseOrNow(map[UserCols.createdAt]),
      updatedAt: DbDateUtils.parseOrNow(map[UserCols.updatedAt]),
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) UserCols.id: id,
      UserCols.name: name,
      UserCols.email: email,
      UserCols.passwordHash: passwordHash,
      UserCols.createdAt: DbDateUtils.dateTimeToDb(createdAt),
      UserCols.updatedAt: DbDateUtils.dateTimeToDb(updatedAt),
    };
  }

  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    String? passwordHash,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
