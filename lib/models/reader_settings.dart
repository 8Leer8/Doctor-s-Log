import 'package:flutter/material.dart';

enum ReaderThemeOption { dark, black, sepia, light }

extension ReaderThemeLabel on ReaderThemeOption {
  String get label => switch (this) {
    ReaderThemeOption.dark => 'Dark',
    ReaderThemeOption.black => 'Black',
    ReaderThemeOption.sepia => 'Sepia',
    ReaderThemeOption.light => 'Light',
  };
}

class ReaderThemeColors {
  final Color background;
  final Color text;
  final Color secondaryText;
  final Color speaker;
  final Color accent; // used for highlights/borders across reader UI (choice boxes, transition dividers, settings controls)

  const ReaderThemeColors({
    required this.background,
    required this.text,
    required this.secondaryText,
    required this.speaker,
    required this.accent,
  });

  static const Map<ReaderThemeOption, ReaderThemeColors> presets = {
    ReaderThemeOption.dark: ReaderThemeColors(
      background: Color(0xFF15181F),
      text: Color(0xFFEDEDED),
      secondaryText: Color(0xFF9CA3AF),
      speaker: Color(0xFFF2A93C),
      accent: Color(0xFFF2A93C),
    ),
    ReaderThemeOption.black: ReaderThemeColors(
      background: Colors.black,
      text: Color(0xFFEDEDED),
      secondaryText: Color(0xFF9CA3AF),
      speaker: Color(0xFFF2A93C),
      accent: Color(0xFFF2A93C),
    ),
    ReaderThemeOption.sepia: ReaderThemeColors(
      background: Color(0xFFF4ECD8),
      text: Color(0xFF3B2F22),
      secondaryText: Color(0xFF6B5D4B),
      speaker: Color(0xFFA65D2E),
      accent: Color(0xFFA65D2E),
    ),
    ReaderThemeOption.light: ReaderThemeColors(
      background: Colors.white,
      text: Color(0xFF1A1A1A),
      secondaryText: Color(0xFF6B7280),
      speaker: Color(0xFFB5762A),
      accent: Color(0xFFB5762A),
    ),
  };
}

enum LineSpacingOption { compact, comfortable, spacious }

extension LineSpacingValue on LineSpacingOption {
  double get multiplier {
    switch (this) {
      case LineSpacingOption.compact:
        return 1.3;
      case LineSpacingOption.comfortable:
        return 1.6;
      case LineSpacingOption.spacious:
        return 2.0;
    }
  }

  String get label {
    switch (this) {
      case LineSpacingOption.compact:
        return 'Compact';
      case LineSpacingOption.comfortable:
        return 'Comfortable';
      case LineSpacingOption.spacious:
        return 'Spacious';
    }
  }
}

/// Global reading preferences (one set for the whole app, not per chapter).
///
/// Stored as a small versioned JSON object (see ReaderSettingsStore):
///   {"v":1,"fontSize":16.0,"theme":"dark","lineSpacing":"comfortable",
///    "keepScreenAwake":true}
/// Enums are saved by NAME, so reordering them later never breaks saved
/// settings, and unknown or missing values fall back to the defaults.
class ReaderSettings {
  static const int schemaVersion = 1;
  static const double minFontSize = 12;
  static const double maxFontSize = 24;

  final double fontSize;
  final ReaderThemeOption theme;
  final LineSpacingOption lineSpacing;
  final bool keepScreenAwake;

  const ReaderSettings({
    this.fontSize = 16,
    this.theme = ReaderThemeOption.dark,
    this.lineSpacing = LineSpacingOption.comfortable,
    this.keepScreenAwake = true,
  });

  ReaderThemeColors get colors => ReaderThemeColors.presets[theme]!;

  ReaderSettings copyWith({
    double? fontSize,
    ReaderThemeOption? theme,
    LineSpacingOption? lineSpacing,
    bool? keepScreenAwake,
  }) {
    return ReaderSettings(
      fontSize: fontSize ?? this.fontSize,
      theme: theme ?? this.theme,
      lineSpacing: lineSpacing ?? this.lineSpacing,
      keepScreenAwake: keepScreenAwake ?? this.keepScreenAwake,
    );
  }

  Map<String, dynamic> toJson() => {
    'v': schemaVersion,
    'fontSize': fontSize,
    'theme': theme.name,
    'lineSpacing': lineSpacing.name,
    'keepScreenAwake': keepScreenAwake,
  };

  /// Tolerant reader: bad, missing or out-of-range values become defaults.
  factory ReaderSettings.fromJson(Map<String, dynamic> json) {
    const d = ReaderSettings();
    final rawSize = json['fontSize'];
    final size = rawSize is num ? rawSize.toDouble() : d.fontSize;
    final awake = json['keepScreenAwake'];

    return ReaderSettings(
      fontSize: size.clamp(minFontSize, maxFontSize).toDouble(),
      theme: _byName(ReaderThemeOption.values, json['theme']) ?? d.theme,
      lineSpacing:
          _byName(LineSpacingOption.values, json['lineSpacing']) ??
          d.lineSpacing,
      keepScreenAwake: awake is bool ? awake : d.keepScreenAwake,
    );
  }

  static T? _byName<T extends Enum>(List<T> values, Object? name) {
    for (final v in values) {
      if (v.name == name) return v;
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      other is ReaderSettings &&
      other.fontSize == fontSize &&
      other.theme == theme &&
      other.lineSpacing == lineSpacing &&
      other.keepScreenAwake == keepScreenAwake;

  @override
  int get hashCode => Object.hash(fontSize, theme, lineSpacing, keepScreenAwake);
}