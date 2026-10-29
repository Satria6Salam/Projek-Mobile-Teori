/// Konstanta basis data SQLite SmartReceipt.
class DbConstants {
  DbConstants._();

  static const String databaseName = 'smartreceipt.db';
  static const int databaseVersion = 3;
}

/// Nama tabel.
class DbTables {
  DbTables._();

  static const String users = 'users';
  static const String categories = 'categories';
  static const String ocrResults = 'ocr_results';
  static const String parsedReceipts = 'parsed_receipts';
  static const String mlClassifications = 'ml_classifications';
  static const String tfidfFeatures = 'tfidf_features';
  static const String transactions = 'transactions';
  static const String transactionItems = 'transaction_items';
}

/// Kolom tabel users.
class UserCols {
  UserCols._();

  static const String id = 'user_id';
  static const String name = 'name';
  static const String email = 'email';
  static const String passwordHash = 'password_hash';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
}

/// Kolom tabel categories.
class CategoryCols {
  CategoryCols._();

  static const String id = 'category_id';
  static const String name = 'category_name';
  static const String description = 'description';
  static const String createdAt = 'created_at';
}

/// Kolom tabel ocr_results.
class OcrCols {
  OcrCols._();

  static const String id = 'ocr_id';
  static const String userId = 'user_id';
  static const String imagePath = 'image_path';
  static const String rawText = 'raw_text';
  static const String source = 'ocr_source';
  static const String status = 'ocr_status';
  static const String error = 'ocr_error';
  static const String createdAt = 'created_at';
}

/// Kolom tabel parsed_receipts.
class ParsedCols {
  ParsedCols._();

  static const String id = 'parsed_id';
  static const String ocrId = 'ocr_id';
  static const String merchantName = 'merchant_name';
  static const String transactionDate = 'transaction_date';
  static const String totalAmount = 'total_amount';
  static const String status = 'parsing_status';
  static const String createdAt = 'created_at';
}

/// Kolom tabel ml_classifications.
class ClassCols {
  ClassCols._();

  static const String id = 'classification_id';
  static const String parsedId = 'parsed_id';
  static const String inputText = 'input_text';
  static const String preprocessedText = 'preprocessed_text';
  static const String predictedCategoryId = 'predicted_category_id';
  static const String probability = 'prediction_probability';
  static const String modelName = 'model_name';
  static const String modelVersion = 'model_version';
  static const String status = 'classification_status';
  static const String createdAt = 'created_at';
}

/// Kolom tabel tfidf_features.
class TfidfCols {
  TfidfCols._();

  static const String id = 'tfidf_id';
  static const String classificationId = 'classification_id';
  static const String term = 'term';
  static const String tf = 'tf';
  static const String idf = 'idf';
  static const String weight = 'tfidf_weight';
}

/// Kolom tabel transactions.
class TransCols {
  TransCols._();

  static const String id = 'transaction_id';
  static const String userId = 'user_id';
  static const String ocrId = 'ocr_id';
  static const String parsedId = 'parsed_id';
  static const String classificationId = 'classification_id';
  static const String merchantName = 'merchant_name';
  static const String transactionDate = 'transaction_date';
  static const String totalAmount = 'total_amount';
  static const String categoryId = 'category_id';
  static const String isManualEdit = 'is_manual_edit';
  static const String notes = 'notes';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
}

/// Kolom tabel transaction_items (rincian barang per transaksi).
class ItemCols {
  ItemCols._();

  static const String id = 'item_id';
  static const String transactionId = 'transaction_id';
  static const String name = 'item_name';
  static const String quantity = 'quantity';
  static const String unitPrice = 'unit_price';
  static const String totalPrice = 'total_price';
  static const String categoryId = 'category_id';
  static const String aiCategoryId = 'ai_category_id';
  static const String aiConfidence = 'ai_confidence';
  static const String createdAt = 'created_at';
}

/// Nilai valid kolom ocr_source.
class OcrSource {
  OcrSource._();

  static const String camera = 'camera';
  static const String gallery = 'gallery';
  static const String file = 'file';
}

/// Nilai valid kolom ocr_status.
class OcrStatus {
  OcrStatus._();

  static const String success = 'success';
  static const String failed = 'failed';
}

/// Nilai valid kolom parsing_status.
class ParsingStatus {
  ParsingStatus._();

  static const String success = 'success';
  static const String partial = 'partial';
  static const String failed = 'failed';
}

/// Nilai valid kolom classification_status.
class ClassificationStatus {
  ClassificationStatus._();

  static const String success = 'success';
  static const String failed = 'failed';
}
