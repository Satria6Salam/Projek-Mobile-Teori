import '../../core/constants/db_constants.dart';
import '../../core/utils/db_date_utils.dart';

/// Satu barang pada rencana belanja (tabel `shopping_plans`).
///
/// Barang yang sudah dibeli tidak dihapus, hanya ditandai [isBought], agar
/// tetap muncul di rekap "sudah dibeli" dan "belum dibeli".
class ShoppingPlanModel {
  const ShoppingPlanModel({
    this.id,
    required this.userId,
    required this.name,
    this.quantity = 1,
    this.note,
    this.status = PlanStatus.pending,
    required this.createdAt,
    this.boughtAt,
    this.transactionId,
    this.boughtName,
    this.boughtPrice,
  });

  final int? id;
  final int userId;
  final String name;
  final double quantity;
  final String? note;
  final String status;
  final DateTime createdAt;

  /// Diisi saat barang dibeli (dari struk yang dipindai atau ditandai manual).
  final DateTime? boughtAt;
  final int? transactionId;

  /// Nama barang pada struk yang cocok dengan rencana ini.
  final String? boughtName;
  final double? boughtPrice;

  bool get isBought => status == PlanStatus.bought;

  factory ShoppingPlanModel.fromMap(Map<String, Object?> map) {
    return ShoppingPlanModel(
      id: map[PlanCols.id] as int?,
      userId: map[PlanCols.userId] as int? ?? 0,
      name: map[PlanCols.name] as String? ?? '',
      quantity: (map[PlanCols.quantity] as num?)?.toDouble() ?? 1,
      note: map[PlanCols.note] as String?,
      status: map[PlanCols.status] as String? ?? PlanStatus.pending,
      createdAt: DbDateUtils.parseOrNow(map[PlanCols.createdAt]),
      boughtAt: DbDateUtils.tryParse(map[PlanCols.boughtAt]),
      transactionId: map[PlanCols.transactionId] as int?,
      boughtName: map[PlanCols.boughtName] as String?,
      boughtPrice: (map[PlanCols.boughtPrice] as num?)?.toDouble(),
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) PlanCols.id: id,
      PlanCols.userId: userId,
      PlanCols.name: name,
      PlanCols.quantity: quantity,
      PlanCols.note: note,
      PlanCols.status: status,
      PlanCols.createdAt: DbDateUtils.dateTimeToDb(createdAt),
      PlanCols.boughtAt:
          boughtAt == null ? null : DbDateUtils.dateTimeToDb(boughtAt!),
      PlanCols.transactionId: transactionId,
      PlanCols.boughtName: boughtName,
      PlanCols.boughtPrice: boughtPrice,
    };
  }

  /// Salinan berstatus "sudah dibeli".
  ShoppingPlanModel markBought({
    required DateTime at,
    int? transactionId,
    String? boughtName,
    double? boughtPrice,
  }) {
    return ShoppingPlanModel(
      id: id,
      userId: userId,
      name: name,
      quantity: quantity,
      note: note,
      status: PlanStatus.bought,
      createdAt: createdAt,
      boughtAt: at,
      transactionId: transactionId,
      boughtName: boughtName,
      boughtPrice: boughtPrice,
    );
  }

  /// Salinan yang dikembalikan ke daftar rencana (belum dibeli).
  ShoppingPlanModel markPending() {
    return ShoppingPlanModel(
      id: id,
      userId: userId,
      name: name,
      quantity: quantity,
      note: note,
      createdAt: createdAt,
    );
  }
}
