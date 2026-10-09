import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/rink_art.dart';
import '../theme/rink_themes.dart';

/// Settings: music/SFX toggles, volume, stats reset.
class SettingsScreen extends StatelessWidget {
  final RinkAudio audio;
  final RinkSettings settings;
  const SettingsScreen(
      {super.key, required this.audio, required this.settings});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (_, _) {
        final t = RinkThemes.byId(settings.themeId,
            custom: settings.customTheme);
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
              title: Text('Settings', style: Rink.display(22, theme: t)),
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                child: Column(
                  children: [
                    RinkCard(
                      title: '🔊  Audio',
                      theme: t,
                      children: [
                        _toggle(
                          t,
                          'Music',
                          settings.musicOn,
                          (v) {
                            audio.click();
                            audio.configure(
                                musicOn: v,
                                sfxOn: settings.sfxOn,
                                volume: settings.volume);
                            settings.setMusic(v);
                            if (v) {
                              audio.startMenuMusic();
                            }
                          },
                        ),
                        _toggle(
                          t,
                          'Sound effects',
                          settings.sfxOn,
                          (v) {
                            settings.setSfx(v);
                            audio.configure(
                                musicOn: settings.musicOn,
                                sfxOn: v,
                                volume: settings.volume);
                            if (v) audio.click();
                          },
                        ),
                        const SizedBox(height: 8),
                        Text('Volume', style: Rink.body(14, theme: t)),
                        Slider(
                          value: settings.volume,
                          min: 0,
                          max: 1,
                          activeColor: t.accent,
                          inactiveColor:
                              t.accent.withValues(alpha: 0.3),
                          onChanged: (v) {
                            settings.setVolume(v);
                            audio.configure(
                                musicOn: settings.musicOn,
                                sfxOn: settings.sfxOn,
                                volume: v);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    RinkCard(
                      title: '📊  Stats',
                      theme: t,
                      children: [
                        Text(
                          'Wins: ${settings.wins}   •   Games: ${settings.gamesPlayed}   •   Goals: ${settings.goalsScored}',
                          style: Rink.body(14, theme: t),
                        ),
                        const SizedBox(height: 12),
                        RinkButton(
                          label: 'Reset stats',
                          theme: t,
                          width: 200,
                          primary: false,
                          onTap: () {
                            audio.click();
                            settings.resetStats();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Stats cleared.',
                                    style: Rink.body(14, theme: t)),
                                backgroundColor: t.woodDeep,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
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

  Widget _toggle(RinkThemeDef t, String label, bool value,
      ValueChanged<bool> onChanged) {
    return Row(
      children: [
        Expanded(child: Text(label, style: Rink.body(15, theme: t))),
        Switch(
          value: value,
          activeThumbColor: t.accentLight,
          activeTrackColor: t.accentDark,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
