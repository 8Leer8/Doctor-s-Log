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

/// A divider in the reading flow between two parts.
///
/// [partIndexInList] identifies the part being "entered" by this
/// transition — its title is shown as [currentTitle]. A single transition
/// can independently report a loading/error state for:
///   * the part immediately *before* it (backward — shown in the
///     PREVIOUS/top section), and/or
///   * the part this transition represents going forward, i.e. either the
///     part being entered (when it's still loading/missing) or the part
///     right after the currently loaded window (forward — shown in the
///     CURRENT/bottom section).
///
/// Both slots may be set at once, only one may be set, or neither — the
/// widget renders whichever slots are non-null. This lets one divider show
/// two fully independent error states at the same time.
class TransitionItem extends ReaderItem {
  final String? previousTitle;
  final String currentTitle;
  final int partIndexInList;

  /// Missing reason ('no_internet' | 'unknown') for the part immediately
  /// before this transition, or null if that part is loaded, not
  /// applicable, or hasn't been attempted/hasn't failed.
  final String? backwardMissingReason;

  /// Missing reason for the part this transition represents going
  /// forward (see class doc).
  final String? forwardMissingReason;

  /// True while the backward-adjacent part is being fetched.
  final bool isLoadingBackward;

  /// True while the forward-adjacent part is being fetched.
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
