import '../data/local/profile_store.dart';

/// Swaps the player's name into story text.
///
/// * "{@nickname}" (the game's own placeholder for the player's name) is
///   always replaced: with your name when the option is on, otherwise with
///   "Doctor", so the raw placeholder never shows up in the reader.
/// * The standalone capitalised word "Doctor" (also "Doctor's") becomes your
///   name when the option is on and you have set one. Lowercase "doctor",
///   "Doctors" and words like "Doctorate" are left alone.
class PlayerName {
  PlayerName._();

  static final RegExp _nickname = RegExp(
    r'\{@nickname\}',
    caseSensitive: false,
  );
  static final RegExp _doctor = RegExp(r'\bDoctor\b');

  static String apply(String text) {
    if (text.isEmpty) return text;

    final name = ProfileStore.name.value;
    final enabled = ProfileStore.useNameInStories.value;
    final custom = enabled && name != ProfileStore.defaultName;

    var out = text.replaceAll(
      _nickname,
      custom ? name : ProfileStore.defaultName,
    );
    if (custom) out = out.replaceAll(_doctor, name);
    return out;
  }
}
