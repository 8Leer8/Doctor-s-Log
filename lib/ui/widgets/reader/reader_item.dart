import '../../../models/story_element.dart';

abstract class ReaderItem {
  const ReaderItem();
}

class ContentItem extends ReaderItem {
  final StoryElement element;
  final int partIndexInList;
  final int elementIndexInPart;
  ContentItem(this.element, this.partIndexInList, this.elementIndexInPart);
}

/// A run of consecutive [StoryLineElement]s that share the same
/// [speaker] value (including `null` for narration) collapsed into a
/// single visual block.
///
/// Produced by [buildReaderVisibleItems] as a presentation-only pass
/// after choice-gating. The underlying per-line [StoryElement]s are
/// preserved in [lines] so nothing about the parser's data model
/// changes.
///
/// [firstElementIndexInPart] is the [elementIndexInPart] of `lines[0]`
/// within its original part — used by the reader for resume-position
/// persistence, since the group replaces what used to be a run of
/// separate [ContentItem]s that each carried their own index.
class DialogueGroupItem extends ReaderItem {
  final String? speaker;
  final List<StoryLineElement> lines;
  final int partIndexInList;
  final int firstElementIndexInPart;

  const DialogueGroupItem({
    required this.speaker,
    required this.lines,
    required this.partIndexInList,
    required this.firstElementIndexInPart,
  });
}

class TransitionItem extends ReaderItem {
  final String? previousTitle;
  final String currentTitle;
  final int partIndexInList;
  final String? backwardMissingReason;
  final String? forwardMissingReason;
  final bool isLoadingBackward;
  final bool isLoadingForward;

  TransitionItem({
    required this.previousTitle,
    required this.currentTitle,
    required this.partIndexInList,
    this.backwardMissingReason,
    this.forwardMissingReason,
    this.isLoadingBackward = false,
    this.isLoadingForward = false,
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
