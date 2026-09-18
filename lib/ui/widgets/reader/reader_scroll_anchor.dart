/// Identifies which kind of ReaderItem a [ScrollAnchor] points at.
enum AnchorKind { content, transition, locked, endMarker }

class ScrollAnchor {
  final AnchorKind kind;
  final int? partIndexInList;
  final int? elementIndexInPart;
  final int? gateChoiceId;

  final double alignment;

  ScrollAnchor.content(
    this.partIndexInList,
    this.elementIndexInPart,
    this.alignment,
  ) : kind = AnchorKind.content,
      gateChoiceId = null;

  ScrollAnchor.transition(this.partIndexInList, this.alignment)
    : kind = AnchorKind.transition,
      elementIndexInPart = null,
      gateChoiceId = null;

  ScrollAnchor.locked(this.partIndexInList, this.gateChoiceId, this.alignment)
    : kind = AnchorKind.locked,
      elementIndexInPart = null;

  ScrollAnchor.endMarker(this.alignment)
    : kind = AnchorKind.endMarker,
      partIndexInList = null,
      elementIndexInPart = null,
      gateChoiceId = null;
}
