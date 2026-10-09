import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/rink_art.dart';
import '../theme/rink_themes.dart';

/// Custom theme creator (PRO): design your own table from physical
/// material colors. Every change previews live and persists immediately.
class CustomThemeScreen extends StatelessWidget {
  final RinkAudio audio;
  final RinkSettings settings;
  const CustomThemeScreen(
      {super.key, required this.audio, required this.settings});

  static const _swatches = [
    0xFF3B2416, 0xFF5C3A21, 0xFF7A5230, 0xFF8A6A3B,
    0xFFB08D4F, 0xFF4A1F14, 0xFF6E2F1C, 0xFF1C2438,
    0xFF2C3A55, 0xFF1E3327, 0xFF3D1F2E, 0xFF26262A,
    0xFFF7F2E6, 0xFFE3D8BE, 0xFFFFFFFF, 0xFF2E3D5C,
    0xFFA31621, 0xFF1D4E9E, 0xFF1B7A4D, 0xFFD99A2B,
    0xFFC9A227, 0xFFE8CE7A, 0xFFC0C6D4, 0xFFF5EFE0,
  ];

  static const _fields = [
    ('railDark', 'Rail — dark edge'),
    ('railMid', 'Rail — main wood'),
    ('railLight', 'Rail — highlight'),
    ('surfaceLight', 'Surface — light'),
    ('surfaceDark', 'Surface — dark'),
    ('lineColor', 'Painted lines'),
    ('accent', 'Accent'),
    ('accentLight', 'Accent — light'),
    ('accentDark', 'Accent — dark'),
    ('ivory', 'Text'),
    ('woodDeep', 'Background'),
    ('side0', 'Home side color'),
    ('side1', 'Away side color'),
  ];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (_, _) {
        final t = RinkThemes.byId('custom', custom: settings.customTheme);
        return RinkBackdrop(
          theme: t,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: t.accentLight),
                onPressed: () {
                  audio.click();
                  Navigator.of(context).pop();
                },
              ),
              title:
                  Text('My Table Theme', style: Rink.display(22, theme: t)),
              actions: [
                TextButton(
                  onPressed: () {
                    audio.click();
                    settings.resetCustomColors();
                  },
                  child: Text('Reset',
                      style: Rink.label(13, theme: t)),
                ),
              ],
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                child: Column(
                  children: [
                    // Live preview: mini table.
                    Container(
                      height: 150,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: t.accent, width: 2.5),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        children: [
                          Column(
                            children: [
                              Expanded(
                                  flex: 2,
                                  child: Container(color: t.railMid)),
                              Expanded(
                                flex: 5,
                                child: Container(
                                  color: t.surfaceLight,
                                  child: Center(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: t.sideColors[0],
                                            border: Border.all(
                                                color: Colors.white70,
                                                width: 2),
                                          ),
                                        ),
                                        const SizedBox(width: 24),
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: t.sideColors[1],
                                            border: Border.all(
                                                color: Colors.white70,
                                                width: 2),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                  flex: 2,
                                  child: Container(color: t.railMid)),
                            ],
                          ),
                          Center(
                            child: Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: t.lineColor, width: 2.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    for (final f in _fields) ...[
                      _colorRow(context, t, f.$1, f.$2),
                      const SizedBox(height: 12),
                    ],
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _colorRow(
      BuildContext context, RinkThemeDef t, String key, String label) {
    final current = settings.customColors[key] ?? 0xFF000000;
    return RinkCard(
      title: label,
      theme: t,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final s in _swatches)
              GestureDetector(
                onTap: () {
                  audio.click();
                  settings.setCustomColor(key, s);
                },
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(s),
                    border: Border.all(
                      color: current == s
                          ? t.accentLight
                          : Colors.black.withValues(alpha: 0.4),
                      width: current == s ? 3 : 1.5,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
