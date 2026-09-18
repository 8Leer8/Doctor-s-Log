import '../../../models/story_element.dart';
import '../../../models/reader_part.dart';
import 'reader_item.dart';

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
  // ── 1. Build the flat (ungrouped) item list, WITHOUT tracking any
  //       indices. We'll compute those later against the final list. ──

  final flat = <ReaderItem>[];
  bool endsWithTransition = false;
  bool endsWithEndMarker = false;

  if (lo == null) {
    flat.add(
      TransitionItem(
        previousTitle: null,
        currentTitle: readerParts[startAt].part.title,
        partIndexInList: startAt,
        forwardMissingReason: missingParts[startAt],
        isLoadingForward: loadingParts.contains(startAt),
      ),
    );
    endsWithTransition = true;
  } else {
    final int loValue = lo;
    final int hiValue = hi!;

    // Leading divider.
    flat.add(
      TransitionItem(
        previousTitle: loValue > 0 ? readerParts[loValue - 1].part.title : null,
        currentTitle: readerParts[loValue].part.title,
        partIndexInList: loValue,
        backwardMissingReason: loValue > 0 ? missingParts[loValue - 1] : null,
        isLoadingBackward: loValue > 0 && loadingParts.contains(loValue - 1),
      ),
    );

    int? lockedItemIndex;
    bool cascadeStopped = false;

    for (int i = loValue; i <= hiValue; i++) {
      if (i > loValue) {
        flat.add(
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
          flat.add(item);
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
            flat.add(item);
          }
          continue;
        }

        if (isPast) {
          continue;
        }

        final gateChoiceId = el.gateChoiceId;
        final lastVisible = flat.isNotEmpty ? flat.last : null;
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
            flat[lockedItemIndex] = lockedItem;
          } else {
            flat.add(lockedItem);
            lockedItemIndex = flat.length - 1;
          }
        }

        cascadeStopped = true;
        break;
      }

      if (cascadeStopped) break;
    }

    if (!cascadeStopped) {
      if (hiValue == readerParts.length - 1) {
        flat.add(EndOfChapterMarker());
        endsWithEndMarker = true;
      } else {
        flat.add(
          TransitionItem(
            previousTitle: readerParts[hiValue].part.title,
            currentTitle: readerParts[hiValue + 1].part.title,
            partIndexInList: hiValue + 1,
            forwardMissingReason: missingParts[hiValue + 1],
            isLoadingForward: loadingParts.contains(hiValue + 1),
          ),
        );
        endsWithTransition = true;
      }
    }
  }

  // ── 2. Grouping pass ──
  final grouped = _groupDialogue(flat);

  // ── 3. Compute all index maps against the FINAL grouped list ──

  final partListIndex = <int, int>{};
  final choiceListIndex = <String, int>{};

  for (int i = 0; i < grouped.length; i++) {
    final item = grouped[i];

    if (item is TransitionItem) {
      partListIndex[item.partIndexInList] = i;
    } else if (item is ContentItem) {
      final el = item.element;
      if (el is StoryChoiceElement) {
        choiceListIndex['${item.partIndexInList}-${el.id}'] = i;
      }
    }
  }

  // Leading divider is always the first item in the list (lo != null case)
  // or the only item (lo == null case). Grouping can't move a
  // TransitionItem, so this is stable.
  final int? leadingDividerListIndex =
      grouped.isNotEmpty && grouped.first is TransitionItem ? 0 : null;

  // Trailing divider / end marker is always last if present.
  final int? trailingDividerListIndex = endsWithTransition && grouped.isNotEmpty
      ? grouped.length - 1
      : null;

  final int? endMarkerListIndex = endsWithEndMarker && grouped.isNotEmpty
      ? grouped.length - 1
      : null;

  return VisibleItemsResult(
    items: grouped,
    partListIndex: partListIndex,
    choiceListIndex: choiceListIndex,
    endMarkerListIndex: endMarkerListIndex,
    leadingDividerListIndex: leadingDividerListIndex,
    trailingDividerListIndex: trailingDividerListIndex,
  );
}

/// Collapses consecutive ContentItems whose element is a
/// StoryLineElement with the same speaker. Single-line runs are kept
/// as plain ContentItem so isolated lines render exactly as before.
List<ReaderItem> _groupDialogue(List<ReaderItem> items) {
  final out = <ReaderItem>[];
  int i = 0;

  while (i < items.length) {
    final item = items[i];

    if (item is ContentItem && item.element is StoryLineElement) {
      final first = item.element as StoryLineElement;
      final speaker = first.speaker;
      final run = <StoryLineElement>[first];
      final partIndex = item.partIndexInList;
      final firstElementIndex = item.elementIndexInPart;

      int j = i + 1;
      while (j < items.length) {
        final next = items[j];
        if (next is! ContentItem) break;
        final el = next.element;
        if (el is! StoryLineElement) break;
        if (el.speaker != speaker) break;
        if (next.partIndexInList != partIndex) break;
        run.add(el);
        j++;
      }

      if (run.length == 1) {
        out.add(item);
      } else {
        out.add(
          DialogueGroupItem(
            speaker: speaker,
            lines: run,
            partIndexInList: partIndex,
            firstElementIndexInPart: firstElementIndex,
          ),
        );
      }

      i = j;
      continue;
    }

    out.add(item);
    i++;
  }

  return out;
}
