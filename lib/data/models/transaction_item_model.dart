import '../../core/constants/db_constants.dart';
import '../../core/utils/db_date_utils.dart';

/// Representasi tabel `transaction_items`: satu barang pada sebuah struk.
class TransactionItemModel {
  const TransactionItemModel({
    this.id,
    required this.transactionId,
    required this.name,
    this.quantity = 1,
    required this.unitPrice,
    required this.totalPrice,
    required this.categoryId,
    this.aiCategoryId,
    this.aiConfidence,
    required this.createdAt,
    this.categoryName,
  });

  final int? id;
  final int transactionId;
  final String name;
  final double quantity;
  final double unitPrice;
  final double totalPrice;
  final int categoryId;

  /// Kategori tebakan AI (untuk membandingkan dengan koreksi pengguna).
  final int? aiCategoryId;
  final double? aiConfidence;
  final DateTime createdAt;

  /// Tidak disimpan di tabel; terisi saat query digabung dengan `categories`.
  final String? categoryName;

  factory TransactionItemModel.fromMap(Map<String, Object?> map) {
    return TransactionItemModel(
      id: map[ItemCols.id] as int?,
      transactionId: map[ItemCols.transactionId] as int? ?? 0,
      name: map[ItemCols.name] as String? ?? '',
      quantity: (map[ItemCols.quantity] as num?)?.toDouble() ?? 1.0,
      unitPrice: (map[ItemCols.unitPrice] as num?)?.toDouble() ?? 0.0,
      totalPrice: (map[ItemCols.totalPrice] as num?)?.toDouble() ?? 0.0,
      categoryId: map[ItemCols.categoryId] as int? ?? 0,
      aiCategoryId: map[ItemCols.aiCategoryId] as int?,
      aiConfidence: (map[ItemCols.aiConfidence] as num?)?.toDouble(),
      createdAt: DbDateUtils.parseOrNow(map[ItemCols.createdAt]),
      categoryName: map[CategoryCols.name] as String?,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) ItemCols.id: id,
      ItemCols.transactionId: transactionId,
      ItemCols.name: name,
      ItemCols.quantity: quantity,
      ItemCols.unitPrice: unitPrice,
      ItemCols.totalPrice: totalPrice,
      ItemCols.categoryId: categoryId,
      ItemCols.aiCategoryId: aiCategoryId,
      ItemCols.aiConfidence: aiConfidence,
      ItemCols.createdAt: DbDateUtils.dateTimeToDb(createdAt),
    };
  }

  TransactionItemModel copyWith({
    int? id,
    int? transactionId,
    String? name,
    double? quantity,
    double? unitPrice,
    double? totalPrice,
    int? categoryId,
    int? aiCategoryId,
    double? aiConfidence,
    DateTime? createdAt,
    String? categoryName,
  }) {
    return TransactionItemModel(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      categoryId: categoryId ?? this.categoryId,
      aiCategoryId: aiCategoryId ?? this.aiCategoryId,
      aiConfidence: aiConfidence ?? this.aiConfidence,
      createdAt: createdAt ?? this.createdAt,
      categoryName: categoryName ?? this.categoryName,
    );
  }
}

/// Pasangan nama barang dan nama kategori yang sudah divalidasi pengguna.
/// Dipakai untuk melatih ulang model AI dari koreksi pengguna.
class LabeledItem {
  const LabeledItem({required this.name, required this.categoryName});

  final String name;
  final String categoryName;
}
