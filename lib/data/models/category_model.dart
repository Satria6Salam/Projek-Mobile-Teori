import '../../core/constants/db_constants.dart';
import '../../core/utils/db_date_utils.dart';

/// Representasi tabel `categories` (label/kelas untuk Naive Bayes).
class CategoryModel {
  const CategoryModel({
    this.id,
    required this.name,
    this.description,
    required this.createdAt,
  });

  final int? id;
  final String name;
  final String? description;
  final DateTime createdAt;

  factory CategoryModel.fromMap(Map<String, Object?> map) {
    return CategoryModel(
      id: map[CategoryCols.id] as int?,
      name: map[CategoryCols.name] as String? ?? '',
      description: map[CategoryCols.description] as String?,
      createdAt: DbDateUtils.parseOrNow(map[CategoryCols.createdAt]),
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) CategoryCols.id: id,
      CategoryCols.name: name,
      CategoryCols.description: description,
      CategoryCols.createdAt: DbDateUtils.dateTimeToDb(createdAt),
    };
  }

  CategoryModel copyWith({
    int? id,
    String? name,
    String? description,
    DateTime? createdAt,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
