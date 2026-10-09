import 'package:flutter/material.dart';

/// Theme, mallet-style and puck-style catalog for Air Hockey.
///
/// Every theme stays inside the physical arcade world — real woods, brushed
/// metal, leather, stone, felt — the variety comes from different rail woods,
/// table surfaces, painted lines and striker jewel tones. No neon, no
/// cyberpunk, no glowing synthetic looks.
class RinkThemeDef {
  final String id;
  final String name;
  final Color railDark;
  final Color railMid;
  final Color railLight;
  final Color surfaceLight;
  final Color surfaceDark;
  final Color lineColor;
  final Color accent; // UI brass-equivalent
  final Color accentLight;
  final Color accentDark;
  final Color ivory;
  final Color woodDeep; // darkest background tone
  final List<Color> sideColors; // [bottom side, top side] mallet defaults
  final List<String> sideColorNames;

  const RinkThemeDef({
    required this.id,
    required this.name,
    required this.railDark,
    required this.railMid,
    required this.railLight,
    required this.surfaceLight,
    required this.surfaceDark,
    required this.lineColor,
    required this.accent,
    required this.accentLight,
    required this.accentDark,
    required this.ivory,
    required this.woodDeep,
    required this.sideColors,
    required this.sideColorNames,
  });
}

class RinkThemes {
  /// First 4 are the FREE starter themes. The rest are PRO.
  static const List<String> freeThemeIds = [
    'classic',
    'cherry',
    'maple',
    'heritage',
  ];

  static bool isProTheme(String id) => !freeThemeIds.contains(id);

  static const List<RinkThemeDef> all = [
    RinkThemeDef(
      id: 'classic',
      name: 'Classic Arcade',
      railDark: Color(0xFF3B2416),
      railMid: Color(0xFF5C3A21),
      railLight: Color(0xFF7A5230),
      surfaceLight: Color(0xFFF7F2E6),
      surfaceDark: Color(0xFFE3D8BE),
      lineColor: Color(0xFFA31621),
      accent: Color(0xFFC9A227),
      accentLight: Color(0xFFE8CE7A),
      accentDark: Color(0xFF8A6D1A),
      ivory: Color(0xFFF5EFE0),
      woodDeep: Color(0xFF241309),
      sideColors: [Color(0xFFA31621), Color(0xFF1D4E9E)],
      sideColorNames: ['Ruby', 'Sapphire'],
    ),
    RinkThemeDef(
      id: 'cherry',
      name: 'Cherry Classic',
      railDark: Color(0xFF4A1F14),
      railMid: Color(0xFF6E2F1C),
      railLight: Color(0xFF8F452A),
      surfaceLight: Color(0xFFFAF5EA),
      surfaceDark: Color(0xFFE8DCC4),
      lineColor: Color(0xFF1B7A4D),
      accent: Color(0xFFD4AF37),
      accentLight: Color(0xFFF3DC8E),
      accentDark: Color(0xFF96702A),
      ivory: Color(0xFFF8F1E2),
      woodDeep: Color(0xFF2B1009),
      sideColors: [Color(0xFF7D3C98), Color(0xFF1E8449)],
      sideColorNames: ['Amethyst', 'Jade'],
    ),
    RinkThemeDef(
      id: 'maple',
      name: 'Maple Hall',
      railDark: Color(0xFF8A6A3B),
      railMid: Color(0xFFB08D4F),
      railLight: Color(0xFFD4B47A),
      surfaceLight: Color(0xFFFFFFFF),
      surfaceDark: Color(0xFFEAE2CF),
      lineColor: Color(0xFF1D4E9E),
      accent: Color(0xFF1B6E4C),
      accentLight: Color(0xFF6FCF97),
      accentDark: Color(0xFF0F4A33),
      ivory: Color(0xFF2B2118),
      woodDeep: Color(0xFF4A3418),
      sideColors: [Color(0xFFD99A2B), Color(0xFFA31621)],
      sideColorNames: ['Amber', 'Ruby'],
    ),
    RinkThemeDef(
      id: 'heritage',
      name: 'Heritage Oak',
      railDark: Color(0xFF5A3A1E),
      railMid: Color(0xFF7D5628),
      railLight: Color(0xFF9E7438),
      surfaceLight: Color(0xFFF4EDDC),
      surfaceDark: Color(0xFFDFD2B2),
      lineColor: Color(0xFF6B2D1B),
      accent: Color(0xFFB0722A),
      accentLight: Color(0xFFE0A856),
      accentDark: Color(0xFF7A4E18),
      ivory: Color(0xFFF5EFE0),
      woodDeep: Color(0xFF33200E),
      sideColors: [Color(0xFF1B7A4D), Color(0xFFD99A2B)],
      sideColorNames: ['Emerald', 'Amber'],
    ),
    RinkThemeDef(
      id: 'midnight',
      name: 'Midnight Billiard',
      railDark: Color(0xFF1C2438),
      railMid: Color(0xFF2C3A55),
      railLight: Color(0xFF46587E),
      surfaceLight: Color(0xFF2E3D5C),
      surfaceDark: Color(0xFF1B2440),
      lineColor: Color(0xFFE8ECF5),
      accent: Color(0xFFC0C6D4),
      accentLight: Color(0xFFE8ECF5),
      accentDark: Color(0xFF7E8698),
      ivory: Color(0xFFF2EEE4),
      woodDeep: Color(0xFF101624),
      sideColors: [Color(0xFFD64545), Color(0xFF4A90D9)],
      sideColorNames: ['Candle', 'Moonstone'],
    ),
    RinkThemeDef(
      id: 'emerald',
      name: 'Emerald Club',
      railDark: Color(0xFF1E3327),
      railMid: Color(0xFF2F4F3C),
      railLight: Color(0xFF4A7357),
      surfaceLight: Color(0xFF3E6B52),
      surfaceDark: Color(0xFF274434),
      lineColor: Color(0xFFF5EFE0),
      accent: Color(0xFFD4AF37),
      accentLight: Color(0xFFF3DC8E),
      accentDark: Color(0xFF96702A),
      ivory: Color(0xFFF5EFE0),
      woodDeep: Color(0xFF101F16),
      sideColors: [Color(0xFFD99A2B), Color(0xFFA31621)],
      sideColorNames: ['Topaz', 'Garnet'],
    ),
    RinkThemeDef(
      id: 'burgundy',
      name: 'Burgundy Lounge',
      railDark: Color(0xFF3D1F2E),
      railMid: Color(0xFF5A2C42),
      railLight: Color(0xFF7A3E58),
      surfaceLight: Color(0xFF6E3B4E),
      surfaceDark: Color(0xFF472232),
      lineColor: Color(0xFFEFE3C8),
      accent: Color(0xFFD4AF37),
      accentLight: Color(0xFFF3DC8E),
      accentDark: Color(0xFF96702A),
      ivory: Color(0xFFF8F1E2),
      woodDeep: Color(0xFF241118),
      sideColors: [Color(0xFFC0392B), Color(0xFFD99A2B)],
      sideColorNames: ['Garnet', 'Topaz'],
    ),
    RinkThemeDef(
      id: 'graphite',
      name: 'Graphite Loft',
      railDark: Color(0xFF26262A),
      railMid: Color(0xFF3C3C42),
      railLight: Color(0xFF5A5A62),
      surfaceLight: Color(0xFF4E4E56),
      surfaceDark: Color(0xFF323238),
      lineColor: Color(0xFFE8E8EA),
      accent: Color(0xFFC9CCD4),
      accentLight: Color(0xFFEDEFF4),
      accentDark: Color(0xFF7E828C),
      ivory: Color(0xFFF2F0EA),
      woodDeep: Color(0xFF141416),
      sideColors: [Color(0xFFC0392B), Color(0xFF2980B9)],
      sideColorNames: ['Brick', 'Steel'],
    ),
    RinkThemeDef(
      id: 'sandstone',
      name: 'Sandstone Court',
      railDark: Color(0xFF7A5C38),
      railMid: Color(0xFF9C7A4E),
      railLight: Color(0xFFBC9A68),
      surfaceLight: Color(0xFFEFE0C2),
      surfaceDark: Color(0xFFD9C49A),
      lineColor: Color(0xFF5A3A1E),
      accent: Color(0xFF8A5A1E),
      accentLight: Color(0xFFD4A85C),
      accentDark: Color(0xFF5F3D12),
      ivory: Color(0xFF3A2A16),
      woodDeep: Color(0xFF4A3A1E),
      sideColors: [Color(0xFF1D4E9E), Color(0xFF1B7A4D)],
      sideColorNames: ['Sapphire', 'Jade'],
    ),
    RinkThemeDef(
      id: 'royal',
      name: 'Royal Navy',
      railDark: Color(0xFF14243E),
      railMid: Color(0xFF1F3A5E),
      railLight: Color(0xFF33537E),
      surfaceLight: Color(0xFF2A4A78),
      surfaceDark: Color(0xFF182C4E),
      lineColor: Color(0xFFF5EFE0),
      accent: Color(0xFFD4AF37),
      accentLight: Color(0xFFF3DC8E),
      accentDark: Color(0xFF96702A),
      ivory: Color(0xFFF5EFE0),
      woodDeep: Color(0xFF0C1626),
      sideColors: [Color(0xFFD99A2B), Color(0xFFC0392B)],
      sideColorNames: ['Crown', 'Scarlet'],
    ),
    RinkThemeDef(
      id: 'forest',
      name: 'Forest Lodge',
      railDark: Color(0xFF2E3B22),
      railMid: Color(0xFF4A5A34),
      railLight: Color(0xFF687E48),
      surfaceLight: Color(0xFFDCE5C8),
      surfaceDark: Color(0xFFB4C194),
      lineColor: Color(0xFF4A2E1C),
      accent: Color(0xFFB0722A),
      accentLight: Color(0xFFE0A856),
      accentDark: Color(0xFF7A4E18),
      ivory: Color(0xFF2B2118),
      woodDeep: Color(0xFF1A2312),
      sideColors: [Color(0xFF7D3C98), Color(0xFF1E8449)],
      sideColorNames: ['Plum', 'Pine'],
    ),
    RinkThemeDef(
      id: 'copper',
      name: 'Copper Works',
      railDark: Color(0xFF4A2A18),
      railMid: Color(0xFF7A4A26),
      railLight: Color(0xFFA86A3A),
      surfaceLight: Color(0xFFF1E4D0),
      surfaceDark: Color(0xFFDBC29E),
      lineColor: Color(0xFF6B3A1E),
      accent: Color(0xFFC77B3B),
      accentLight: Color(0xFFF0B57E),
      accentDark: Color(0xFF8A5226),
      ivory: Color(0xFFF5EFE0),
      woodDeep: Color(0xFF2B1708),
      sideColors: [Color(0xFF2980B9), Color(0xFFD99A2B)],
      sideColorNames: ['Cobalt', 'Brass'],
    ),
  ];

  static RinkThemeDef byId(String id, {RinkThemeDef? custom}) {
    if (id == 'custom' && custom != null) return custom;
    for (final t in all) {
      if (t.id == id) return t;
    }
    return all.first;
  }

  static List<RinkThemeDef> catalog({RinkThemeDef? custom}) {
    final list = List<RinkThemeDef>.of(all);
    if (custom != null) list.add(custom);
    return list;
  }
}

/// Mallet striker styles. First 4 are FREE, the rest are PRO.
class MalletStyleDef {
  final String name;
  final Color body;
  final Color grip;
  final Color base;

  const MalletStyleDef({
    required this.name,
    required this.body,
    required this.grip,
    required this.base,
  });
}

class MalletStyles {
  static const List<MalletStyleDef> all = [
    MalletStyleDef(
        name: 'Classic Red',
        body: Color(0xFFA31621),
        grip: Color(0xFF7A0E18),
        base: Color(0xFF3A2A1E)),
    MalletStyleDef(
        name: 'Ocean Blue',
        body: Color(0xFF1D4E9E),
        grip: Color(0xFF143A78),
        base: Color(0xFF2A2620)),
    MalletStyleDef(
        name: 'Forest Green',
        body: Color(0xFF1B7A4D),
        grip: Color(0xFF125C3A),
        base: Color(0xFF3A2A1E)),
    MalletStyleDef(
        name: 'Jet Black',
        body: Color(0xFF2B2B30),
        grip: Color(0xFF17171A),
        base: Color(0xFF4A4A50)),
    MalletStyleDef(
        name: 'Ivory',
        body: Color(0xFFF0EAD8),
        grip: Color(0xFFCFC4A8),
        base: Color(0xFF5A4A34)),
    MalletStyleDef(
        name: 'Crimson',
        body: Color(0xFFC0392B),
        grip: Color(0xFF96281B),
        base: Color(0xFF3A2A1E)),
    MalletStyleDef(
        name: 'Cobalt',
        body: Color(0xFF2980B9),
        grip: Color(0xFF1F6391),
        base: Color(0xFF2A2620)),
    MalletStyleDef(
        name: 'Slate',
        body: Color(0xFF5D6D7E),
        grip: Color(0xFF45525F),
        base: Color(0xFF2E3338)),
  ];

  static const int freeCount = 4;

  static bool isPro(int index) => index >= freeCount;

  static MalletStyleDef of(int index) =>
      all[index.clamp(0, all.length - 1)];
}

/// Puck styles. First 4 are FREE, the rest are PRO.
class PuckStyleDef {
  final String name;
  final Color body;
  final Color ring;

  const PuckStyleDef({
    required this.name,
    required this.body,
    required this.ring,
  });
}

class PuckStyles {
  static const List<PuckStyleDef> all = [
    PuckStyleDef(
        name: 'Tournament Red',
        body: Color(0xFFC0392B),
        ring: Color(0xFF96281B)),
    PuckStyleDef(
        name: 'Midnight Black',
        body: Color(0xFF2B2B30),
        ring: Color(0xFF121216)),
    PuckStyleDef(
        name: 'Ivory',
        body: Color(0xFFF0EAD8),
        ring: Color(0xFFCFC4A8)),
    PuckStyleDef(
        name: 'Cobalt',
        body: Color(0xFF2980B9),
        ring: Color(0xFF1F6391)),
    PuckStyleDef(
        name: 'Emerald',
        body: Color(0xFF1E8449),
        ring: Color(0xFF145A32)),
    PuckStyleDef(
        name: 'Amber',
        body: Color(0xFFD99A2B),
        ring: Color(0xFFA87418)),
    PuckStyleDef(
        name: 'Crimson',
        body: Color(0xFFA31621),
        ring: Color(0xFF7A0E18)),
    PuckStyleDef(
        name: 'Graphite',
        body: Color(0xFF5D6D7E),
        ring: Color(0xFF45525F)),
  ];

  static const int freeCount = 4;

  static bool isPro(int index) => index >= freeCount;

  static PuckStyleDef of(int index) =>
      all[index.clamp(0, all.length - 1)];
}
