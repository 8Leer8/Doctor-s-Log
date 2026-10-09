import 'package:flutter/material.dart';
import '../../data/search/library_search_index.dart';

/// Search state shared between the AppShell (which hosts the search field in
/// the single top bar) and LibraryScreen (which shows the results and chips).
///
/// Owned by AppShell; LibraryScreen attaches the [LibrarySearchIndex] once
/// the chapter data has loaded.
class LibrarySearchController extends ChangeNotifier {
  final TextEditingController text = TextEditingController();
  final FocusNode focus = FocusNode();

  LibrarySearchIndex? _index;
  bool _searching = false;
  String _rawQuery = '';
  String _ghost = '';
  List<SearchSuggestion> _suggestions = const [];

  LibrarySearchController() {
    text.addListener(_onTextChanged);
    focus.addListener(_onFocusChanged);
  }

  LibrarySearchIndex? get index => _index;
  bool get searching => _searching;

  /// Exactly what is in the field (may have trailing spaces).
  String get rawQuery => _rawQuery;
  String get query => _rawQuery.trim();

  /// True when a non-empty query is actively filtering the Library.
  bool get filtering => _index != null && _searching && query.isNotEmpty;

  /// Cached — recomputed only when the text, focus or index changes.
  String get ghost => _ghost;
  List<SearchSuggestion> get suggestions => _suggestions;
  List<String> get hints => _index?.hints ?? const <String>[];

  void attachIndex(LibrarySearchIndex index) {
    _index = index;
    _recompute();
    notifyListeners();
  }

  void open() {
    if (_searching) return;
    _searching = true;
    _recompute();
    notifyListeners();
  }

  void close() {
    if (!_searching) return;
    focus.unfocus();
    text.clear();
    _searching = false;
    _rawQuery = '';
    _recompute();
    notifyListeners();
  }

  void acceptGhost() {
    if (_ghost.isEmpty) return;
    _setText(_rawQuery + _ghost);
  }

  void applySuggestion(SearchSuggestion s) {
    _setText(s.text);
    // Keywords keep the keyboard up so you can keep refining;
    // chapters / parts are "final", so reveal the results.
    if (s.kind != SuggestionKind.keyword) focus.unfocus();
  }

  void _setText(String value) {
    text.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  void _onTextChanged() {
    final raw = text.text;
    if (raw == _rawQuery) return; // selection-only change
    _rawQuery = raw;
    _recompute();
    notifyListeners();
  }

  void _onFocusChanged() {
    _recompute();
    notifyListeners();
  }

  void _recompute() {
    final index = _index;
    _ghost = (_searching && index != null) ? index.ghostFor(_rawQuery) : '';
    _suggestions = (_searching && index != null && focus.hasFocus)
        ? index.suggestionsFor(_rawQuery)
        : const <SearchSuggestion>[];
  }

  @override
  void dispose() {
    text.removeListener(_onTextChanged);
    focus.removeListener(_onFocusChanged);
    text.dispose();
    focus.dispose();
    super.dispose();
  }
}
