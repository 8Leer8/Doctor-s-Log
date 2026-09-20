class StoryChoiceOption {
  final String label;
  final String value;

  const StoryChoiceOption({required this.label, required this.value});
}

abstract class StoryElement {
  final String? requiredValue;
  final int? gateChoiceId;

  const StoryElement({this.requiredValue, this.gateChoiceId});

  bool isVisible(Map<int, String> selections) {
    if (requiredValue == null) return true;
    final chosen = selections[gateChoiceId];
    if (chosen == null) return false;
    return requiredValue!.split(';').map((s) => s.trim()).contains(chosen);
  }
}

class StoryLineElement extends StoryElement {
  final String? speaker;
  final String text;
  final String? speakerPortraitId;

  const StoryLineElement({
    this.speaker,
    required this.text,
    this.speakerPortraitId,
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

class SceneBreakElement extends StoryElement {
  final String backgroundImageId;

  const SceneBreakElement({
    required this.backgroundImageId,
    super.requiredValue,
    super.gateChoiceId,
  });
}

class StoryImageElement extends StoryElement {
  final String imageId;

  const StoryImageElement({
    required this.imageId,
    super.requiredValue,
    super.gateChoiceId,
  });
}
