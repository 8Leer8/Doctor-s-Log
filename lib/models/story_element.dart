class StoryChoiceOption {
  final String label;
  final String value;

  const StoryChoiceOption({required this.label, required this.value});
}

/// Base class for anything that can appear in a parsed story.
/// requiredValue + gateChoiceId together mean:
/// "only show this if the player picked `requiredValue` (or one of the
/// semicolon-separated values in it) for choice #gateChoiceId."
/// If requiredValue is null, the element always shows.
abstract class StoryElement {
  final String? requiredValue;
  final int? gateChoiceId;

  const StoryElement({this.requiredValue, this.gateChoiceId});

  bool isVisible(Map<int, String> selections) {
    if (requiredValue == null) return true;
    final chosen = selections[gateChoiceId];
    if (chosen == null) return false; // choice not made yet, stay hidden
    return requiredValue!.split(';').map((s) => s.trim()).contains(chosen);
  }
}

class StoryLineElement extends StoryElement {
  final String? speaker;
  final String text;

  const StoryLineElement({
    this.speaker,
    required this.text,
    super.requiredValue,
    super.gateChoiceId,
  });
}

class StoryChoiceElement extends StoryElement {
  final int id;
  final List<StoryChoiceOption> options;

  const StoryChoiceElement({
    required this.id,
    required this.options,
    super.requiredValue,
    super.gateChoiceId,
  });
}