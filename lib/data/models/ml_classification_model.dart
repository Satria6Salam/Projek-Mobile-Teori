import '../../core/constants/db_constants.dart';
import '../../core/utils/db_date_utils.dart';

/// Representasi tabel `ml_classifications` (hasil TF-IDF + Multinomial Naive Bayes).
class MlClassificationModel {
  const MlClassificationModel({
    this.id,
    required this.parsedId,
    required this.inputText,
    required this.preprocessedText,
    this.predictedCategoryId,
    this.predictionProbability,
    required this.modelName,
    required this.modelVersion,
    required this.classificationStatus,
    required this.createdAt,
  });

  final int? id;
  final int parsedId;
  final String inputText;
  final String preprocessedText;
  final int? predictedCategoryId;
  final double? predictionProbability;
  final String modelName;
  final String modelVersion;

  /// `ClassificationStatus.success` atau `failed`.
  final String classificationStatus;
  final DateTime createdAt;

  factory MlClassificationModel.fromMap(Map<String, Object?> map) {
    return MlClassificationModel(
      id: map[ClassCols.id] as int?,
      parsedId: map[ClassCols.parsedId] as int? ?? 0,
      inputText: map[ClassCols.inputText] as String? ?? '',
      preprocessedText: map[ClassCols.preprocessedText] as String? ?? '',
      predictedCategoryId: map[ClassCols.predictedCategoryId] as int?,
      predictionProbability: (map[ClassCols.probability] as num?)?.toDouble(),
      modelName: map[ClassCols.modelName] as String? ?? '',
      modelVersion: map[ClassCols.modelVersion] as String? ?? '',
      classificationStatus:
          map[ClassCols.status] as String? ?? ClassificationStatus.failed,
      createdAt: DbDateUtils.parseOrNow(map[ClassCols.createdAt]),
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) ClassCols.id: id,
      ClassCols.parsedId: parsedId,
      ClassCols.inputText: inputText,
      ClassCols.preprocessedText: preprocessedText,
      ClassCols.predictedCategoryId: predictedCategoryId,
      ClassCols.probability: predictionProbability,
      ClassCols.modelName: modelName,
      ClassCols.modelVersion: modelVersion,
      ClassCols.status: classificationStatus,
      ClassCols.createdAt: DbDateUtils.dateTimeToDb(createdAt),
    };
  }

  MlClassificationModel copyWith({
    int? id,
    int? parsedId,
    String? inputText,
    String? preprocessedText,
    int? predictedCategoryId,
    double? predictionProbability,
    String? modelName,
    String? modelVersion,
    String? classificationStatus,
    DateTime? createdAt,
  }) {
    return MlClassificationModel(
      id: id ?? this.id,
      parsedId: parsedId ?? this.parsedId,
      inputText: inputText ?? this.inputText,
      preprocessedText: preprocessedText ?? this.preprocessedText,
      predictedCategoryId: predictedCategoryId ?? this.predictedCategoryId,
      predictionProbability:
          predictionProbability ?? this.predictionProbability,
      modelName: modelName ?? this.modelName,
      modelVersion: modelVersion ?? this.modelVersion,
      classificationStatus: classificationStatus ?? this.classificationStatus,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
