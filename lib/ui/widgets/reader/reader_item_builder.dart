import 'package:flutter/material.dart';
import '../../../models/story_element.dart';
import '../../../models/reader_settings.dart';
import 'reader_item.dart';
import '../chapter_transition_widget.dart';
import 'end_of_chapter_widget.dart';
import 'locked_section_widget.dart';
import 'story_line_widget.dart';
import 'choice_widget.dart';
import '../chapter_transition_widget.dart' show ChapterTransitionWidget;

/// Renders a single ReaderItem into its widget. Stateless — all state
/// lives in the parent ReaderScreen.
class ReaderItemBuilder {
  final ReaderSettings settings;
  final Map<String, String> selections;
  final Map<int, String> missingParts;
  final Set<int> loadingParts;
  final void Function(int partIndexInList) onRetryBackward;
  final void Function(int partIndexInList) onRetryForward;
  final void Function(int partIndexInList, int choiceId) onGoToChoice;
  final void Function(int partIndexInList, int choiceId, String value)
  onChoiceSelected;

  const ReaderItemBuilder({
    required this.settings,
    required this.selections,
    required this.missingParts,
    required this.loadingParts,
    required this.onRetryBackward,
    required this.onRetryForward,
    required this.onGoToChoice,
    required this.onChoiceSelected,
  });

  Widget build(BuildContext context, ReaderItem item) {
    if (item is TransitionItem) {
      return ChapterTransitionWidget(
        previousTitle: item.previousTitle,
        currentTitle: item.currentTitle,
        settings: settings,
        backwardMissingReason: item.backwardMissingReason,
        forwardMissingReason: item.forwardMissingReason,
        isLoadingBackward: item.isLoadingBackward,
        isLoadingForward: item.isLoadingForward,
        onRetryBackward: item.backwardMissingReason != null
            ? () => onRetryBackward(item.partIndexInList - 1)
            : null,
        onRetryForward: item.forwardMissingReason != null
            ? () => onRetryForward(item.partIndexInList)
            : null,
      );
    }

    if (item is EndOfChapterMarker) {
      return EndOfChapterWidget(settings: settings);
    }

    if (item is LockedSectionItem) {
      return LockedSectionWidget(
        settings: settings,
        onGoToChoice: () =>
            onGoToChoice(item.partIndexInList, item.gateChoiceId),
      );
    }

    if (item is ContentItem) {
      final el = item.element;
      final selectionKey = '${item.partIndexInList}-';
      if (el is StoryChoiceElement) {
        return ChoiceWidget(
          element: el,
          selectedValue: selections['$selectionKey${el.id}'],
          onSelect: (value) =>
              onChoiceSelected(item.partIndexInList, el.id, value),
          settings: settings,
        );
      }
      if (el is StoryLineElement) {
        return StoryLineWidget(line: el, settings: settings);
      }
      return const SizedBox.shrink();
    }

    return const SizedBox.shrink();
  }
}
