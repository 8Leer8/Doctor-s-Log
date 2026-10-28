import '../data/local/profile_store.dart';

/// Swaps the player's name into story text. Automatic: if you have set a
/// name on your profile it is used everywhere, otherwise stories stay as
/// they are.
///
/// * "{@nickname}" (the game's own placeholder for the player's name) is
///   always replaced, with your name, or "Doctor" when no name is set, so
///   the raw placeholder never shows up in the reader.
/// * The standalone capitalised word "Doctor" (also "Doctor's") becomes your
///   name once you have set one. Lowercase "doctor", "Doctors" and words
///   like "Doctorate" are left alone.
class PlayerName {
  PlayerName._();

  static final RegExp _nickname = RegExp(
    r'\{@nickname\}',
    caseSensitive: false,
  );
  static final RegExp _doctor = RegExp(r'\bDoctor\b');

  static String apply(String text) {
    if (text.isEmpty) return text;

    final name = ProfileStore.name.value; // "Doctor" when nothing is set
    var out = text.replaceAll(_nickname, name);
    if (name != ProfileStore.defaultName) {
      out = out.replaceAll(_doctor, name);
    }
    return out;
  }
}
