import '../../core/constants/db_constants.dart';
import '../../core/utils/db_date_utils.dart';

/// Representasi tabel `transactions` (data final setelah divalidasi pengguna).
class TransactionModel {
  const TransactionModel({
    this.id,
    required this.userId,
    this.ocrId,
    this.parsedId,
    this.classificationId,
    required this.merchantName,
    required this.transactionDate,
    required this.totalAmount,
    required this.categoryId,
    this.isManualEdit = false,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.categoryName,
  });

  final int? id;
  final int userId;
  final int? ocrId;
  final int? parsedId;
  final int? classificationId;
  final String merchantName;
  final DateTime transactionDate;
  final double totalAmount;
  final int categoryId;

  /// True jika pengguna mengubah hasil AI secara manual.
  final bool isManualEdit;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Tidak disimpan di tabel; terisi saat query digabung dengan `categories`.
  final String? categoryName;

  factory TransactionModel.fromMap(Map<String, Object?> map) {
    return TransactionModel(
      id: map[TransCols.id] as int?,
      userId: map[TransCols.userId] as int? ?? 0,
      ocrId: map[TransCols.ocrId] as int?,
      parsedId: map[TransCols.parsedId] as int?,
      classificationId: map[TransCols.classificationId] as int?,
      merchantName: map[TransCols.merchantName] as String? ?? '',
      transactionDate: DbDateUtils.parseOrNow(map[TransCols.transactionDate]),
      totalAmount: (map[TransCols.totalAmount] as num?)?.toDouble() ?? 0.0,
      categoryId: map[TransCols.categoryId] as int? ?? 0,
      isManualEdit: (map[TransCols.isManualEdit] as int? ?? 0) == 1,
      notes: map[TransCols.notes] as String?,
      createdAt: DbDateUtils.parseOrNow(map[TransCols.createdAt]),
      updatedAt: DbDateUtils.parseOrNow(map[TransCols.updatedAt]),
      categoryName: map[CategoryCols.name] as String?,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) TransCols.id: id,
      TransCols.userId: userId,
      TransCols.ocrId: ocrId,
      TransCols.parsedId: parsedId,
      TransCols.classificationId: classificationId,
      TransCols.merchantName: merchantName,
      TransCols.transactionDate: DbDateUtils.dateToDb(transactionDate),
      TransCols.totalAmount: totalAmount,
      TransCols.categoryId: categoryId,
      TransCols.isManualEdit: isManualEdit ? 1 : 0,
      TransCols.notes: notes,
      TransCols.createdAt: DbDateUtils.dateTimeToDb(createdAt),
      TransCols.updatedAt: DbDateUtils.dateTimeToDb(updatedAt),
    };
  }

  TransactionModel copyWith({
    int? id,
    int? userId,
    int? ocrId,
    int? parsedId,
    int? classificationId,
    String? merchantName,
    DateTime? transactionDate,
    double? totalAmount,
    int? categoryId,
    bool? isManualEdit,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? categoryName,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      ocrId: ocrId ?? this.ocrId,
      parsedId: parsedId ?? this.parsedId,
      classificationId: classificationId ?? this.classificationId,
      merchantName: merchantName ?? this.merchantName,
      transactionDate: transactionDate ?? this.transactionDate,
      totalAmount: totalAmount ?? this.totalAmount,
      categoryId: categoryId ?? this.categoryId,
      isManualEdit: isManualEdit ?? this.isManualEdit,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      categoryName: categoryName ?? this.categoryName,
    );
  }
}
