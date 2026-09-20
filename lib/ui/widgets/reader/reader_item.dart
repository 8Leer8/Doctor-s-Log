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

  final String? speakerPortraitId;

  const DialogueGroupItem({
    required this.speaker,
    required this.lines,
    required this.partIndexInList,
    required this.firstElementIndexInPart,
    this.speakerPortraitId,
  });
}

class SceneBreakItem extends ReaderItem {
  final int partIndexInList;
  final int elementIndexInPart;

  /// Raw background image ID (e.g. "72_g15_wideunder").
  final String backgroundImageId;

  const SceneBreakItem({
    required this.partIndexInList,
    required this.elementIndexInPart,
    required this.backgroundImageId,
  });
}

class SceneImageItem extends ReaderItem {
  final int partIndexInList;
  final int elementIndexInPart;

  /// Raw CG image ID (e.g. "72_i10_1").
  final String imageId;

  const SceneImageItem({
    required this.partIndexInList,
    required this.elementIndexInPart,
    required this.imageId,
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
