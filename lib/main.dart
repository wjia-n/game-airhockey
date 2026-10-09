import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/splash_screen.dart';
import 'services/audio_service.dart';
import 'services/settings_service.dart';
import 'theme/rink_art.dart';
import 'theme/rink_themes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Air hockey is a portrait table: goals at top and bottom.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  final settings = RinkSettings();
  await settings.load();
  final audio = RinkAudio();
  audio.configure(
    musicOn: settings.musicOn,
    sfxOn: settings.sfxOn,
    volume: settings.volume,
  );
  runApp(AirHockeyApp(settings: settings, audio: audio));
}

class AirHockeyApp extends StatefulWidget {
  final RinkSettings settings;
  final RinkAudio audio;
  const AirHockeyApp({super.key, required this.settings, required this.audio});

  @override
  State<AirHockeyApp> createState() => _AirHockeyAppState();
}

class _AirHockeyAppState extends State<AirHockeyApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.audio.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pause (not stop) on interruption so music resumes exactly where it
    // left off; the game screen additionally freezes its engine.
    if (state == AppLifecycleState.paused) {
      widget.audio.onAppPaused();
    } else if (state == AppLifecycleState.resumed) {
      widget.audio.onAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.settings,
      builder: (_, _) => MaterialApp(
        title: 'Air Hockey',
        debugShowCheckedModeBanner: false,
        theme: Rink.theme(RinkThemes.byId(widget.settings.themeId,
            custom: widget.settings.customTheme)),
        home: SplashScreen(audio: widget.audio, settings: widget.settings),
      ),
    );
  }
}
