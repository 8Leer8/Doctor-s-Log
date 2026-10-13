import '../../models/story_element.dart';
import '../local/character_sprite_map_store.dart';

class StoryParser {
  static final RegExp _speakerLineRegex = RegExp(
    r'^\[name="([^"]*)"\]\s*(.*)$',
  );
  static final RegExp _decisionRegex = RegExp(
    r'^\[Decision\(options="(.*)",\s*values="(.*)"\)\]\s*$',
  );
  static final RegExp _predicateRegex = RegExp(
    r'^\[Predicate\(references="(.*)"\)\]\s*$',
  );
  static final RegExp _backgroundRegex = RegExp(
    r'^\[Background\(image="([^"]*)"',
  );
  static final RegExp _imageRegex = RegExp(r'^\[Image\(image="([^"]*)"');
  static final RegExp _stickerRegex = RegExp(
    r'^\[Sticker\([^\]]*text\s*=\s*"((?:[^"\\]|\\.)*)"',
  );
  static final RegExp _subtitleRegex = RegExp(
    r'^\[Subtitle\([^\]]*text\s*=\s*"((?:[^"\\]|\\.)*)"',
  );

  // ---- Stage / sprite tracking -------------------------------------------
  //
  // Scripts describe who is on screen in two formats:
  //   legacy : [Character(name="a", name2="b", focus=1|2)]
  //   newer  : [charslot(slot="l|m|r", name="a", focus="l|m|r|n|all")]
  // `focus` marks the character who is speaking and persists until changed.
  static final RegExp _characterNameRegex = RegExp(
    r'(?<![A-Za-z0-9])name\s*=\s*"([^"]*)"',
  );
  static final RegExp _characterName2Regex = RegExp(
    r'(?<![A-Za-z0-9])name2\s*=\s*"([^"]*)"',
  );
  static final RegExp _characterTagRegex = RegExp(
    r'^\[character(?:\(|\])',
    caseSensitive: false,
  );
  static final RegExp _charslotTagRegex = RegExp(
    r'^\[charslot(?:\(|\])',
    caseSensitive: false,
  );
  static final RegExp _slotRegex = RegExp(
    r'(?<![A-Za-z0-9])slot\s*=\s*"([^"]*)"',
    caseSensitive: false,
  );
  static final RegExp _focusNumRegex = RegExp(r'focus\s*=\s*(-?\d)');
  static final RegExp _focusStrRegex = RegExp(
    r'(?<![A-Za-z0-9])focus\s*=\s*"?([A-Za-z]*)"?',
    caseSensitive: false,
  );

  static final RegExp _animTextRegex = RegExp(
    r'^\[animtext\([^\]]*\)\]\s*(.*)$',
  );
  static final RegExp _animTextParagraphRegex = RegExp(
    r'<p=\d+>(.*?)</p?>',
    dotAll: true,
  );
  static final RegExp _nameTokenRegex = RegExp(
    r'^(?:char|avg)_\d+_([a-z0-9]+)',
    caseSensitive: false,
  );

  static Future<void> ensureSpriteMapLoaded() async {
    await CharacterSpriteMapStore.load();
  }

  static String _unescapeText(String s) {
    return s
        .replaceAll(r'\n', '\n')
        .replaceAll(r'\"', '"')
        .replaceAll(r'\\', '\\');
  }

  static String? _extractNameToken(String spriteId) {
    final m = _nameTokenRegex.firstMatch(spriteId.toLowerCase());
    return m?.group(1);
  }

  static bool _matchesSpeaker(String spriteId, String speaker) {
    final token = _extractNameToken(spriteId);
    if (token == null || token.length < 4) return false;

    final speakerNorm = speaker.toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]'),
      '',
    );
    if (speakerNorm.isEmpty) return false;

    return speakerNorm.contains(token) || token.contains(speakerNorm);
  }

  static String? _cleanSprite(String? v) {
    if (v == null) return null;
    final t = v.trim();
    if (t.isEmpty || t.toLowerCase() == 'char_empty') return null;
    return t;
  }

  static String? _slotKey(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'l':
      case 'left':
        return 'L';
      case 'm':
      case 'middle':
        return 'M';
      case 'r':
      case 'right':
        return 'R';
    }
    return null;
  }

  /// Legacy `focus=` values: 1 / 2 = that sprite is speaking, -1 = nobody on
  /// stage is speaking (the speaker is off-screen: phone call, radio, out of
  /// frame), anything else = default highlight (null).
  static Set<String>? _legacyFocus(int v) {
    if (v == 1) return {'A'};
    if (v == 2) return {'B'};
    if (v == -1) return <String>{};
    return null;
  }

  /// True when the script says nobody on stage is the speaker.
  static bool _isOffScreen(Map<String, String> stage, Set<String>? focus) =>
      stage.isNotEmpty && focus != null && focus.isEmpty;

  /// Picks the sprite for whoever is speaking, using what is on stage:
  ///  1. a sprite whose id matches the speaker's name (operators),
  ///  2. the sprite in the focused slot (the script marks the speaker),
  ///  3. the only sprite on stage.
  /// Returns null when the stage is empty or ambiguous; the caller then falls
  /// back to the global speaker -> sprite map.
  static String? _resolvePortrait({
    required String? speaker,
    required Map<String, String> stage,
    required Set<String>? focus,
  }) {
    if (speaker == null || speaker.trim().isEmpty) return null;
    if (stage.isEmpty) return null;

    for (final id in stage.values) {
      if (_matchesSpeaker(id, speaker)) return id;
    }

    // The script says nobody on stage is speaking, so the sprite(s) shown
    // belong to the listener(s), not to this speaker. Show no portrait.
    if (_isOffScreen(stage, focus)) return null;

    if (focus != null && focus.isNotEmpty) {
      final focused = <String>[
        for (final k in focus)
          if (stage.containsKey(k)) stage[k]!,
      ];
      if (focused.length == 1) return focused.first;
    }

    if (stage.length == 1) return stage.values.first;

    return null;
  }

  static List<StoryElement> parse(String raw) {
    final result = <StoryElement>[];

    int choiceCounter = 0;
    int? currentGateChoiceId;
    String? currentRequiredValue;

    String? lastBackgroundImage;
    String? lastImageId;

    // slot key ('A','B' legacy; 'L','M','R' charslot) -> sprite id
    final stage = <String, String>{};
    Set<String>? focus;

    for (final rawLine in raw.split('\n')) {
      final line = rawLine.trimRight();
      final trimmedLeft = line.trimLeft();
      if (trimmedLeft.isEmpty) continue;

      final animMatch = _animTextRegex.firstMatch(trimmedLeft);
      if (animMatch != null) {
        final payload = animMatch.group(1) ?? '';
        if (payload.isNotEmpty) {
          final paragraphs = _animTextParagraphRegex
              .allMatches(payload)
              .map((m) => (m.group(1) ?? '').trim())
              .where((t) => t.isNotEmpty)
              .toList();

          for (final text in paragraphs) {
            result.add(
              StoryLineElement(
                speaker: null,
                text: text,
                requiredValue: currentRequiredValue,
                gateChoiceId: currentGateChoiceId,
              ),
            );
          }
        }
        continue;
      }

      final backgroundMatch = _backgroundRegex.firstMatch(trimmedLeft);
      if (backgroundMatch != null) {
        final image = backgroundMatch.group(1) ?? '';
        if (image.isNotEmpty && image != lastBackgroundImage) {
          result.add(
            SceneBreakElement(
              backgroundImageId: image,
              requiredValue: currentRequiredValue,
              gateChoiceId: currentGateChoiceId,
            ),
          );
          lastBackgroundImage = image;
        }
        lastImageId = null;
        continue;
      }

      final imageMatch = _imageRegex.firstMatch(trimmedLeft);
      if (imageMatch != null) {
        final image = imageMatch.group(1) ?? '';
        if (image.isNotEmpty && image != lastImageId) {
          result.add(
            StoryImageElement(
              imageId: image,
              requiredValue: currentRequiredValue,
              gateChoiceId: currentGateChoiceId,
            ),
          );
          lastImageId = image;
        }
        continue;
      }

      final stickerMatch = _stickerRegex.firstMatch(trimmedLeft);
      if (stickerMatch != null) {
        final text = _unescapeText(stickerMatch.group(1) ?? '');
        if (text.isNotEmpty) {
          result.add(
            StoryLineElement(
              text: text,
              requiredValue: currentRequiredValue,
              gateChoiceId: currentGateChoiceId,
            ),
          );
        }
        continue;
      }

      final subtitleMatch = _subtitleRegex.firstMatch(trimmedLeft);
      if (subtitleMatch != null) {
        final text = _unescapeText(subtitleMatch.group(1) ?? '');
        if (text.isNotEmpty) {
          result.add(
            StoryLineElement(
              text: text,
              requiredValue: currentRequiredValue,
              gateChoiceId: currentGateChoiceId,
            ),
          );
        }
        continue;
      }

      // Legacy format: [Character(name=..., name2=..., focus=1|2)]
      if (_characterTagRegex.hasMatch(trimmedLeft)) {
        final nameMatch = _characterNameRegex.firstMatch(trimmedLeft);
        final name2Match = _characterName2Regex.firstMatch(trimmedLeft);
        final focusMatch = _focusNumRegex.firstMatch(trimmedLeft);

        if (nameMatch == null && name2Match == null) {
          if (focusMatch != null) {
            // Focus-only tag: sprites stay, the active speaker changes.
            focus = _legacyFocus(int.parse(focusMatch.group(1)!));
          } else {
            // Bare tag (e.g. fade-out): clears the stage.
            stage.clear();
            focus = null;
          }
          continue;
        }

        if (nameMatch != null) {
          stage.remove('A');
          final v = _cleanSprite(nameMatch.group(1));
          if (v != null) stage['A'] = v;
        }

        if (name2Match != null) {
          stage.remove('B');
          final v = _cleanSprite(name2Match.group(1));
          if (v != null) stage['B'] = v;
        } else if (nameMatch != null) {
          stage.remove('B');
        }

        // `focus` belongs to the tag it is written on: a tag without it goes
        // back to the default highlight (so [Character(name=A)] after a
        // focus=-1 line makes A the speaker again).
        focus = focusMatch != null
            ? _legacyFocus(int.parse(focusMatch.group(1)!))
            : null;

        continue;
      }

      // Newer format: [charslot(slot="l|m|r", name=..., focus=...)]
      if (_charslotTagRegex.hasMatch(trimmedLeft)) {
        final slotMatch = _slotRegex.firstMatch(trimmedLeft);
        final nameMatch = _characterNameRegex.firstMatch(trimmedLeft);
        final focusMatch = _focusStrRegex.firstMatch(trimmedLeft);
        final hasFocusAttr = trimmedLeft.toLowerCase().contains('focus');

        if (slotMatch == null && nameMatch == null && !hasFocusAttr) {
          // Bare [charslot] / duration-only: clears the stage.
          stage.clear();
          focus = null;
          continue;
        }

        if (slotMatch != null && nameMatch != null) {
          final slot = _slotKey(slotMatch.group(1) ?? '');
          if (slot != null) {
            final v = _cleanSprite(nameMatch.group(1));
            if (v != null) {
              stage[slot] = v;
            } else {
              stage.remove(slot);
            }
          }
        }

        if (focusMatch != null && hasFocusAttr) {
          final fv = (focusMatch.group(1) ?? '').toLowerCase();
          final key = _slotKey(fv);
          if (key != null) {
            focus = {key};
          } else if (fv == 'all' || fv == 'a') {
            focus = null; // everyone highlighted: default
          } else {
            focus = <String>{}; // n / none: nobody on stage is speaking
          }
        } else if (nameMatch != null) {
          // A new sprite without a focus attribute goes back to the default.
          focus = null;
        }

        continue;
      }

      final decisionMatch = _decisionRegex.firstMatch(line);
      if (decisionMatch != null) {
        choiceCounter++;
        final options = (decisionMatch.group(1) ?? '').split(';');
        final values = (decisionMatch.group(2) ?? '').split(';');
        final count = options.length < values.length
            ? options.length
            : values.length;
        final opts = <StoryChoiceOption>[
          for (int i = 0; i < count; i++)
            StoryChoiceOption(
              label: options[i].trim(),
              value: values[i].trim(),
            ),
        ];
        result.add(
          StoryChoiceElement(
            id: choiceCounter,
            options: opts,
            requiredValue: currentRequiredValue,
            gateChoiceId: currentGateChoiceId,
          ),
        );
        continue;
      }

      final predicateMatch = _predicateRegex.firstMatch(line);
      if (predicateMatch != null) {
        currentRequiredValue = predicateMatch.group(1);
        currentGateChoiceId = choiceCounter == 0 ? null : choiceCounter;
        continue;
      }

      final speakerMatch = _speakerLineRegex.firstMatch(line);
      if (speakerMatch != null) {
        final rawSpeaker = speakerMatch.group(1) ?? '';
        final speaker = rawSpeaker.trim().isEmpty ? null : rawSpeaker;
        final text = (speakerMatch.group(2) ?? '').trim();

        if (text.isNotEmpty) {
          // 1) what the scene itself shows (name match, focus, sole sprite)
          String? portrait = _resolvePortrait(
            speaker: speaker,
            stage: stage,
            focus: focus,
          );

          // 2) fallback: global speaker -> sprite map (operators + NPCs).
          //    Not used when the script says the speaker is off-screen
          //    (phone call, radio, out of frame): no portrait is correct then.
          if (portrait == null &&
              speaker != null &&
              !_isOffScreen(stage, focus)) {
            portrait = CharacterSpriteMapStore.lookupSync(speaker);
          }

          result.add(
            StoryLineElement(
              speaker: speaker,
              text: text,
              speakerPortraitId: portrait,
              requiredValue: currentRequiredValue,
              gateChoiceId: currentGateChoiceId,
            ),
          );
        }
        continue;
      }

      if (trimmedLeft.startsWith('[')) {
        continue;
      }

      result.add(
        StoryLineElement(
          text: line.trim(),
          requiredValue: currentRequiredValue,
          gateChoiceId: currentGateChoiceId,
        ),
      );
    }

    return result;
  }
}
