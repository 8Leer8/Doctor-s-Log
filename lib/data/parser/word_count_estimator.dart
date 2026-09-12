class WordCountEstimator {
  static final RegExp _tagRegex = RegExp(r'\[[^\]]*\]');
  static final RegExp _inlineTagRegex = RegExp(r'<[^>]*>');

  /// Strips stage-direction tags and inline markup, then counts real words.
  static int countWords(String raw) {
    final stripped = raw.replaceAll(_tagRegex, ' ').replaceAll(_inlineTagRegex, ' ');
    final words = stripped.split(RegExp(r'\s+')).where((w) => w.trim().isNotEmpty);
    return words.length;
  }

  /// Average adult silent reading speed in English is commonly cited around
  /// 200–250 words per minute; 200 is used here as a conservative estimate.
  static int estimateMinutes(int wordCount, {int wordsPerMinute = 200}) {
    if (wordCount <= 0) return 0;
    return (wordCount / wordsPerMinute).ceil();
  }
}