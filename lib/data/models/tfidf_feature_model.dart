import '../../core/constants/db_constants.dart';

/// Representasi tabel `tfidf_features` (detail bobot TF-IDF per term).
class TfidfFeatureModel {
  const TfidfFeatureModel({
    this.id,
    required this.classificationId,
    required this.term,
    required this.tf,
    required this.idf,
    required this.tfidfWeight,
  });

  final int? id;
  final int classificationId;
  final String term;
  final double tf;
  final double idf;
  final double tfidfWeight;

  factory TfidfFeatureModel.fromMap(Map<String, Object?> map) {
    return TfidfFeatureModel(
      id: map[TfidfCols.id] as int?,
      classificationId: map[TfidfCols.classificationId] as int? ?? 0,
      term: map[TfidfCols.term] as String? ?? '',
      tf: (map[TfidfCols.tf] as num?)?.toDouble() ?? 0.0,
      idf: (map[TfidfCols.idf] as num?)?.toDouble() ?? 0.0,
      tfidfWeight: (map[TfidfCols.weight] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) TfidfCols.id: id,
      TfidfCols.classificationId: classificationId,
      TfidfCols.term: term,
      TfidfCols.tf: tf,
      TfidfCols.idf: idf,
      TfidfCols.weight: tfidfWeight,
    };
  }

  TfidfFeatureModel copyWith({
    int? id,
    int? classificationId,
    String? term,
    double? tf,
    double? idf,
    double? tfidfWeight,
  }) {
    return TfidfFeatureModel(
      id: id ?? this.id,
      classificationId: classificationId ?? this.classificationId,
      term: term ?? this.term,
      tf: tf ?? this.tf,
      idf: idf ?? this.idf,
      tfidfWeight: tfidfWeight ?? this.tfidfWeight,
    );
  }
}
