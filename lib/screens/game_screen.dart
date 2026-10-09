import 'package:flutter/material.dart';
import '../engine/airhockey_engine.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/rink_art.dart';
import '../theme/rink_themes.dart';

const _difficultyNames = ['Rookie', 'Skilled', 'Champion'];

/// The match screen: painted wooden table, drag mallets, puck physics,
/// goal celebrations, pause/resume, victory flow.
class GameScreen extends StatefulWidget {
  final AirHockeyEngine engine;
  final RinkAudio audio;
  final RinkSettings settings;

  const GameScreen({
    super.key,
    required this.engine,
    required this.audio,
    required this.settings,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  final _tableKey = GlobalKey();
  bool _victoryShown = false;
  bool _pausedByLifecycle = false;

  AirHockeyEngine get _e => widget.engine;
  RinkSettings get _s => widget.settings;
  RinkThemeDef get _t => RinkThemes.byId(_s.themeId, custom: _s.customTheme);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.audio.startGameMusic();
    _e.onEvent = _onEngineEvent;
    _e.addListener(_onEngineChanged);
  }

  void _onEngineEvent(MatchEvent e) {
    switch (e) {
      case MatchEvent.serve:
        widget.audio.beep();
      case MatchEvent.hit:
        widget.audio.hit();
      case MatchEvent.wall:
        widget.audio.wall();
      case MatchEvent.goal:
        widget.audio.goal();
      case MatchEvent.win:
        _onMatchEnd();
    }
  }

  void _onEngineChanged() {
    if (_e.over && !_victoryShown) {
      _victoryShown = true;
      // Let the final frame + horn land before the dialog.
      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted) _showVictory();
      });
    }
  }

  void _onMatchEnd() {
    final w = _e.winner ?? 0;
    final winnerIsHuman = !_e.players[w].isBot;
    if (winnerIsHuman) {
      widget.audio.win();
    } else {
      widget.audio.lose();
    }
    // Stats: side 0 is always a human side.
    _s.recordGame(humanWon: winnerIsHuman, humanGoals: _e.players[0].score);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _e.removeListener(_onEngineChanged);
    _e.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Freeze the match on interruption; resume keeps the phase timers.
    // A match the user paused manually stays paused.
    if (state == AppLifecycleState.paused) {
      _pausedByLifecycle = !_e.over && !_e.paused;
      _e.setPaused(true);
    } else if (state == AppLifecycleState.resumed) {
      if (_pausedByLifecycle && !_e.over) {
        _pausedByLifecycle = false;
        _e.setPaused(false);
      }
    }
  }

  void _dragAt(Offset global) {
    final ctx = _tableKey.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject() as RenderBox;
    final local = box.globalToLocal(global);
    final nx = (local.dx / box.size.width).clamp(0.0, 1.0);
    final ny = (local.dy / box.size.height).clamp(0.0, 1.0);
    _e.dragSide(ny < 0.5 ? 1 : 0, nx, ny);
  }

  void _showVictory() {
    final w = _e.winner ?? 0;
    final p = _e.players[w];
    final q = _e.players[1 - w];
    final t = _t;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient:
                LinearGradient(colors: [t.railMid, t.railDark]),
            border: Border.all(color: t.accent, width: 2.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🏆', style: const TextStyle(fontSize: 54)),
              const SizedBox(height: 8),
              Text('${p.name} wins!',
                  style: Rink.display(30, theme: t),
                  textAlign: TextAlign.center),
              const SizedBox(height: 6),
              Text('${p.score}  —  ${q.score}',
                  style: Rink.display(40, theme: t)),
              const SizedBox(height: 6),
              Text('First to ${AirHockeyEngine.winScore}',
                  style: Rink.body(13, theme: t)),
              const SizedBox(height: 20),
              RinkButton(
                label: '🔄  Rematch',
                theme: t,
                width: 220,
                onTap: () {
                  widget.audio.click();
                  Navigator.of(context).pop();
                  setState(() => _victoryShown = false);
                  _e.restart();
                },
              ),
              const SizedBox(height: 10),
              RinkButton(
                label: 'Menu',
                theme: t,
                width: 220,
                primary: false,
                onTap: () {
                  widget.audio.click();
                  Navigator.of(context).pop(); // dialog
                  Navigator.of(context).pop(); // game screen
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    return RinkBackdrop(
      theme: t,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: ListenableBuilder(
            listenable: _e,
            builder: (_, _) => Column(
              children: [
                _topBar(t),
                _sideStrip(t, side: 1),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    child: GestureDetector(
                      key: _tableKey,
                      onPanDown: (d) => _dragAt(d.globalPosition),
                      onPanUpdate: (d) => _dragAt(d.globalPosition),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _TablePainter(
                                engine: _e,
                                theme: t,
                                mallet: MalletStyles.of(_s.malletStyle),
                                puck: PuckStyles.of(_s.puckStyle),
                              ),
                            ),
                          ),
                          if (_e.banner.isNotEmpty)
                            Center(child: _banner(t)),
                          if (_e.paused && !_e.over)
                            Center(child: _pausedOverlay(t)),
                        ],
                      ),
                    ),
                  ),
                ),
                _sideStrip(t, side: 0),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _topBar(RinkThemeDef t) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: t.accentLight),
            onPressed: () {
              widget.audio.click();
              Navigator.of(context).pop();
            },
          ),
          const Spacer(),
          Text('First to ${AirHockeyEngine.winScore}',
              style: Rink.label(13, theme: t)),
          const Spacer(),
          IconButton(
            icon: Icon(
              _e.paused ? Icons.play_arrow : Icons.pause,
              color: t.accentLight,
            ),
            onPressed: () {
              widget.audio.click();
              _e.setPaused(!_e.paused);
            },
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: t.accentLight),
            onPressed: () {
              widget.audio.click();
              _victoryShown = false;
              _e.restart();
            },
          ),
        ],
      ),
    );
  }

  /// Per-side score strip. The active/human sides are never ambiguous:
  /// the top strip belongs to the top side, the bottom strip to the bottom.
  Widget _sideStrip(RinkThemeDef t, {required int side}) {
    final p = _e.players[side];
    final isBot = p.isBot;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.black.withValues(alpha: 0.35),
        border: Border.all(color: p.color.withValues(alpha: 0.7), width: 2),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: p.color,
              border:
                  Border.all(color: t.ivory.withValues(alpha: 0.7), width: 2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(p.name,
                    style: Rink.label(15, theme: t),
                    overflow: TextOverflow.ellipsis),
                if (isBot)
                  Text('AI • ${_difficultyNames[_s.difficulty]}',
                      style: Rink.body(11,
                          theme: t,
                          color: t.ivory.withValues(alpha: 0.65))),
                if (!isBot && side == 0 && _s.mode == 1)
                  Text('Your mallet — bottom half',
                      style: Rink.body(11,
                          theme: t,
                          color: t.ivory.withValues(alpha: 0.65))),
                if (!isBot && side == 1 && _s.mode == 1)
                  Text('Your mallet — top half',
                      style: Rink.body(11,
                          theme: t,
                          color: t.ivory.withValues(alpha: 0.65))),
              ],
            ),
          ),
          Text('${p.score}',
              style: Rink.display(32, theme: t, color: p.color)),
        ],
      ),
    );
  }

  Widget _banner(RinkThemeDef t) {
    final isGoal = _e.phase == MatchPhase.goal;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.black.withValues(alpha: 0.62),
        border: Border.all(color: t.accent, width: 2.5),
      ),
      child: Text(
        _e.banner,
        style: Rink.display(isGoal ? 40 : 24, theme: t),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _pausedOverlay(RinkThemeDef t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.black.withValues(alpha: 0.72),
        border: Border.all(color: t.accent, width: 2.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Paused', style: Rink.display(30, theme: t)),
          const SizedBox(height: 12),
          RinkButton(
            label: '▶  Resume',
            theme: t,
            width: 190,
            onTap: () {
              widget.audio.click();
              _e.setPaused(false);
            },
          ),
        ],
      ),
    );
  }
}

/// Paints the wooden table, lines, goal mouths, mallets and puck with
/// physical depth: rail bevels, surface vignette, soft contact shadows.
class _TablePainter extends CustomPainter {
  final AirHockeyEngine engine;
  final RinkThemeDef theme;
  final MalletStyleDef mallet;
  final PuckStyleDef puck;

  _TablePainter({
    required this.engine,
    required this.theme,
    required this.mallet,
    required this.puck,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    const rail = 26.0; // rail thickness in px
    final t = theme;
    final e = engine;

    // Outer rail body with bevel highlight.
    final railRect = RRect.fromLTRBR(
        0, 0, w, h, const Radius.circular(30));
    canvas.drawRRect(
        railRect, Paint()..color = t.railDark);
    final railBody = RRect.fromLTRBR(
        3, 3, w - 3, h - 3, const Radius.circular(27));
    final railPaint = Paint()
      ..shader = LinearGradient(
        colors: [t.railLight, t.railMid, t.railDark],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRRect(railBody, railPaint);

    // Playing surface with a soft vertical falloff (polished laminate).
    final surf = RRect.fromLTRBR(
        rail, rail, w - rail, h - rail, const Radius.circular(16));
    final surfPaint = Paint()
      ..shader = LinearGradient(
        colors: [t.surfaceLight, t.surfaceDark],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(rail, rail, w - 2 * rail, h - 2 * rail));
    canvas.drawRRect(surf, surfPaint);
    // Inner rail shadow (ambient occlusion under the rail lip).
    canvas.drawRRect(
        surf,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..color = Colors.black.withValues(alpha: 0.35));

    final sx = w - 2 * rail, sy = h - 2 * rail;
    Offset pt(double nx, double ny) =>
        Offset(rail + nx * sx, rail + ny * sy);

    // Painted lines.
    final linePaint = Paint()
      ..color = t.lineColor.withValues(alpha: 0.85)
      ..strokeWidth = 3;
    canvas.drawLine(pt(0.06, 0.5), pt(0.94, 0.5), linePaint);
    canvas.drawCircle(pt(0.5, 0.5), sx * 0.11,
        Paint()..style = PaintingStyle.stroke..strokeWidth = 3..color = t.lineColor.withValues(alpha: 0.85));
    canvas.drawCircle(pt(0.5, 0.5), 5,
        Paint()..color = t.lineColor.withValues(alpha: 0.85));
    // Face-off dots.
    for (final fx in [0.25, 0.75]) {
      for (final fy in [0.28, 0.72]) {
        canvas.drawCircle(pt(fx, fy), 4,
            Paint()..color = t.lineColor.withValues(alpha: 0.5));
      }
    }

    // Goal mouths: slots cut into the rails, dark goal boxes with net lines.
    final mouthW = sx * AirHockeyEngine.goalHalfWidth * 2;
    for (final top in [true, false]) {
      final gx = w / 2 - mouthW / 2;
      final gy = top ? 0.0 : h - 22.0;
      final goalRect = RRect.fromLTRBR(
          gx, gy, gx + mouthW, gy + 22, const Radius.circular(6));
      canvas.drawRRect(goalRect, Paint()..color = const Color(0xFF120B06));
      final netPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.25)
        ..strokeWidth = 1;
      for (double lx = gx + 5; lx < gx + mouthW; lx += 9) {
        canvas.drawLine(Offset(lx, gy + 2), Offset(lx, gy + 20), netPaint);
      }
      // Goal flash ring during celebration.
      if (e.phase == MatchPhase.goal && e.goalT > 0) {
        final flashR = 30 + e.goalT * 90;
        canvas.drawCircle(
            Offset(w / 2, top ? 6 : h - 6),
            flashR,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 5 * (1 - e.goalT)
              ..color = t.accent.withValues(alpha: 0.8 * (1 - e.goalT)));
      }
    }

    // Puck shadow + body.
    final pp = pt(e.px, e.py);
    final pr = sx * AirHockeyEngine.puckR;
    _shadow(canvas, pp + const Offset(3, 5), pr);
    canvas.drawCircle(pp, pr, Paint()..color = puck.body);
    canvas.drawCircle(
        pp,
        pr,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = puck.ring);
    canvas.drawCircle(pp + Offset(-pr * 0.3, -pr * 0.3), pr * 0.28,
        Paint()..color = Colors.white.withValues(alpha: 0.35));

    // Mallets: felt base, wooden/plastic body, grip knob.
    for (int i = 0; i < 2; i++) {
      final mp = pt(e.mx[i], e.my[i]);
      final mr = sx * AirHockeyEngine.malletR;
      final body = i == 0 ? mallet.body : _altMallet(i);
      _shadow(canvas, mp + const Offset(4, 7), mr);
      // Felt base ring.
      canvas.drawCircle(mp, mr, Paint()..color = mallet.base);
      // Body with top-light shading.
      final bodyPaint = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.4),
          radius: 1.1,
          colors: [_lighten(body, 0.25), body, _darken(body, 0.25)],
        ).createShader(Rect.fromCircle(center: mp, radius: mr * 0.92));
      canvas.drawCircle(mp, mr * 0.92, bodyPaint);
      // Grip knob.
      final gripPaint = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.35),
          colors: [_lighten(mallet.grip, 0.3), mallet.grip],
        ).createShader(Rect.fromCircle(center: mp, radius: mr * 0.42));
      canvas.drawCircle(mp, mr * 0.42, gripPaint);
      canvas.drawCircle(
          mp,
          mr * 0.16,
          Paint()..color = Colors.white.withValues(alpha: 0.5));
    }
  }

  /// Second side uses the theme's side color so each table theme re-tints
  /// the away mallet while the chosen style shapes the home one.
  Color _altMallet(int i) {
    if (i == 0) return mallet.body;
    return theme.sideColors[1];
  }

  void _shadow(Canvas canvas, Offset c, double r) {
    canvas.drawCircle(
        c, r, Paint()..color = Colors.black.withValues(alpha: 0.30));
  }

  Color _lighten(Color c, double amt) {
    final v = (amt * 255).round();
    return Color.fromARGB(
      (c.a * 255).round().clamp(0, 255),
      (c.r * 255 + v).clamp(0, 255).toInt(),
      (c.g * 255 + v).clamp(0, 255).toInt(),
      (c.b * 255 + v).clamp(0, 255).toInt(),
    );
  }

  Color _darken(Color c, double amt) {
    final v = (amt * 255).round();
    return Color.fromARGB(
      (c.a * 255).round().clamp(0, 255),
      (c.r * 255 - v).clamp(0, 255).toInt(),
      (c.g * 255 - v).clamp(0, 255).toInt(),
      (c.b * 255 - v).clamp(0, 255).toInt(),
    );
  }

  @override
  bool shouldRepaint(covariant _TablePainter old) => true;
}
