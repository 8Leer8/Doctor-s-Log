import '../../models/chapter_preview.dart';
import '../../utils/act_type_formatter.dart';

enum SuggestionKind { chapter, keyword, part }

class SearchSuggestion {
  /// Text that replaces the search field when the suggestion is tapped.
  final String text;

  /// Small secondary label.
  final String? context;
  final SuggestionKind kind;

  const SearchSuggestion({
    required this.text,
    required this.kind,
    this.context,
  });
}

class _Doc {
  final ChapterPreview chapter;
  final int order;
  final String title; // lowercase
  final String label; // lowercase, e.g. "chapter 3" / "event story"
  final String desc; // lowercase

  const _Doc({
    required this.chapter,
    required this.order,
    required this.title,
    required this.label,
    required this.desc,
  });
}

/// In-memory search over CHAPTERS only: chapter title, chapter label
/// ("chapter 3", "event story") and the bundled chapter description. Part
/// titles inside a chapter are not searched. Everything is precomputed once,
/// so searching on every keystroke is cheap.
class LibrarySearchIndex {
  static const Set<String> _stopWords = {
    'part',
    'with',
    'from',
    'that',
    'this',
    'their',
    'they',
    'them',
    'then',
    'than',
    'into',
    'over',
    'after',
    'while',
    'when',
    'where',
    'what',
    'which',
    'also',
    'have',
    'been',
    'were',
    'will',
  };

  static final RegExp _wordRe = RegExp(r"[A-Za-z][A-Za-z'’]+");
  static final RegExp _whitespace = RegExp(r'\s+');

  final List<_Doc> _mainDocs;
  final List<_Doc> _sideDocs;
  final List<_Doc> _vignetteDocs;
  late final List<_Doc> _allDocs = [
    ..._mainDocs,
    ..._sideDocs,
    ..._vignetteDocs,
  ];

  final Map<String, String> _vocabDisplay = {};
  final Map<String, int> _vocabCount = {};
  final List<({String lower, String display})> _titles = [];

  /// Shown when the field is empty (and used for the rotating hint).
  final List<SearchSuggestion> startSuggestions = [];
  final List<String> hints = [];

  LibrarySearchIndex({
    required List<ChapterPreview> main,
    required List<ChapterPreview> side,
    required List<ChapterPreview> vignettes,
    required Map<String, String> descriptions,
  }) : _mainDocs = _buildDocs(main, descriptions),
       _sideDocs = _buildDocs(side, descriptions),
       _vignetteDocs = _buildDocs(vignettes, descriptions) {
    for (final doc in _allDocs) {
      _titles.add((lower: doc.title, display: doc.chapter.title));
      _addWords(doc.chapter.title);
    }
    _buildStartSuggestions();
  }

  static List<_Doc> _buildDocs(
    List<ChapterPreview> chapters,
    Map<String, String> descriptions,
  ) {
    return [
      for (int i = 0; i < chapters.length; i++)
        _Doc(
          chapter: chapters[i],
          order: i,
          title: chapters[i].title.toLowerCase(),
          label: formatChapterCardLabel(
            chapters[i].number,
            chapters[i].subtitle,
          ).toLowerCase(),
          desc: (descriptions[chapters[i].number] ?? '').toLowerCase(),
        ),
    ];
  }

  // ---------------------------------------------------------------- vocab

  void _addWord(String raw) {
    var w = raw;
    if (w.endsWith("'s") || w.endsWith('’s')) {
      w = w.substring(0, w.length - 2);
    }
    if (w.length < 4) return;
    final lower = w.toLowerCase();
    if (_stopWords.contains(lower)) return;
    _vocabDisplay.putIfAbsent(lower, () => w[0].toUpperCase() + w.substring(1));
    _vocabCount[lower] = (_vocabCount[lower] ?? 0) + 1;
  }

  void _addWords(String text) {
    for (final m in _wordRe.allMatches(text)) {
      _addWord(m.group(0)!);
    }
  }

  /// The "TRY" chips and the rotating hint: chapter titles only, spread
  /// evenly across Main Theme, Side Stories and Vignettes.
  void _buildStartSuggestions() {
    if (_titles.isEmpty) return;
    const count = 6;
    final used = <int>{};
    for (int i = 0; i < count; i++) {
      final idx = _titles.length * (2 * i + 1) ~/ (2 * count);
      if (used.add(idx)) {
        startSuggestions.add(
          SearchSuggestion(
            text: _titles[idx].display,
            kind: SuggestionKind.chapter,
          ),
        );
      }
    }
    hints.addAll(startSuggestions.map((s) => s.text));
  }

  // --------------------------------------------------------------- search

  static List<String> _tokens(String query) => query
      .toLowerCase()
      .split(_whitespace)
      .where((t) => t.isNotEmpty)
      .toList();

  static bool _wordStartsWith(String text, String token) =>
      text.startsWith(token) || text.contains(' $token');

  int _score(_Doc d, List<String> tokens, String phrase) {
    var total = 0;
    for (final t in tokens) {
      int s;
      if (_wordStartsWith(d.title, t)) {
        s = 100;
      } else if (d.title.contains(t)) {
        s = 60;
      } else if (d.label.contains(t)) {
        s = 40;
      } else if (d.desc.contains(t)) {
        s = 10;
      } else {
        return 0; // every token must match somewhere
      }
      total += s;
    }
    if (d.title.contains(phrase)) total += 50;
    return total;
  }

  List<ChapterPreview> _search(List<_Doc> docs, String query) {
    final tokens = _tokens(query);
    if (tokens.isEmpty) return [for (final d in docs) d.chapter];
    final phrase = tokens.join(' ');

    final scored = <(_Doc, int)>[];
    for (final d in docs) {
      final s = _score(d, tokens, phrase);
      if (s > 0) scored.add((d, s));
    }
    scored.sort((a, b) {
      final c = b.$2.compareTo(a.$2);
      return c != 0 ? c : a.$1.order.compareTo(b.$1.order);
    });
    return [for (final s in scored) s.$1.chapter];
  }

  List<ChapterPreview> searchMain(String query) => _search(_mainDocs, query);
  List<ChapterPreview> searchSide(String query) => _search(_sideDocs, query);
  List<ChapterPreview> searchVignettes(String query) =>
      _search(_vignetteDocs, query);

  // ---------------------------------------------------------------- ghost

  /// The faded "rest of the word" shown after what the user has typed,
  /// completed from chapter titles only. Empty string when there is nothing
  /// sensible to complete.
  String ghostFor(String raw) {
    if (raw.trim().isEmpty || raw.endsWith(' ')) return '';
    final lower = raw.toLowerCase();

    // 1) Whole query is the start of a chapter title.
    for (final t in _titles) {
      if (t.lower.length > lower.length &&
          t.display.length >= lower.length &&
          t.lower.startsWith(lower)) {
        return t.display.substring(lower.length);
      }
    }

    // 2) Last word is the start of a word used in a chapter title.
    final token = raw.substring(raw.lastIndexOf(' ') + 1).toLowerCase();
    if (token.length < 2) return '';

    String? best;
    var bestCount = -1;
    for (final e in _vocabCount.entries) {
      final word = e.key;
      if (word.length > token.length && word.startsWith(token)) {
        final better =
            e.value > bestCount ||
            (e.value == bestCount && best != null && word.length < best.length);
        if (better) {
          best = word;
          bestCount = e.value;
        }
      }
    }
    if (best == null) return '';
    return _vocabDisplay[best]!.substring(token.length);
  }

  // ---------------------------------------------------------- suggestions

  /// Chapter titles only (no keywords, no part titles).
  List<SearchSuggestion> suggestionsFor(String raw, {int limit = 8}) {
    final q = raw.trim().toLowerCase();
    if (q.isEmpty) return startSuggestions;

    final tokens = _tokens(q);
    final seen = <String>{q};
    final out = <SearchSuggestion>[];

    // Chapters whose title contains every typed word.
    final chapterHits = _allDocs
        .where((d) => tokens.every((t) => d.title.contains(t)))
        .toList();
    chapterHits.sort((a, b) {
      final sa = a.title.startsWith(q) ? 0 : 1;
      final sb = b.title.startsWith(q) ? 0 : 1;
      return sa != sb ? sa.compareTo(sb) : a.order.compareTo(b.order);
    });
    var added = 0;
    for (final d in chapterHits) {
      if (added >= limit) break;
      if (seen.add(d.title)) {
        out.add(
          SearchSuggestion(text: d.chapter.title, kind: SuggestionKind.chapter),
        );
        added++;
      }
    }

    return out.take(limit).toList();
  }
}
