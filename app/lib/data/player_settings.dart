class PlayerSettings {
  const PlayerSettings({
    this.music = true,
    this.sound = true,
    this.haptics = true,
    this.reducedMotion = false,
    this.colorSymbols = true,
    this.strongContrast = false,
  });
  final bool music, sound, haptics, reducedMotion, colorSymbols, strongContrast;
  Map<String, bool> toJson() => {
    'music': music,
    'sound': sound,
    'haptics': haptics,
    'reduced_motion': reducedMotion,
    'color_symbols': colorSymbols,
    'strong_contrast': strongContrast,
  };
  factory PlayerSettings.fromJson(Map<String, bool> m) => PlayerSettings(
    music: m['music']!,
    sound: m['sound']!,
    haptics: m['haptics']!,
    reducedMotion: m['reduced_motion']!,
    colorSymbols: m['color_symbols']!,
    strongContrast: m['strong_contrast']!,
  );
  PlayerSettings withValue(String key, bool value) {
    final values = toJson();
    if (!values.containsKey(key)) throw ArgumentError.value(key);
    values[key] = value;
    return PlayerSettings.fromJson(values);
  }
}
