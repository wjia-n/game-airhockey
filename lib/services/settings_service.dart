import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/rink_themes.dart';

/// Persisted settings + stats for Air Hockey. Survives app restarts.
///
/// Stores: audio toggles, player names (2 slots), table/mallet/puck
/// appearance choices (incl. custom theme colors), mode setup (solo vs AI /
/// 2-player local, bot difficulty), Pro unlock state, and lifetime stats.
class RinkSettings extends ChangeNotifier {
  static const _kMusic = 'airhockey_music_on';
  static const _kSfx = 'airhockey_sfx_on';
  static const _kVolume = 'airhockey_volume';
  static const _kMode = 'airhockey_mode'; // 0 = vs AI, 1 = 2-player local
  static const _kDifficulty = 'airhockey_bot_difficulty'; // 0/1/2
  static const _kNames = 'airhockey_player_names'; // legacy unordered key
  /// Order-safe player-name storage: a single JSON string. Android's
  /// SharedPreferences stores StringLists as an unordered StringSet, so the
  /// old key scrambled name order on every app restart. Never use a
  /// StringList for ordered data on Android.
  static const _kNamesJson = 'airhockey_player_names_json';
  static const _kTheme = 'airhockey_theme_id';
  static const _kMallet = 'airhockey_mallet_style';
  static const _kPuck = 'airhockey_puck_style';
  static const _kWins = 'airhockey_wins';
  static const _kGames = 'airhockey_games_played';
  static const _kGoals = 'airhockey_goals_scored';
  static const _kIsPro = 'airhockey_is_pro';
  static const _kCustomPrefix = 'airhockey_custom_';

  /// The two on-screen sides: index 0 = bottom side, index 1 = top side.
  static const defaultNames = ['You', 'Rival'];

  /// Encode the 2 player names as one JSON string (order-preserving).
  static String encodePlayerNames(List<String> names) => jsonEncode(names);

  static String _cleanName(int i, Object? v) {
    final s = v is String ? v.trim() : '';
    return s.isEmpty ? defaultNames[i] : s;
  }

  /// Decode persisted names; falls back to defaults on missing/corrupt data.
  static List<String> decodePlayerNames(String? raw) {
    if (raw == null) return List.of(defaultNames);
    try {
      final d = jsonDecode(raw);
      if (d is List && d.length == 2) {
        return [for (int i = 0; i < 2; i++) _cleanName(i, d[i])];
      }
    } catch (_) {}
    return List.of(defaultNames);
  }

  bool musicOn = true;
  bool sfxOn = true;
  double volume = 0.8;
  int mode = 0; // 0 = vs AI, 1 = 2-player local
  int difficulty = 1; // 0 rookie, 1 skilled, 2 champion (Pro)
  List<String> playerNames = List.of(defaultNames);
  String themeId = 'classic';
  int malletStyle = 0;
  int puckStyle = 0;
  int wins = 0;
  int gamesPlayed = 0;
  int goalsScored = 0; // lifetime human-side goals
  bool isPro = false;

  /// Custom theme colors (ARGB ints). Defaults mirror Classic Arcade.
  Map<String, int> customColors = Map.of(_defaultCustomColors);

  static const Map<String, int> _defaultCustomColors = {
    'railDark': 0xFF3B2416,
    'railMid': 0xFF5C3A21,
    'railLight': 0xFF7A5230,
    'surfaceLight': 0xFFF7F2E6,
    'surfaceDark': 0xFFE3D8BE,
    'lineColor': 0xFFA31621,
    'accent': 0xFFC9A227,
    'accentLight': 0xFFE8CE7A,
    'accentDark': 0xFF8A6D1A,
    'ivory': 0xFFF5EFE0,
    'woodDeep': 0xFF241309,
    'side0': 0xFFA31621,
    'side1': 0xFF1D4E9E,
  };

  /// Builds the user-designed custom theme from stored colors.
  RinkThemeDef get customTheme {
    Color c(String k) => Color(customColors[k] ?? 0xFF000000);
    return RinkThemeDef(
      id: 'custom',
      name: 'My Creation',
      railDark: c('railDark'),
      railMid: c('railMid'),
      railLight: c('railLight'),
      surfaceLight: c('surfaceLight'),
      surfaceDark: c('surfaceDark'),
      lineColor: c('lineColor'),
      accent: c('accent'),
      accentLight: c('accentLight'),
      accentDark: c('accentDark'),
      ivory: c('ivory'),
      woodDeep: c('woodDeep'),
      sideColors: [c('side0'), c('side1')],
      sideColorNames: const ['Home', 'Away'],
    );
  }

  SharedPreferences? _prefs;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final p = _prefs!;
    musicOn = p.getBool(_kMusic) ?? true;
    sfxOn = p.getBool(_kSfx) ?? true;
    volume = p.getDouble(_kVolume) ?? 0.8;
    mode = (p.getInt(_kMode) ?? 0).clamp(0, 1);
    difficulty = (p.getInt(_kDifficulty) ?? 1).clamp(0, 2);
    // Player names: prefer the order-safe JSON key. Fall back to the legacy
    // StringList key once (one-time migration); it may already be scrambled
    // on Android, which is exactly the bug this replaces.
    final namesRaw = p.getString(_kNamesJson);
    if (namesRaw != null) {
      playerNames = decodePlayerNames(namesRaw);
    } else {
      final legacy = p.getStringList(_kNames);
      playerNames = (legacy != null && legacy.length == 2)
          ? [for (int i = 0; i < 2; i++) _cleanName(i, legacy[i])]
          : List.of(defaultNames);
    }
    themeId = p.getString(_kTheme) ?? 'classic';
    malletStyle = (p.getInt(_kMallet) ?? 0).clamp(0, MalletStyles.all.length - 1);
    puckStyle = (p.getInt(_kPuck) ?? 0).clamp(0, PuckStyles.all.length - 1);
    wins = p.getInt(_kWins) ?? 0;
    gamesPlayed = p.getInt(_kGames) ?? 0;
    goalsScored = p.getInt(_kGoals) ?? 0;
    isPro = p.getBool(_kIsPro) ?? false;
    for (final k in _defaultCustomColors.keys) {
      customColors[k] =
          p.getInt('$_kCustomPrefix$k') ?? _defaultCustomColors[k]!;
    }
    _enforceFreeLimits(silent: true);
    notifyListeners();
  }

  Future<void> _save() async {
    final p = _prefs;
    if (p == null) return;
    await p.setBool(_kMusic, musicOn);
    await p.setBool(_kSfx, sfxOn);
    await p.setDouble(_kVolume, volume);
    await p.setInt(_kMode, mode);
    await p.setInt(_kDifficulty, difficulty);
    await p.setString(_kNamesJson, encodePlayerNames(playerNames));
    await p.remove(_kNames); // drop the legacy unordered key for good
    await p.setString(_kTheme, themeId);
    await p.setInt(_kMallet, malletStyle);
    await p.setInt(_kPuck, puckStyle);
    await p.setInt(_kWins, wins);
    await p.setInt(_kGames, gamesPlayed);
    await p.setInt(_kGoals, goalsScored);
    await p.setBool(_kIsPro, isPro);
    for (final e in customColors.entries) {
      await p.setInt('$_kCustomPrefix${e.key}', e.value);
    }
  }

  /// Free-tier limits: clamp pro-only choices back when not Pro.
  /// Called after load and whenever Pro status could have changed.
  void _enforceFreeLimits({bool silent = false}) {
    if (isPro) return;
    var changed = false;
    // The custom theme creator is a Pro feature ('custom' is not covered by
    // RinkThemes.isProTheme, so it needs an explicit check).
    if (themeId == 'custom' || RinkThemes.isProTheme(themeId)) {
      themeId = 'classic';
      changed = true;
    }
    if (MalletStyles.isPro(malletStyle)) {
      malletStyle = 0;
      changed = true;
    }
    if (PuckStyles.isPro(puckStyle)) {
      puckStyle = 0;
      changed = true;
    }
    if (difficulty > 1) {
      difficulty = 1;
      changed = true;
    }
    if (changed && !silent) {
      notifyListeners();
      _save();
    }
  }

  Future<void> setPro(bool v) async {
    isPro = v;
    if (!v) _enforceFreeLimits();
    notifyListeners();
    await _save();
  }

  Future<void> setCustomColor(String key, int argb) async {
    if (!isPro) return; // custom theme creator is a Pro feature
    if (!_defaultCustomColors.containsKey(key)) return;
    customColors[key] = argb;
    notifyListeners();
    await _save();
  }

  Future<void> resetCustomColors() async {
    customColors = Map.of(_defaultCustomColors);
    notifyListeners();
    await _save();
  }

  Future<void> setMusic(bool v) async {
    musicOn = v;
    notifyListeners();
    await _save();
  }

  Future<void> setSfx(bool v) async {
    sfxOn = v;
    notifyListeners();
    await _save();
  }

  Future<void> setVolume(double v) async {
    volume = v.clamp(0.0, 1.0);
    notifyListeners();
    await _save();
  }

  /// Mode setup: [mode] 0 = vs AI, 1 = 2-player local;
  /// [difficulty] 0 rookie / 1 skilled / 2 champion (Pro only).
  Future<void> setSetup({required int mode, required int difficulty}) async {
    this.mode = mode.clamp(0, 1);
    this.difficulty = difficulty.clamp(0, 2);
    // Champion is a Pro feature.
    if (!isPro && this.difficulty > 1) this.difficulty = 1;
    notifyListeners();
    await _save();
  }

  /// Save on every keystroke (never only on keyboard-done).
  Future<void> setPlayerName(int index, String name) async {
    if (index < 0 || index > 1) return;
    playerNames[index] = _cleanName(index, name);
    notifyListeners();
    await _save();
  }

  /// Commit on focus loss: guarantees the final typed value is persisted.
  Future<void> commitNames() async => _save();

  Future<void> setTheme(String id) async {
    // Pro-only themes (incl. the custom theme creator) require Pro;
    // silently ignore otherwise (UI shows a lock).
    if (!isPro && (id == 'custom' || RinkThemes.isProTheme(id))) return;
    themeId = id;
    notifyListeners();
    await _save();
  }

  Future<void> setMalletStyle(int v) async {
    v = v.clamp(0, MalletStyles.all.length - 1);
    if (!isPro && MalletStyles.isPro(v)) return;
    malletStyle = v;
    notifyListeners();
    await _save();
  }

  Future<void> setPuckStyle(int v) async {
    v = v.clamp(0, PuckStyles.all.length - 1);
    if (!isPro && PuckStyles.isPro(v)) return;
    puckStyle = v;
    notifyListeners();
    await _save();
  }

  /// Record a finished match. [humanWon] true if a human side won;
  /// [humanGoals] goals scored by the bottom (human) side.
  Future<void> recordGame(
      {required bool humanWon, required int humanGoals}) async {
    gamesPlayed++;
    if (humanWon) wins++;
    goalsScored += humanGoals;
    notifyListeners();
    await _save();
  }

  Future<void> resetStats() async {
    wins = 0;
    gamesPlayed = 0;
    goalsScored = 0;
    notifyListeners();
    await _save();
  }
}
