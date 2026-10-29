import 'dart:math' as math;

import 'ml_training_data.dart';

/// Bobot TF-IDF satu term (disimpan ke tabel `tfidf_features`).
class TfidfTerm {
  const TfidfTerm({
    required this.term,
    required this.tf,
    required this.idf,
    required this.weight,
  });

  final String term;
  final double tf;
  final double idf;

  /// TF x IDF.
  final double weight;
}

/// Hasil klasifikasi (disimpan ke tabel `ml_classifications`).
class ClassificationOutput {
  const ClassificationOutput({
    required this.inputText,
    required this.preprocessedText,
    required this.categoryName,
    required this.probability,
    required this.isConfident,
    required this.probabilities,
    required this.terms,
    required this.modelName,
    required this.modelVersion,
  });

  final String inputText;
  final String preprocessedText;

  /// Nama kategori hasil prediksi (cocokkan dengan `categories.category_name`).
  final String categoryName;

  /// Probabilitas kategori terpilih, 0.0 - 1.0.
  final double probability;

  /// False bila probabilitas rendah atau tidak ada kata yang dikenali model.
  final bool isConfident;

  /// Probabilitas seluruh kategori.
  final Map<String, double> probabilities;

  /// Term tingkat kata beserta bobot TF-IDF (tanpa n-gram karakter).
  final List<TfidfTerm> terms;
  final String modelName;
  final String modelVersion;

  ClassificationOutput copyWith({
    String? categoryName,
    double? probability,
    bool? isConfident,
  }) {
    return ClassificationOutput(
      inputText: inputText,
      preprocessedText: preprocessedText,
      categoryName: categoryName ?? this.categoryName,
      probability: probability ?? this.probability,
      isConfident: isConfident ?? this.isConfident,
      probabilities: probabilities,
      terms: terms,
      modelName: modelName,
      modelVersion: modelVersion,
    );
  }
}

/// TF-IDF + Multinomial Naive Bayes, ditulis murni Dart (tanpa library eksternal).
///
/// Peningkatan pada versi 2:
/// - Fitur ganda: kata utuh + n-gram karakter (tahan terhadap singkatan dan
///   salah baca OCR, mis. "INDOMIE GRG", "SHP SUNSILK").
/// - Perluasan singkatan khas struk dan pembuangan satuan (ml, gr, kg, pcs).
/// - Klasifikasi per barang (satu struk bisa berisi banyak kategori).
/// - Belajar dari koreksi pengguna lewat [learn].
class MlService {
  MlService({Map<String, List<String>>? trainingData})
      : _trainingData = trainingData ?? MlTrainingData.data;

  static const String modelName = 'Multinomial Naive Bayes';
  static const String modelVersion = '2.0.0';
  static const String fallbackCategory = MlTrainingData.lainnya;

  /// Di bawah nilai ini, hasil ditandai "perlu dicek" (isConfident = false).
  static const double confidenceThreshold = 0.5;

  /// Batas keyakinan petunjuk merchant agar boleh menggantikan tebakan barang.
  static const double merchantHintThreshold = 0.75;

  static const double _alpha = 1.0; // Laplace smoothing
  static const double _ngramWeight = 0.2;
  static const int _minTokenLength = 2;

  /// Contoh koreksi pengguna dihitung beberapa kali agar lebih berpengaruh.
  static const int _userSampleRepeat = 3;

  static const Set<String> _stopwords = <String>{
    'dan',
    'yang',
    'di',
    'ke',
    'dari',
    'untuk',
    'dengan',
    'pada',
    'pt',
    'cv',
    'tbk',
    'toko',
    'jl',
    'jln',
    'jalan',
    'no',
    'nomor',
    'rp',
    'qty',
    'item',
    'items',
    'by',
    'the',
    'and',
    'of',
    'bulan',
    'ini',
  };

  /// Satuan yang tidak membawa makna kategori.
  static const Set<String> _units = <String>{
    'ml',
    'gr',
    'gram',
    'kg',
    'ltr',
    'liter',
    'pcs',
    'pc',
    'sct',
    'pak',
    'box',
    'dus',
    'lbr',
    'buah',
    'rb',
    'ribu',
  };

  /// Singkatan yang lazim dicetak pada struk.
  static const Map<String, List<String>> _abbreviations =
      <String, List<String>>{
    'grg': <String>['goreng'],
    'gor': <String>['goreng'],
    'sbn': <String>['sabun'],
    'shp': <String>['shampoo'],
    'sampo': <String>['shampoo'],
    'sampoo': <String>['shampoo'],
    'pst': <String>['pasta'],
    'dtjn': <String>['deterjen'],
    'det': <String>['deterjen'],
    'mnrl': <String>['mineral'],
    'tlr': <String>['telur'],
    'btl': <String>['botol'],
    'kcg': <String>['kacang'],
    'cklt': <String>['coklat'],
    'coklt': <String>['coklat'],
    'cokelat': <String>['coklat'],
    'choco': <String>['coklat'],
    'bks': <String>['biskuit'],
    'bskt': <String>['biskuit'],
    'sus': <String>['susu'],
    'mlk': <String>['susu'],
    'mnyk': <String>['minyak'],
    'obt': <String>['obat'],
    'vit': <String>['vitamin'],
    'prtlt': <String>['pertalite'],
    'ptmx': <String>['pertamax'],
    'prtmx': <String>['pertamax'],
    'pertmax': <String>['pertamax'],
    'tkn': <String>['token'],
    'pls': <String>['pulsa'],
    'byr': <String>['bayar'],
    'blj': <String>['belanja'],
    'pmbalut': <String>['pembalut'],
    'klp': <String>['pelembut'],
    'spl': <String>['spesial'],
    'sdp': <String>['sedaap'],
    'pcm': <String>['paracetamol'],
    'amoxicilin': <String>['amoxicillin'],
    'closeup': <String>['close', 'up'],
    'cappucino': <String>['cappuccino'],
    'topup': <String>['top', 'up'],
    'fotocopy': <String>['fotokopi'],
    'apotik': <String>['apotek'],
  };

  final Map<String, List<String>> _trainingData;
  List<LabeledSample> _userSamples = <LabeledSample>[];

  bool _isTrained = false;
  int _vocabularySize = 0;
  final Map<String, double> _idf = <String, double>{};
  final Map<String, double> _logPrior = <String, double>{};
  final Map<String, Map<String, double>> _featureSum =
      <String, Map<String, double>>{};
  final Map<String, double> _classTotal = <String, double>{};

  bool get isTrained => _isTrained;

  List<String> get categories => _logPrior.keys.toList();

  /// Melatih model. Aman dipanggil berulang (hanya melatih sekali).
  Future<void> initialize() async {
    if (_isTrained) return;
    _train();
  }

  /// Melatih ulang dengan menambahkan barang yang sudah divalidasi pengguna.
  /// Dengan begitu model makin cocok dengan kebiasaan belanja pengguna.
  void learn(List<LabeledSample> samples) {
    _userSamples = List<LabeledSample>.of(samples);
    _train();
  }

  // ------------------------------------------------------- pra-pemrosesan

  /// Huruf kecil, buang angka & simbol, perluas singkatan, buang satuan dan stopword.
  List<String> tokenize(String text) {
    final String cleaned =
        text.toLowerCase().replaceAll(RegExp(r'[^a-z\s]'), ' ');
    final List<String> result = <String>[];
    for (final String raw in cleaned.split(RegExp(r'\s+'))) {
      if (raw.isEmpty) continue;
      final List<String> words = _abbreviations[raw] ?? <String>[raw];
      for (final String word in words) {
        if (word.length >= _minTokenLength &&
            !_stopwords.contains(word) &&
            !_units.contains(word)) {
          result.add(word);
        }
      }
    }
    return result;
  }

  String preprocess(String text) => tokenize(text).join(' ');

  /// Fitur = kata utuh (bobot 1) + n-gram karakter 3 dan 4 (bobot kecil).
  Map<String, double> _featureCounts(List<String> tokens) {
    final Map<String, double> counts = <String, double>{};
    for (final String token in tokens) {
      final String wordKey = 'w:$token';
      counts[wordKey] = (counts[wordKey] ?? 0) + 1.0;
      if (token.length >= 3) {
        final String padded = '<$token>';
        for (final int n in const <int>[3, 4]) {
          for (int i = 0; i + n <= padded.length; i++) {
            final String key = 'c:${padded.substring(i, i + n)}';
            counts[key] = (counts[key] ?? 0) + _ngramWeight;
          }
        }
      }
    }
    return counts;
  }

  // ---------------------------------------------------------------- latih

  void _train() {
    final List<Map<String, double>> documents = <Map<String, double>>[];
    final List<String> labels = <String>[];

    void addDocument(String label, String text, int repeat) {
      final List<String> tokens = tokenize(text);
      if (tokens.isEmpty) return;
      final Map<String, double> counts = _featureCounts(tokens);
      for (int i = 0; i < repeat; i++) {
        documents.add(counts);
        labels.add(label);
      }
    }

    _trainingData.forEach((String label, List<String> texts) {
      for (final String text in texts) {
        addDocument(label, text, 1);
      }
    });
    for (final LabeledSample sample in _userSamples) {
      if (_trainingData.containsKey(sample.label)) {
        addDocument(sample.label, sample.text, _userSampleRepeat);
      }
    }
    if (documents.isEmpty) {
      throw StateError('Data latih kosong; model tidak dapat dilatih.');
    }

    final int total = documents.length;

    // Document frequency -> IDF (smoothed): ln((1 + N) / (1 + df)) + 1
    final Map<String, int> docFreq = <String, int>{};
    for (final Map<String, double> doc in documents) {
      for (final String feature in doc.keys) {
        docFreq[feature] = (docFreq[feature] ?? 0) + 1;
      }
    }
    _idf.clear();
    docFreq.forEach((String feature, int df) {
      _idf[feature] = math.log((1 + total) / (1 + df)) + 1;
    });
    _vocabularySize = docFreq.length;

    // Akumulasi bobot TF-IDF per kelas.
    final Map<String, int> classDocCount = <String, int>{};
    _featureSum.clear();
    _classTotal.clear();
    for (int i = 0; i < documents.length; i++) {
      final String label = labels[i];
      classDocCount[label] = (classDocCount[label] ?? 0) + 1;
      final Map<String, double> sums =
          _featureSum.putIfAbsent(label, () => <String, double>{});
      for (final TfidfTerm t in _termsFrom(documents[i])) {
        sums[t.term] = (sums[t.term] ?? 0) + t.weight;
        _classTotal[label] = (_classTotal[label] ?? 0) + t.weight;
      }
    }

    _logPrior.clear();
    classDocCount.forEach((String label, int count) {
      _logPrior[label] = math.log(count / total);
    });

    _isTrained = true;
  }

  /// TF = bobot kemunculan / total bobot dokumen. Hanya fitur yang ada di
  /// kosakata model yang dikembalikan, diurutkan dari bobot terbesar.
  List<TfidfTerm> _termsFrom(Map<String, double> counts) {
    double sum = 0;
    for (final double v in counts.values) {
      sum += v;
    }
    if (sum <= 0) return const <TfidfTerm>[];

    final List<TfidfTerm> result = <TfidfTerm>[];
    counts.forEach((String feature, double count) {
      final double? idf = _idf[feature];
      if (idf == null) return;
      final double tf = count / sum;
      result.add(TfidfTerm(term: feature, tf: tf, idf: idf, weight: tf * idf));
    });
    result.sort((TfidfTerm a, TfidfTerm b) => b.weight.compareTo(a.weight));
    return result;
  }

  // ------------------------------------------------------------ prediksi

  /// Memprediksi kategori pengeluaran dari teks (nama barang atau merchant).
  ClassificationOutput classify(String text) {
    if (!_isTrained) _train();

    final List<String> tokens = tokenize(text);
    final String preprocessed = tokens.join(' ');
    final List<TfidfTerm> features = tokens.isEmpty
        ? const <TfidfTerm>[]
        : _termsFrom(_featureCounts(tokens));

    // log P(c) + sum( bobot_t * log P(t | c) )
    final Map<String, double> scores = <String, double>{};
    _logPrior.forEach((String label, double prior) {
      final Map<String, double> sums =
          _featureSum[label] ?? const <String, double>{};
      final double denominator = math.log(
        (_classTotal[label] ?? 0) + _alpha * _vocabularySize,
      );
      double score = prior;
      for (final TfidfTerm t in features) {
        final double numerator = math.log((sums[t.term] ?? 0) + _alpha);
        score += t.weight * (numerator - denominator);
      }
      scores[label] = score;
    });

    final Map<String, double> probabilities = _softmax(scores);

    String best = _argMax(probabilities);
    double probability = probabilities[best] ?? 0.0;
    if (features.isEmpty) {
      // Tidak ada yang dikenali: jangan menebak, arahkan ke "Lainnya".
      if (probabilities.containsKey(fallbackCategory)) best = fallbackCategory;
      probability = 0.0;
    }
    final bool confident =
        features.isNotEmpty && probability >= confidenceThreshold;

    final List<TfidfTerm> wordTerms = features
        .where((TfidfTerm t) => t.term.startsWith('w:'))
        .map(
          (TfidfTerm t) => TfidfTerm(
            term: t.term.substring(2),
            tf: t.tf,
            idf: t.idf,
            weight: t.weight,
          ),
        )
        .toList();

    return ClassificationOutput(
      inputText: text,
      preprocessedText: preprocessed,
      categoryName: best,
      probability: probability,
      isConfident: confident,
      probabilities: probabilities,
      terms: wordTerms,
      modelName: modelName,
      modelVersion: modelVersion,
    );
  }

  /// Klasifikasi satu barang. Bila tebakan barang kurang yakin, nama merchant
  /// (mis. "Apotek K24", "SPBU Pertamina") dipakai sebagai petunjuk tambahan.
  ClassificationOutput classifyItem(String itemName, {String? merchantName}) {
    final ClassificationOutput item = classify(itemName);
    if (item.isConfident) return item;

    final String merchant = (merchantName ?? '').trim();
    if (merchant.isEmpty) return item;

    final ClassificationOutput byMerchant = classify(merchant);
    if (!byMerchant.isConfident ||
        byMerchant.probability < merchantHintThreshold) {
      return item;
    }
    return item.copyWith(
      categoryName: byMerchant.categoryName,
      probability: byMerchant.probability * 0.85,
      isConfident: true,
    );
  }

  String _argMax(Map<String, double> values) {
    String? bestKey;
    double bestValue = double.negativeInfinity;
    values.forEach((String key, double value) {
      if (value > bestValue) {
        bestValue = value;
        bestKey = key;
      }
    });
    return bestKey ?? fallbackCategory;
  }

  /// Mengubah skor log menjadi probabilitas (stabil secara numerik).
  Map<String, double> _softmax(Map<String, double> scores) {
    if (scores.isEmpty) return <String, double>{};
    final double maxScore = scores.values.reduce(math.max);
    final Map<String, double> exps = scores.map(
      (String key, double value) =>
          MapEntry<String, double>(key, math.exp(value - maxScore)),
    );
    final double sum =
        exps.values.fold<double>(0, (double a, double b) => a + b);
    return exps.map(
      (String key, double value) => MapEntry<String, double>(key, value / sum),
    );
  }
}
