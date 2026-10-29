/// Ringkasan total pengeluaran per kategori (untuk Dasbor Keuangan).
class CategorySummaryModel {
  const CategorySummaryModel({
    required this.categoryId,
    required this.categoryName,
    required this.totalAmount,
    required this.transactionCount,
  });

  final int categoryId;
  final String categoryName;
  final double totalAmount;
  final int transactionCount;

  factory CategorySummaryModel.fromMap(Map<String, Object?> map) {
    return CategorySummaryModel(
      categoryId: map['category_id'] as int? ?? 0,
      categoryName: map['category_name'] as String? ?? '',
      totalAmount: (map['total_amount'] as num?)?.toDouble() ?? 0.0,
      transactionCount: map['transaction_count'] as int? ?? 0,
    );
  }
}
