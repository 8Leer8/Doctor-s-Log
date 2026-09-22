enum SelectionAction { bookmark, download, delete }

class SelectionActions {
  static List<SelectionAction> forIndices({
    required Iterable<int> selectedIndices,
    required List<bool> isDownloaded,
    required List<bool> hasFile,
  }) {
    final actions = <SelectionAction>[];
    if (selectedIndices.isEmpty) return actions;

    final anyDownloadable = selectedIndices.any(
      (i) => hasFile[i] && !isDownloaded[i],
    );
    final anyDownloaded = selectedIndices.any(
      (i) => hasFile[i] && isDownloaded[i],
    );

    actions.add(SelectionAction.bookmark);
    if (anyDownloadable) actions.add(SelectionAction.download);
    if (anyDownloaded) actions.add(SelectionAction.delete);

    return actions;
  }
}
