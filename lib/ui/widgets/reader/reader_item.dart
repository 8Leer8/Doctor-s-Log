import '../../../models/story_element.dart';

abstract class ReaderItem {
  const ReaderItem();
}

class ContentItem extends ReaderItem {
  final StoryElement element;
  final int partIndexInList;
  final int
  elementIndexInPart; // position within this part's own raw parsed list — stable across sessions
  ContentItem(this.element, this.partIndexInList, this.elementIndexInPart);
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

class LockedSectionItem extends ReaderItem {
  final int partIndexInList;
  final int gateChoiceId;
  LockedSectionItem({
    required this.partIndexInList,
    required this.gateChoiceId,
  });
}
