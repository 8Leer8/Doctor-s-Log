import '../../../models/story_element.dart';

/// Internal list-item model used by ReaderScreen to interleave
/// story content, chapter-transition markers, and the end-of-chapter card.
abstract class ReaderItem {}

class ContentItem extends ReaderItem {
  final StoryElement element;
  final int partIndexInList;
  ContentItem(this.element, this.partIndexInList);
}

class TransitionItem extends ReaderItem {
  final String? previousTitle;
  final String currentTitle;
  final int partIndexInList;
  TransitionItem({
    required this.previousTitle,
    required this.currentTitle,
    required this.partIndexInList,
  });
}

class EndOfChapterMarker extends ReaderItem {}