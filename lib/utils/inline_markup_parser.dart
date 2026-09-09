import 'package:flutter/material.dart';

/// Strips non-italic inline tags and converts <i>...</i> spans into
/// styled TextSpans instead of leaking raw tag text.
List<TextSpan> buildRichSpans(String rawText, TextStyle baseStyle) {
  final cleaned = rawText.replaceAll(RegExp(r'<(?!/?i\s*>)[^>]*>'), '');

  final spans = <TextSpan>[];
  final tagRegex = RegExp(r'<(/?)\s*i\s*>', caseSensitive: false);
  int cursor = 0;
  bool italic = false;

  for (final match in tagRegex.allMatches(cleaned)) {
    if (match.start > cursor) {
      final segment = cleaned.substring(cursor, match.start);
      spans.add(TextSpan(
        text: segment,
        style: italic ? baseStyle.copyWith(fontStyle: FontStyle.italic) : baseStyle,
      ));
    }
    italic = match.group(1) != '/';
    cursor = match.end;
  }
  if (cursor < cleaned.length) {
    final segment = cleaned.substring(cursor);
    spans.add(TextSpan(
      text: segment,
      style: italic ? baseStyle.copyWith(fontStyle: FontStyle.italic) : baseStyle,
    ));
  }
  return spans;
}