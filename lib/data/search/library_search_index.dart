import '../../models/chapter_preview.dart';
import '../../utils/act_type_formatter.dart';

enum SuggestionKind { chapter, keyword, part }

class SearchSuggestion {
  /// Text that replaces the search field when the suggestion is tapped.
  final String text;

  /// Small secondary label, e.g. "in Evil Time Part 1".
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
  final List<String> parts; // lowercase part titles

  const _Doc({
    required this.chapter,
    required this.order,
    required this.title,
    required this.label,
    required this.desc,
    required this.parts,
  });
}

/// In-memory search over chapter titles, part titles and the bundled
/// descriptions. Everything is precomputed once, so searching on every
/// keystroke is cheap.
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
  static final RegExp _sentenceSplit = RegExp(r'(?<=[.!?])\s+');
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
      for (final part in doc.chapter.parts) {
        _addWords(part.title);
      }
    }
    for (final desc in descriptions.values) {
      _addProperNouns(desc);
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
          parts: chapters[i].parts.map((p) => p.title.toLowerCase()).toList(),
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

  /// Collects capitalised words that are NOT the first word of a sentence,
  /// which is a cheap way to pick up names and places (Amiya, Lungmen...)
  /// without also picking up "Beneath", "Guided", etc.
  void _addProperNouns(String text) {
    for (final sentence in text.split(_sentenceSplit)) {
      final words = _wordRe
          .allMatches(sentence)
          .map((m) => m.group(0)!)
          .toList();
      for (int i = 1; i < words.length; i++) {
        final w = words[i];
        final first = w[0];
        if (first == first.toUpperCase()) {
          _addWord(w);
        }
      }
    }
  }

  void _buildStartSuggestions() {
    final keywords = _vocabCount.keys.where((k) => k.length >= 5).toList()
      ..sort((a, b) {
        final c = _vocabCount[b]!.compareTo(_vocabCount[a]!);
        return c != 0 ? c : a.compareTo(b);
      });
    final kw = keywords
        .take(5)
        .map(
          (k) => SearchSuggestion(
            text: _vocabDisplay[k]!,
            kind: SuggestionKind.keyword,
          ),
        )
        .toList();

    final ti = <SearchSuggestion>[];
    final usedIdx = <int>{};
    for (int i = 0; i < 3 && _titles.isNotEmpty; i++) {
      final idx = _titles.length * (2 * i + 1) ~/ 6;
      if (usedIdx.add(idx)) {
        ti.add(
          SearchSuggestion(
            text: _titles[idx].display,
            kind: SuggestionKind.chapter,
          ),
        );
      }
    }

    final n = kw.length > ti.length ? kw.length : ti.length;
    for (int i = 0; i < n; i++) {
      if (i < kw.length) startSuggestions.add(kw[i]);
      if (i < ti.length) startSuggestions.add(ti[i]);
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
      } else if (d.parts.any((p) => p.contains(t))) {
        s = 30;
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

  /// The faded "rest of the word" shown after what the user has typed.
  /// Empty string when there is nothing sensible to complete.
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

    // 2) Last word is the start of a known keyword.
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

  List<SearchSuggestion> suggestionsFor(String raw, {int limit = 8}) {
    final q = raw.trim().toLowerCase();
    if (q.isEmpty) return startSuggestions;

    final tokens = _tokens(q);
    final last = tokens.last;
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
      if (added >= 3) break;
      if (seen.add(d.title)) {
        out.add(
          SearchSuggestion(text: d.chapter.title, kind: SuggestionKind.chapter),
        );
        added++;
      }
    }

    // Keywords (names / places) starting with the last typed word.
    if (last.length >= 2 && !raw.endsWith(' ')) {
      final words =
          _vocabCount.keys
              .where((w) => w.startsWith(last) && w != last)
              .toList()
            ..sort((a, b) {
              final c = _vocabCount[b]!.compareTo(_vocabCount[a]!);
              return c != 0 ? c : a.length.compareTo(b.length);
            });
      final trimmed = raw.trim();
      final prefix = trimmed.substring(0, trimmed.lastIndexOf(' ') + 1);
      added = 0;
      for (final w in words) {
        if (added >= 3) break;
        final text = '$prefix${_vocabDisplay[w]}';
        if (seen.add(text.toLowerCase())) {
          out.add(SearchSuggestion(text: text, kind: SuggestionKind.keyword));
          added++;
        }
      }
    }

    // Part titles containing every typed word.
    final partDisplay = <String, String>{};
    final partChapter = <String, String>{};
    final partCount = <String, int>{};
    for (final d in _allDocs) {
      for (int j = 0; j < d.parts.length; j++) {
        final lower = d.parts[j];
        if (tokens.every((t) => lower.contains(t))) {
          partDisplay.putIfAbsent(lower, () => d.chapter.parts[j].title);
          partChapter.putIfAbsent(lower, () => d.chapter.title);
          partCount[lower] = (partCount[lower] ?? 0) + 1;
        }
      }
    }
    added = 0;
    for (final e in partDisplay.entries) {
      if (added >= 3 || out.length >= limit) break;
      if (!seen.add(e.key)) continue;
      final count = partCount[e.key]!;
      out.add(
        SearchSuggestion(
          text: e.value,
          kind: SuggestionKind.part,
          context: count == 1
              ? 'in ${partChapter[e.key]}'
              : 'in $count chapters',
        ),
      );
      added++;
    }

    return out.take(limit).toList();
  }
}
