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

/// A scene-change divider. Emitted by the parser whenever a
/// `[Background(image="...")]` value changes mid-part.
///
/// [elementIndexInPart] is a bookkeeping index used only for
/// resume-position tracking — it is never rendered to the user.
///
/// Scene breaks are:
///   - never gated (no choice/predicate)
///   - never TOC targets
///   - never valid resume targets (resume always lands on the next
///     dialogue line instead)
///   - always rendered as a plain inline divider
class SceneBreakItem extends ReaderItem {
  final int partIndexInList;
  final int elementIndexInPart;

  const SceneBreakItem({
    required this.partIndexInList,
    required this.elementIndexInPart,
  });
}

class TransitionItem extends ReaderItem {
  final String? previousTitle;
  final String currentTitle;
  final int partIndexInList;
  final String? backwardMissingReason;
  final String? forwardMissingReason;
  final bool isPendingBackward;
  final bool isPendingForward;

  TransitionItem({
    required this.previousTitle,
    required this.currentTitle,
    required this.partIndexInList,
    this.backwardMissingReason,
    this.forwardMissingReason,
    this.isPendingBackward = false,
    this.isPendingForward = false,
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
