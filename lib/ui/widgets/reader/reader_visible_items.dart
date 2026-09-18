import '../../../models/story_element.dart';
import '../../../models/reader_part.dart';
import 'reader_item.dart';

/// Result of building the visible item list. Holds the list itself plus
/// the index maps the reader screen needs to keep its scroll bookkeeping
/// in sync (part dividers, choice elements, end marker, leading/trailing
/// dividers).
class VisibleItemsResult {
  final List<ReaderItem> items;
  final Map<int, int> partListIndex;
  final Map<String, int> choiceListIndex;
  final int? endMarkerListIndex;
  final int? leadingDividerListIndex;
  final int? trailingDividerListIndex;

  VisibleItemsResult({
    required this.items,
    required this.partListIndex,
    required this.choiceListIndex,
    required this.endMarkerListIndex,
    required this.leadingDividerListIndex,
    required this.trailingDividerListIndex,
  });
}

/// Builds the currently visible item list from the loaded-window state.
///
/// At most two "attempt" dividers exist at any time: a leading divider
/// (entry into the first loaded part, carrying a backward error/loading
/// state for the part before it) and a trailing divider (carrying a
/// forward error/loading state for the part after the loaded window).
/// Between two already-loaded parts, only a plain divider (no error
/// slots) is shown — never a duplicate.
VisibleItemsResult buildReaderVisibleItems({
  required List<ReaderPart> readerParts,
  required int startAt,
  required int? lo,
  required int? hi,
  required Set<int> loadedParts,
  required Map<int, String> missingParts,
  required Set<int> loadingParts,
  required Map<int, List<StoryElement>> contentCache,
  required Map<String, String> selections,
  required int frontierPartIndexInList,
}) {
  final visible = <ReaderItem>[];
  final partIndexMap = <int, int>{};
  final choiceIndexMap = <String, int>{};

  int? endMarkerListIndex;
  int? leadingDividerListIndex;
  int? trailingDividerListIndex;

  if (lo == null) {
    // Nothing loaded yet: a single forward-flagged divider for startAt,
    // no backward slot.
    partIndexMap[startAt] = visible.length;
    visible.add(
      TransitionItem(
        previousTitle: null,
        currentTitle: readerParts[startAt].part.title,
        partIndexInList: startAt,
        forwardMissingReason: missingParts[startAt],
        isLoadingForward: loadingParts.contains(startAt),
      ),
    );
    trailingDividerListIndex = visible.length - 1;

    return VisibleItemsResult(
      items: visible,
      partListIndex: partIndexMap,
      choiceListIndex: choiceIndexMap,
      endMarkerListIndex: null,
      leadingDividerListIndex: null,
      trailingDividerListIndex: trailingDividerListIndex,
    );
  }

  final int loValue = lo;
  final int hiValue = hi!;

  // Leading divider: entry into `lo`. May carry a backward error/loading
  // state for part lo-1.
  partIndexMap[loValue] = visible.length;
  visible.add(
    TransitionItem(
      previousTitle: loValue > 0 ? readerParts[loValue - 1].part.title : null,
      currentTitle: readerParts[loValue].part.title,
      partIndexInList: loValue,
      backwardMissingReason: loValue > 0 ? missingParts[loValue - 1] : null,
      isLoadingBackward: loValue > 0 && loadingParts.contains(loValue - 1),
    ),
  );
  leadingDividerListIndex = visible.length - 1;

  int? lockedItemIndex;
  bool cascadeStopped = false;

  for (int i = loValue; i <= hiValue; i++) {
    if (i > loValue) {
      // Plain boundary between two already-loaded parts.
      partIndexMap[i] = visible.length;
      visible.add(
        TransitionItem(
          previousTitle: readerParts[i - 1].part.title,
          currentTitle: readerParts[i].part.title,
          partIndexInList: i,
        ),
      );
      lockedItemIndex = null;
    }

    final elements = contentCache[i] ?? const <StoryElement>[];
    final isPast = i < frontierPartIndexInList;

    for (int e = 0; e < elements.length; e++) {
      final el = elements[e];
      final item = ContentItem(el, i, e);

      if (el.requiredValue == null) {
        lockedItemIndex = null;
        visible.add(item);
        if (el is StoryChoiceElement) {
          choiceIndexMap['$i-${el.id}'] = visible.length - 1;
        }
        continue;
      }

      final key = '$i-${el.gateChoiceId}';
      final chosen = selections[key];

      if (chosen != null) {
        final matches = el.requiredValue!
            .split(';')
            .map((s) => s.trim())
            .contains(chosen);
        if (matches) {
          lockedItemIndex = null;
          visible.add(item);
          if (el is StoryChoiceElement) {
            choiceIndexMap['$i-${el.id}'] = visible.length - 1;
          }
        }
        continue;
      }

      if (isPast) {
        continue;
      }

      final gateChoiceId = el.gateChoiceId;
      final lastVisible = visible.isNotEmpty ? visible.last : null;
      final immediatelyAfterOwnChoice =
          lastVisible is ContentItem &&
          lastVisible.element is StoryChoiceElement &&
          (lastVisible.element as StoryChoiceElement).id == gateChoiceId;

      if (!immediatelyAfterOwnChoice) {
        final lockedItem = LockedSectionItem(
          partIndexInList: i,
          gateChoiceId: gateChoiceId!,
        );
        if (lockedItemIndex != null) {
          visible[lockedItemIndex] = lockedItem;
        } else {
          visible.add(lockedItem);
          lockedItemIndex = visible.length - 1;
        }
      }

      cascadeStopped = true;
      break;
    }

    if (cascadeStopped) break;
  }

  if (!cascadeStopped) {
    if (hiValue == readerParts.length - 1) {
      visible.add(EndOfChapterMarker());
      endMarkerListIndex = visible.length - 1;
    } else {
      // Trailing divider: attempt into hi+1.
      partIndexMap[hiValue + 1] = visible.length;
      visible.add(
        TransitionItem(
          previousTitle: readerParts[hiValue].part.title,
          currentTitle: readerParts[hiValue + 1].part.title,
          partIndexInList: hiValue + 1,
          forwardMissingReason: missingParts[hiValue + 1],
          isLoadingForward: loadingParts.contains(hiValue + 1),
        ),
      );
      trailingDividerListIndex = visible.length - 1;
    }
  }

  return VisibleItemsResult(
    items: visible,
    partListIndex: partIndexMap,
    choiceListIndex: choiceIndexMap,
    endMarkerListIndex: endMarkerListIndex,
    leadingDividerListIndex: leadingDividerListIndex,
    trailingDividerListIndex: trailingDividerListIndex,
  );
}
