import '../../core/constants/db_constants.dart';
import '../../core/utils/db_date_utils.dart';

/// Representasi tabel `parsed_receipts` (hasil Smart Parsing / Regex).
/// Merchant, tanggal, dan total boleh null bila tidak ditemukan (UC-03).
class ParsedReceiptModel {
  const ParsedReceiptModel({
    this.id,
    required this.ocrId,
    this.merchantName,
    this.transactionDate,
    this.totalAmount,
    required this.parsingStatus,
    required this.createdAt,
  });

  final int? id;
  final int ocrId;
  final String? merchantName;
  final DateTime? transactionDate;
  final double? totalAmount;

  /// `ParsingStatus.success`, `partial`, atau `failed`.
  final String parsingStatus;
  final DateTime createdAt;

  factory ParsedReceiptModel.fromMap(Map<String, Object?> map) {
    return ParsedReceiptModel(
      id: map[ParsedCols.id] as int?,
      ocrId: map[ParsedCols.ocrId] as int? ?? 0,
      merchantName: map[ParsedCols.merchantName] as String?,
      transactionDate: DbDateUtils.tryParse(map[ParsedCols.transactionDate]),
      totalAmount: (map[ParsedCols.totalAmount] as num?)?.toDouble(),
      parsingStatus: map[ParsedCols.status] as String? ?? ParsingStatus.failed,
      createdAt: DbDateUtils.parseOrNow(map[ParsedCols.createdAt]),
    );
  }

  Map<String, Object?> toMap() {
    final DateTime? date = transactionDate;
    return <String, Object?>{
      if (id != null) ParsedCols.id: id,
      ParsedCols.ocrId: ocrId,
      ParsedCols.merchantName: merchantName,
      ParsedCols.transactionDate: date == null ? null : DbDateUtils.dateToDb(date),
      ParsedCols.totalAmount: totalAmount,
      ParsedCols.status: parsingStatus,
      ParsedCols.createdAt: DbDateUtils.dateTimeToDb(createdAt),
    };
  }

  ParsedReceiptModel copyWith({
    int? id,
    int? ocrId,
    String? merchantName,
    DateTime? transactionDate,
    double? totalAmount,
    String? parsingStatus,
    DateTime? createdAt,
  }) {
    return ParsedReceiptModel(
      id: id ?? this.id,
      ocrId: ocrId ?? this.ocrId,
      merchantName: merchantName ?? this.merchantName,
      transactionDate: transactionDate ?? this.transactionDate,
      totalAmount: totalAmount ?? this.totalAmount,
      parsingStatus: parsingStatus ?? this.parsingStatus,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
