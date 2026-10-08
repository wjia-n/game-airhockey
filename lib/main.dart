import 'package:flutter/material.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';
import 'game_screen.dart';

void main() => runApp(const AirHockeyApp());

class AirHockeyApp extends StatelessWidget {
  const AirHockeyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GameShell(
      variant: ShellVariant.neonArcade,
      title: 'Air Hockey',
      tagline: 'Slide the puck past your rival in fast air hockey',
      emoji: '🏒',
      slug: 'airhockey',
      howToPlay:
          '• Drag your mallet to smack the puck. First to 7 goals wins!\n• Your mallet stays on your half — defend your goal, attack theirs.\n• Bank shots off the walls for maximum style. 😎\n• Solo? Pick the bot\'s difficulty… if you dare. 🤖',
      playerOptions: const [1, 2],
      supportsBots: true,
      gameBuilder: (ctx, players, cb) => AirHockeyScreen(players: players, callbacks: cb),
    );
  }
}
