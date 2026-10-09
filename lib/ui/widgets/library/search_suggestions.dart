import 'package:flutter/material.dart';
import '../../../data/search/library_search_index.dart';
import '../../../theme/app_theme.dart';

/// Horizontal row of tappable clue chips (chapters, keywords, part titles).
/// Collapses to zero height when there is nothing to suggest.
class SearchSuggestions extends StatelessWidget {
  static final RegExp _whitespace = RegExp(r'\s+');

  final List<SearchSuggestion> suggestions;
  final String query;

  /// True when the field is empty — adds a small "TRY" label up front.
  final bool isStart;
  final ValueChanged<SearchSuggestion> onTap;

  const SearchSuggestions({
    super.key,
    required this.suggestions,
    required this.query,
    required this.isStart,
    required this.onTap,
  });

  IconData _icon(SuggestionKind kind) => switch (kind) {
    SuggestionKind.chapter => Icons.menu_book_outlined,
    SuggestionKind.keyword => Icons.tag,
    SuggestionKind.part => Icons.subdirectory_arrow_right,
  };

  List<TextSpan> _highlight(String text) {
    final lower = text.toLowerCase();
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [TextSpan(text: text)];

    String? needle;
    if (lower.contains(q)) {
      needle = q;
    } else {
      final lastToken = q.split(_whitespace).last;
      if (lastToken.isNotEmpty && lower.contains(lastToken)) {
        needle = lastToken;
      }
    }
    if (needle == null) return [TextSpan(text: text)];

    final i = lower.indexOf(needle);
    return [
      TextSpan(text: text.substring(0, i)),
      TextSpan(
        text: text.substring(i, i + needle.length),
        style: const TextStyle(
          color: AppColors.amber,
          fontWeight: FontWeight.w700,
        ),
      ),
      TextSpan(text: text.substring(i + needle.length)),
    ];
  }

  Widget _chip(SearchSuggestion s) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ClipPath(
        clipper: CutCornerClipper(cut: 6),
        child: Material(
          color: AppColors.surface,
          child: InkWell(
            onTap: () => onTap(s),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _icon(s.kind),
                      size: 13,
                      color: AppColors.amber.withValues(alpha: 0.85),
                    ),
                    const SizedBox(width: 6),
                    Text.rich(
                      TextSpan(
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textPrimary,
                        ),
                        children: _highlight(s.text),
                      ),
                    ),
                    if (s.context != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        s.context!,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.coldGray,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: suggestions.isEmpty
          ? const SizedBox(width: double.infinity, height: 0)
          : SizedBox(
              height: 46,
              width: double.infinity,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                children: [
                  if (isStart)
                    const Padding(
                      padding: EdgeInsets.only(right: 10),
                      child: Center(
                        child: Text(
                          'TRY',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.4,
                            color: AppColors.coldGray,
                          ),
                        ),
                      ),
                    ),
                  for (final s in suggestions)
                    KeyedSubtree(
                      key: ValueKey('${s.kind.name}:${s.text}'),
                      child: _chip(s),
                    ),
                ],
              ),
            ),
    );
  }
}
