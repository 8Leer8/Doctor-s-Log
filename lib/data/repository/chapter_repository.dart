import '../../models/chapter_preview.dart';
import '../../models/story_part.dart';
import '../../models/story_index_entry.dart';
import '../remote/story_index_source.dart';

class ChapterRepository {
  final StoryIndexSource _indexSource = StoryIndexSource();

  Future<List<ChapterPreview>> fetchMainTheme() async {
    final entries = await _entriesOfType('MAINLINE');
    entries.sort(
      (a, b) => _mainlineSortKey(a.id).compareTo(_mainlineSortKey(b.id)),
    );
    return entries.map(_toChapterPreview).toList();
  }

  Future<List<ChapterPreview>> fetchSideStories() =>
      _fetchSortedByName('ACTIVITY');

  /// Vignettes are the game's "mini stories" (entryType MINI_ACTIVITY). They
  /// live in the same index as Main Theme and Side Stories.
  Future<List<ChapterPreview>> fetchVignettes() =>
      _fetchSortedByName('MINI_ACTIVITY');

  Future<List<ChapterIndexEntry>> _entriesOfType(String entryType) async {
    final index = await _indexSource.fetchIndex();
    return index.values.where((e) => e.entryType == entryType).toList();
  }

  Future<List<ChapterPreview>> _fetchSortedByName(String entryType) async {
    final entries = await _entriesOfType(entryType);
    entries.sort((a, b) => a.name.compareTo(b.name));
    return entries.map(_toChapterPreview).toList();
  }

  int _mainlineSortKey(String id) {
    // ids look like "main_0", "main_1", "main_10" — extract the number for correct order
    final match = RegExp(r'main_(\d+)').firstMatch(id);
    return match != null ? int.parse(match.group(1)!) : 9999;
  }

  ChapterPreview _toChapterPreview(ChapterIndexEntry entry) {
    final parts = entry.infoUnlockDatas
        .map(
          (u) => StoryPart(
            title: u.storyName.isNotEmpty
                ? u.storyName
                : (u.storyCode.isNotEmpty ? u.storyCode : u.storyId),
            filename: '${u.storyTxt}.txt',
            avgTag: u.avgTag.isNotEmpty ? u.avgTag : null,
            code: u.storyCode.isNotEmpty ? u.storyCode : null,
          ),
        )
        .toList();

    return ChapterPreview(
      number: entry.id,
      title: entry.name,
      subtitle: entry.actType,
      description: '', // not available in this table
      progressCurrent: 0,
      progressTotal: parts.length,
      wordCount: 0,
      readTimeMinutes: 0,
      parts: parts,
      entryPicId: entry.storyEntryPicId.isEmpty ? null : entry.storyEntryPicId,
    );
  }
}
