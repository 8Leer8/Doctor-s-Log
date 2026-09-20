import 'package:flutter/material.dart';
import '../../../models/story_element.dart';
import '../../../models/reader_settings.dart';
import '../../../utils/asset_url_resolver.dart';
import '../chapter_transition_widget.dart';
import 'choice_widget.dart';
import 'dialogue_group_widget.dart';
import 'end_of_chapter_widget.dart';
import 'image_modal.dart';
import 'locked_section_widget.dart';
import 'reader_item.dart';
import 'scene_break_widget.dart';
import 'scene_image_widget.dart';
import 'story_line_widget.dart';

class ReaderItemBuilder {
  final ReaderSettings settings;
  final String chapterTitle;
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
    required this.chapterTitle,
    required this.selections,
    required this.missingParts,
    required this.loadingParts,
    required this.onRetryBackward,
    required this.onRetryForward,
    required this.onGoToChoice,
    required this.onChoiceSelected,
  });

  String _initialsFor(String? speaker) {
    if (speaker == null || speaker.isEmpty) return '';
    final cleaned = speaker.replaceAll(RegExp(r'[^A-Za-z0-9\s]'), '').trim();
    if (cleaned.isEmpty) return '';
    final parts = cleaned
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) {
      final word = parts.first;
      if (word.length >= 2) {
        return word.substring(0, 2).toUpperCase();
      }
      return word.toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  Widget build(BuildContext context, ReaderItem item) {
    if (item is TransitionItem) {
      return ChapterTransitionWidget(
        previousTitle: item.previousTitle,
        currentTitle: item.currentTitle,
        settings: settings,
        backwardMissingReason: item.backwardMissingReason,
        forwardMissingReason: item.forwardMissingReason,
        isPendingBackward: item.isPendingBackward,
        isPendingForward: item.isPendingForward,
        onRetryBackward: item.backwardMissingReason != null
            ? () => onRetryBackward(item.partIndexInList - 1)
            : null,
        onRetryForward: item.forwardMissingReason != null
            ? () => onRetryForward(item.partIndexInList)
            : null,
      );
    }

    if (item is SceneBreakItem) {
      final ref = AssetRef(
        type: AssetType.background,
        id: item.backgroundImageId,
      );
      return SceneBreakWidget(
        settings: settings,
        onTap: () => ImageModal.show(
          context,
          urls: ref.urls,
          cacheKey: ref.cacheKey,
          title: 'Scene: $chapterTitle',
        ),
      );
    }

    if (item is SceneImageItem) {
      final ref = AssetRef(type: AssetType.cg, id: item.imageId);
      return SceneImageWidget(
        imageId: item.imageId,
        urls: ref.urls,
        cacheKey: ref.cacheKey,
        settings: settings,
        onTap: () => ImageModal.show(
          context,
          urls: ref.urls,
          cacheKey: ref.cacheKey,
          title: 'Cutscene: $chapterTitle',
        ),
      );
    }

    if (item is DialogueGroupItem) {
      final portraitId = item.speakerPortraitId;
      final speaker = item.speaker;

      if (speaker == null) {
        return DialogueGroupWidget(
          speaker: null,
          lines: item.lines,
          settings: settings,
        );
      }

      if (portraitId != null) {
        final ref = AssetRef(type: AssetType.character, id: portraitId);
        return DialogueGroupWidget(
          speaker: speaker,
          lines: item.lines,
          settings: settings,
          onSpeakerTap: () => ImageModal.show(
            context,
            urls: ref.urls,
            cacheKey: ref.cacheKey,
            title: speaker,
            placeholderInitials: _initialsFor(speaker),
          ),
        );
      }

      return DialogueGroupWidget(
        speaker: speaker,
        lines: item.lines,
        settings: settings,
        onSpeakerTap: () => ImageModal.show(
          context,
          urls: const [],
          cacheKey: 'placeholder:${speaker.hashCode}',
          title: speaker,
          placeholderInitials: _initialsFor(speaker),
        ),
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
