import '../../core/constants/db_constants.dart';
import '../../core/utils/db_date_utils.dart';

/// Representasi tabel `ocr_results` (hasil Google ML Kit OCR).
class OcrResultModel {
  const OcrResultModel({
    this.id,
    required this.userId,
    required this.imagePath,
    required this.rawText,
    required this.ocrSource,
    required this.ocrStatus,
    this.ocrError,
    required this.createdAt,
  });

  final int? id;
  final int userId;
  final String imagePath;
  final String rawText;

  /// `OcrSource.camera` atau `OcrSource.gallery`.
  final String ocrSource;

  /// `OcrStatus.success` atau `OcrStatus.failed`.
  final String ocrStatus;
  final String? ocrError;
  final DateTime createdAt;

  bool get isSuccess => ocrStatus == OcrStatus.success;

  factory OcrResultModel.fromMap(Map<String, Object?> map) {
    return OcrResultModel(
      id: map[OcrCols.id] as int?,
      userId: map[OcrCols.userId] as int? ?? 0,
      imagePath: map[OcrCols.imagePath] as String? ?? '',
      rawText: map[OcrCols.rawText] as String? ?? '',
      ocrSource: map[OcrCols.source] as String? ?? OcrSource.camera,
      ocrStatus: map[OcrCols.status] as String? ?? OcrStatus.failed,
      ocrError: map[OcrCols.error] as String?,
      createdAt: DbDateUtils.parseOrNow(map[OcrCols.createdAt]),
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) OcrCols.id: id,
      OcrCols.userId: userId,
      OcrCols.imagePath: imagePath,
      OcrCols.rawText: rawText,
      OcrCols.source: ocrSource,
      OcrCols.status: ocrStatus,
      OcrCols.error: ocrError,
      OcrCols.createdAt: DbDateUtils.dateTimeToDb(createdAt),
    };
  }

  OcrResultModel copyWith({
    int? id,
    int? userId,
    String? imagePath,
    String? rawText,
    String? ocrSource,
    String? ocrStatus,
    String? ocrError,
    DateTime? createdAt,
  }) {
    return OcrResultModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      imagePath: imagePath ?? this.imagePath,
      rawText: rawText ?? this.rawText,
      ocrSource: ocrSource ?? this.ocrSource,
      ocrStatus: ocrStatus ?? this.ocrStatus,
      ocrError: ocrError ?? this.ocrError,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
