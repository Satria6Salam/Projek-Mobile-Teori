import '../data/models/shopping_plan_model.dart';
import '../data/repositories/shopping_plan_repository.dart';

/// Satu barang pada struk yang sudah disimpan (bahan pencocokan rencana).
class PurchasedLine {
  const PurchasedLine({
    required this.name,
    this.quantity = 1,
    required this.totalPrice,
  });

  final String name;
  final double quantity;
  final double totalPrice;
}

/// Pasangan barang rencana dengan barang pada struk.
class PlanMatch {
  const PlanMatch(
      {required this.plan, required this.line, required this.score});

  final ShoppingPlanModel plan;
  final PurchasedLine line;

  /// 0..1+; makin tinggi makin yakin.
  final double score;
}

/// Mengubah teks menjadi daftar kata yang sudah dinormalkan.
typedef Tokenizer = List<String> Function(String text);

/// Mencocokkan barang rencana belanja dengan barang pada struk.
///
/// Nama di struk sering disingkat ("TLR AYM NEGERI", "INDOMIE GRG SPCL"),
/// jadi kedua sisi dinormalkan dengan tokenizer yang sama dengan model AI
/// (singkatan diperluas, salah ketik dikoreksi). Sebuah rencana dianggap
/// terbeli bila kata-kata pada namanya muncul di nama barang struk:
/// - nama rencana 1-2 kata: semua kata harus ada;
/// - nama rencana 3 kata atau lebih: minimal 60% kata ada.
/// Setiap barang struk hanya dipakai untuk satu rencana, dan sebaliknya.
class ShoppingMatcher {
  ShoppingMatcher({Tokenizer? tokenizer})
      : _tokenizer = tokenizer ?? simpleTokens;

  final Tokenizer _tokenizer;

  static final RegExp _nonLetters = RegExp(r'[^a-z]+');

  /// Tokenizer dasar: huruf kecil, hanya huruf, minimal dua huruf.
  static List<String> simpleTokens(String text) {
    return text
        .toLowerCase()
        .split(_nonLetters)
        .where((String w) => w.length >= 2)
        .toList();
  }

  List<String> _tokens(String text) {
    final Set<String> result = <String>{
      ..._tokenizer(text),
      ...simpleTokens(text),
    };
    return result.toList();
  }

  List<PlanMatch> match(
    List<ShoppingPlanModel> plans,
    List<PurchasedLine> lines,
  ) {
    final List<List<String>> lineTokens =
        lines.map((PurchasedLine l) => _tokens(l.name)).toList();
    final List<PlanMatch> candidates = <PlanMatch>[];

    for (final ShoppingPlanModel plan in plans) {
      if (plan.isBought) continue;
      final List<String> planTokens = _tokens(plan.name);
      if (planTokens.isEmpty) continue;
      for (int i = 0; i < lines.length; i++) {
        final double? score = _score(planTokens, lineTokens[i]);
        if (score != null) {
          candidates.add(PlanMatch(plan: plan, line: lines[i], score: score));
        }
      }
    }

    // Pasangan terbaik dipilih lebih dulu; satu barang struk untuk satu rencana.
    candidates.sort((PlanMatch a, PlanMatch b) => b.score.compareTo(a.score));
    final Set<Object> usedPlans = <Object>{};
    final Set<PurchasedLine> usedLines = Set<PurchasedLine>.identity();
    final List<PlanMatch> result = <PlanMatch>[];
    for (final PlanMatch m in candidates) {
      final Object planKey = m.plan.id ?? m.plan;
      if (usedPlans.contains(planKey) || usedLines.contains(m.line)) continue;
      usedPlans.add(planKey);
      usedLines.add(m.line);
      result.add(m);
    }
    return result;
  }

  /// Skor kecocokan atau null bila tidak cocok.
  double? _score(List<String> plan, List<String> line) {
    if (line.isEmpty) return null;
    // Kata rencana yang dianggap "isi": abaikan kata satu-dua huruf.
    final List<String> words = plan.where((String w) => w.length >= 3).toList();
    final List<String> required = words.isEmpty ? plan : words;

    int hit = 0;
    for (final String w in required) {
      if (line.any((String t) => _sameWord(w, t))) hit++;
    }
    final double coverage = hit / required.length;
    final double needed = required.length <= 2 ? 1.0 : 0.6;
    if (coverage + 1e-9 < needed) return null;

    // Sedikit bonus bila nama struk juga banyak tercakup oleh rencana,
    // agar "Indomie goreng" memilih "INDOMIE GRG" daripada "INDOMIE SOTO".
    int back = 0;
    for (final String t in line) {
      if (required.any((String w) => _sameWord(w, t))) back++;
    }
    return coverage + 0.2 * (back / line.length);
  }

  /// [planWord] dari rencana, [receiptWord] dari struk.
  bool _sameWord(String planWord, String receiptWord) {
    if (planWord == receiptWord) return true;
    final int lp = planWord.length;
    final int lr = receiptWord.length;
    // Kata di struk boleh terpotong ("SUNLIG" untuk "sunlight"), tetapi kata
    // rencana tidak boleh cocok dengan kata struk yang lebih panjang
    // ("susu" bukan "susun").
    if (lr >= 4 && planWord.startsWith(receiptWord)) return true;
    if (lp >= 5 && lr >= 5 && (lp - lr).abs() <= 1) {
      return _oneEdit(planWord, receiptWord);
    }
    return false;
  }

  bool _oneEdit(String a, String b) {
    if (a.length == b.length) {
      int diff = 0;
      for (int i = 0; i < a.length; i++) {
        if (a.codeUnitAt(i) != b.codeUnitAt(i) && ++diff > 1) return false;
      }
      return diff == 1;
    }
    final String s = a.length < b.length ? a : b;
    final String l = a.length < b.length ? b : a;
    int i = 0;
    while (i < s.length && s.codeUnitAt(i) == l.codeUnitAt(i)) {
      i++;
    }
    return s.substring(i) == l.substring(i + 1);
  }
}

/// Rencana belanja: mencatat barang yang akan dibeli dan mencoretnya secara
/// otomatis saat struk belanja dipindai.
class ShoppingPlanService {
  ShoppingPlanService({
    required ShoppingPlanRepository repository,
    ShoppingMatcher? matcher,
  })  : _repository = repository,
        _matcher = matcher ?? ShoppingMatcher();

  final ShoppingPlanRepository _repository;
  final ShoppingMatcher _matcher;

  /// Barang rencana yang akan tercoret bila struk ini disimpan.
  Future<List<PlanMatch>> previewMatches(
    int userId,
    List<PurchasedLine> lines,
  ) async {
    final List<ShoppingPlanModel> pending =
        await _repository.getPending(userId);
    return _matcher.match(pending, lines);
  }

  /// Menandai rencana yang cocok dengan barang struk sebagai "sudah dibeli".
  /// Barang rencana yang tidak ada di struk tetap di daftar rencana.
  Future<List<PlanMatch>> markPurchasedFromReceipt({
    required int userId,
    required List<PurchasedLine> lines,
    required DateTime purchasedAt,
    int? transactionId,
  }) async {
    final List<PlanMatch> matches = await previewMatches(userId, lines);
    await _repository.updateAll(<ShoppingPlanModel>[
      for (final PlanMatch m in matches)
        m.plan.markBought(
          at: purchasedAt,
          transactionId: transactionId,
          boughtName: m.line.name,
          boughtPrice: m.line.totalPrice,
        ),
    ]);
    return matches;
  }
}
