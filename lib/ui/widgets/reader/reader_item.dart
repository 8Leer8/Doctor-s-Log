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

class TransitionItem extends ReaderItem {
  final String? previousTitle;
  final String currentTitle;
  final int partIndexInList;

  /// The reason the part immediately before this transition failed to
  /// load ('no_internet' | 'unknown'), or null if it's loaded / not
  /// applicable / still pending.
  final String? backwardMissingReason;

  /// Same, for the part this transition represents going forward.
  final String? forwardMissingReason;

  /// True while the backward-adjacent part is being fetched AND we're
  /// past the initial "settle" window. Renders an orange divider with
  /// no error text.
  final bool isPendingBackward;

  /// Same for the forward-adjacent part.
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
