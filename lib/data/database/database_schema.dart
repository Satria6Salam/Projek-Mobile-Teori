import '../../core/constants/db_constants.dart';

/// Query pembuatan tabel (DDL) dan data awal.
/// Tipe: DATE/DATETIME disimpan sebagai TEXT (ISO-8601), DECIMAL sebagai REAL,
/// BOOLEAN sebagai INTEGER (0/1).
class DatabaseSchema {
  DatabaseSchema._();

  static const String createUsers = '''
CREATE TABLE ${DbTables.users} (
  ${UserCols.id} INTEGER PRIMARY KEY AUTOINCREMENT,
  ${UserCols.name} TEXT NOT NULL,
  ${UserCols.email} TEXT NOT NULL UNIQUE,
  ${UserCols.passwordHash} TEXT NOT NULL,
  ${UserCols.createdAt} TEXT NOT NULL,
  ${UserCols.updatedAt} TEXT NOT NULL
)''';

  static const String createCategories = '''
CREATE TABLE ${DbTables.categories} (
  ${CategoryCols.id} INTEGER PRIMARY KEY AUTOINCREMENT,
  ${CategoryCols.name} TEXT NOT NULL UNIQUE,
  ${CategoryCols.description} TEXT,
  ${CategoryCols.createdAt} TEXT NOT NULL
)''';

  static const String createOcrResults = '''
CREATE TABLE ${DbTables.ocrResults} (
  ${OcrCols.id} INTEGER PRIMARY KEY AUTOINCREMENT,
  ${OcrCols.userId} INTEGER NOT NULL,
  ${OcrCols.imagePath} TEXT NOT NULL,
  ${OcrCols.rawText} TEXT NOT NULL DEFAULT '',
  ${OcrCols.source} TEXT NOT NULL,
  ${OcrCols.status} TEXT NOT NULL,
  ${OcrCols.error} TEXT,
  ${OcrCols.createdAt} TEXT NOT NULL,
  FOREIGN KEY (${OcrCols.userId}) REFERENCES ${DbTables.users}(${UserCols.id})
    ON DELETE CASCADE
)''';

  static const String createParsedReceipts = '''
CREATE TABLE ${DbTables.parsedReceipts} (
  ${ParsedCols.id} INTEGER PRIMARY KEY AUTOINCREMENT,
  ${ParsedCols.ocrId} INTEGER NOT NULL UNIQUE,
  ${ParsedCols.merchantName} TEXT,
  ${ParsedCols.transactionDate} TEXT,
  ${ParsedCols.totalAmount} REAL,
  ${ParsedCols.status} TEXT NOT NULL,
  ${ParsedCols.createdAt} TEXT NOT NULL,
  FOREIGN KEY (${ParsedCols.ocrId}) REFERENCES ${DbTables.ocrResults}(${OcrCols.id})
    ON DELETE CASCADE
)''';

  static const String createMlClassifications = '''
CREATE TABLE ${DbTables.mlClassifications} (
  ${ClassCols.id} INTEGER PRIMARY KEY AUTOINCREMENT,
  ${ClassCols.parsedId} INTEGER NOT NULL UNIQUE,
  ${ClassCols.inputText} TEXT NOT NULL,
  ${ClassCols.preprocessedText} TEXT NOT NULL,
  ${ClassCols.predictedCategoryId} INTEGER,
  ${ClassCols.probability} REAL,
  ${ClassCols.modelName} TEXT NOT NULL,
  ${ClassCols.modelVersion} TEXT NOT NULL,
  ${ClassCols.status} TEXT NOT NULL,
  ${ClassCols.createdAt} TEXT NOT NULL,
  FOREIGN KEY (${ClassCols.parsedId}) REFERENCES ${DbTables.parsedReceipts}(${ParsedCols.id})
    ON DELETE CASCADE,
  FOREIGN KEY (${ClassCols.predictedCategoryId}) REFERENCES ${DbTables.categories}(${CategoryCols.id})
    ON DELETE SET NULL
)''';

  static const String createTfidfFeatures = '''
CREATE TABLE ${DbTables.tfidfFeatures} (
  ${TfidfCols.id} INTEGER PRIMARY KEY AUTOINCREMENT,
  ${TfidfCols.classificationId} INTEGER NOT NULL,
  ${TfidfCols.term} TEXT NOT NULL,
  ${TfidfCols.tf} REAL NOT NULL,
  ${TfidfCols.idf} REAL NOT NULL,
  ${TfidfCols.weight} REAL NOT NULL,
  FOREIGN KEY (${TfidfCols.classificationId}) REFERENCES ${DbTables.mlClassifications}(${ClassCols.id})
    ON DELETE CASCADE
)''';

  static const String createTransactions = '''
CREATE TABLE ${DbTables.transactions} (
  ${TransCols.id} INTEGER PRIMARY KEY AUTOINCREMENT,
  ${TransCols.userId} INTEGER NOT NULL,
  ${TransCols.ocrId} INTEGER,
  ${TransCols.parsedId} INTEGER,
  ${TransCols.classificationId} INTEGER UNIQUE,
  ${TransCols.merchantName} TEXT NOT NULL,
  ${TransCols.transactionDate} TEXT NOT NULL,
  ${TransCols.totalAmount} REAL NOT NULL,
  ${TransCols.categoryId} INTEGER NOT NULL,
  ${TransCols.isManualEdit} INTEGER NOT NULL DEFAULT 0,
  ${TransCols.notes} TEXT,
  ${TransCols.createdAt} TEXT NOT NULL,
  ${TransCols.updatedAt} TEXT NOT NULL,
  FOREIGN KEY (${TransCols.userId}) REFERENCES ${DbTables.users}(${UserCols.id})
    ON DELETE CASCADE,
  FOREIGN KEY (${TransCols.ocrId}) REFERENCES ${DbTables.ocrResults}(${OcrCols.id})
    ON DELETE SET NULL,
  FOREIGN KEY (${TransCols.parsedId}) REFERENCES ${DbTables.parsedReceipts}(${ParsedCols.id})
    ON DELETE SET NULL,
  FOREIGN KEY (${TransCols.classificationId}) REFERENCES ${DbTables.mlClassifications}(${ClassCols.id})
    ON DELETE SET NULL,
  FOREIGN KEY (${TransCols.categoryId}) REFERENCES ${DbTables.categories}(${CategoryCols.id})
    ON DELETE RESTRICT
)''';

  /// Rincian barang pada tiap transaksi (satu struk dapat berisi banyak kategori).
  static const String createTransactionItems = '''
CREATE TABLE ${DbTables.transactionItems} (
  ${ItemCols.id} INTEGER PRIMARY KEY AUTOINCREMENT,
  ${ItemCols.transactionId} INTEGER NOT NULL,
  ${ItemCols.name} TEXT NOT NULL,
  ${ItemCols.quantity} REAL NOT NULL DEFAULT 1,
  ${ItemCols.unitPrice} REAL NOT NULL,
  ${ItemCols.totalPrice} REAL NOT NULL,
  ${ItemCols.categoryId} INTEGER NOT NULL,
  ${ItemCols.aiCategoryId} INTEGER,
  ${ItemCols.aiConfidence} REAL,
  ${ItemCols.createdAt} TEXT NOT NULL,
  FOREIGN KEY (${ItemCols.transactionId}) REFERENCES ${DbTables.transactions}(${TransCols.id})
    ON DELETE CASCADE,
  FOREIGN KEY (${ItemCols.categoryId}) REFERENCES ${DbTables.categories}(${CategoryCols.id})
    ON DELETE RESTRICT
)''';

  static const List<String> createIndexes = <String>[
    'CREATE INDEX idx_ocr_user ON ${DbTables.ocrResults}(${OcrCols.userId})',
    'CREATE INDEX idx_tfidf_classification ON ${DbTables.tfidfFeatures}(${TfidfCols.classificationId})',
    'CREATE INDEX idx_trans_user_date ON ${DbTables.transactions}(${TransCols.userId}, ${TransCols.transactionDate})',
    'CREATE INDEX idx_trans_category ON ${DbTables.transactions}(${TransCols.categoryId})',
    'CREATE INDEX idx_items_transaction ON ${DbTables.transactionItems}(${ItemCols.transactionId})',
    'CREATE INDEX idx_items_category ON ${DbTables.transactionItems}(${ItemCols.categoryId})',
  ];

  /// Perubahan skema dari versi 1 ke versi 2 (tabel rincian barang).
  static const List<String> upgradeToV2 = <String>[
    createTransactionItems,
    'CREATE INDEX idx_items_transaction ON ${DbTables.transactionItems}(${ItemCols.transactionId})',
    'CREATE INDEX idx_items_category ON ${DbTables.transactionItems}(${ItemCols.categoryId})',
  ];

  /// Urutan penting: tabel induk dibuat sebelum tabel yang mereferensikannya.
  static const List<String> createStatements = <String>[
    createUsers,
    createCategories,
    createOcrResults,
    createParsedReceipts,
    createMlClassifications,
    createTfidfFeatures,
    createTransactions,
    createTransactionItems,
  ];

  /// Kategori awal (label kelas Naive Bayes) sesuai rancangan basis data.
  static const List<Map<String, String>> defaultCategories =
      <Map<String, String>>[
    <String, String>{
      'name': 'Konsumsi',
      'description': 'Makanan dan minuman',
    },
    <String, String>{
      'name': 'Transportasi',
      'description': 'BBM, parkir, transportasi',
    },
    <String, String>{
      'name': 'Kesehatan',
      'description': 'Obat dan kebutuhan kesehatan',
    },
    <String, String>{
      'name': 'Belanja',
      'description': 'Barang kebutuhan pribadi',
    },
    <String, String>{
      'name': 'Lainnya',
      'description': 'Pengeluaran di luar kategori utama',
    },
    <String, String>{
      'name': 'Elektronik',
      'description': 'Perangkat, komponen, dan aksesori elektronik',
    },
  ];
}
