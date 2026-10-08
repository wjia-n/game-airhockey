import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';

/// Air Hockey - drag your mallet, smack the puck, first to 7 wins.
class AirHockeyScreen extends StatefulWidget {
  final List<Player> players;
  final GameCallbacks callbacks;

  const AirHockeyScreen({super.key, required this.players, required this.callbacks});

  @override
  State<AirHockeyScreen> createState() => _AirHockeyScreenState();
}

class _AirHockeyScreenState extends State<AirHockeyScreen> {
  final _rnd = Random();
  Timer? _timer;

  // puck
  double bx = 0.5, by = 0.5, vx = 0, vy = 0;
  // mallets: 0 = bottom (player 0), 1 = top (player 1)
  double m0x = 0.5, m0y = 0.78, m1x = 0.5, m1y = 0.22;
  double m0vx = 0, m0vy = 0, m1vx = 0, m1vy = 0;

  String phase = 'diff'; // diff | play | goal
  String banner = '';
  bool over = false;
  int difficulty = 1; // 0 chill, 1 classic, 2 beast

  static const _diffSpeed = [0.38, 0.58, 0.85];
  static const _diffNames = ['Chill 😌', 'Classic 🙂', 'Beast 🤖'];

  bool get hasBot => widget.players.any((p) => p.isBot);

  @override
  void initState() {
    super.initState();
    if (!hasBot) phase = 'play';
    _timer = Timer.periodic(const Duration(milliseconds: 16), _tick);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _tick(Timer t) {
    if (!mounted || over || phase != 'play') return;
    if (ModalRoute.of(context)?.isCurrent != true) return;
    const dt = 0.016;
    setState(() {
      // bot brain
      if (widget.players[1].isBot) _botMove(dt);
      // friction
      vx *= (1 - 0.45 * dt);
      vy *= (1 - 0.45 * dt);
      // cap speed
      final sp = sqrt(vx * vx + vy * vy);
      if (sp > 1.4) { vx *= 1.4 / sp; vy *= 1.4 / sp; }
      bx += vx * dt;
      by += vy * dt;
      // side walls
      if (bx < 0.035) { bx = 0.035; vx = -vx; }
      if (bx > 0.965) { bx = 0.965; vx = -vx; }
      // top/bottom: goal mouth or bounce
      final inMouth = (bx - 0.5).abs() < 0.17;
      if (by < 0.02) {
        if (inMouth) { _goal(0); return; }
        by = 0.02; vy = -vy;
      }
      if (by > 0.98) {
        if (inMouth) { _goal(1); return; }
        by = 0.98; vy = -vy;
      }
      _collide(0, m0x, m0y, m0vx, m0vy);
      _collide(1, m1x, m1y, m1vx, m1vy);
    });
  }

  void _collide(int who, double mx, double my, double mvx, double mvy) {
    const pr = 0.030, mr = 0.052;
    final dx = bx - mx, dy = by - my;
    final dist = sqrt(dx * dx + dy * dy);
    if (dist < pr + mr && dist > 0.0001) {
      final nx = dx / dist, ny = dy / dist;
      bx = mx + nx * (pr + mr);
      by = my + ny * (pr + mr);
      final rvx = vx - mvx, rvy = vy - mvy;
      final vn = rvx * nx + rvy * ny;
      if (vn < 0) {
        vx -= 1.9 * vn * nx;
        vy -= 1.9 * vn * ny;
        vx += mvx * 0.9;
        vy += mvy * 0.9;
        Sfx.tap();
      }
    }
  }

  void _botMove(double dt) {
    final speed = _diffSpeed[difficulty];
    double tx, ty;
    final puckComing = vy < -0.05;
    if (by < 0.5 && (puckComing || (vx * vx + vy * vy) < 0.02)) {
      // attack: get behind the puck, aim at player's goal
      tx = (bx + (bx - 0.5) * 0.25).clamp(0.07, 0.93);
      ty = (by - 0.09).clamp(0.07, 0.44);
    } else {
      // defend home, shadow the puck
      tx = (0.5 + (bx - 0.5) * 0.55).clamp(0.07, 0.93);
      ty = 0.22;
    }
    final dx = tx - m1x, dy = ty - m1y;
    final d = sqrt(dx * dx + dy * dy);
    final step = min(d, speed * dt);
    m1vx = d > 0.0001 ? dx / d * step / dt : 0;
    m1vy = d > 0.0001 ? dy / d * step / dt : 0;
    m1x += d > 0.0001 ? dx / d * step : 0;
    m1y += d > 0.0001 ? dy / d * step : 0;
  }

  void _goal(int scorer) {
    widget.players[scorer].score += 1;
    widget.callbacks.refreshHud();
    if (widget.players[scorer].score >= 7) {
      _finish(scorer);
      return;
    }
    Sfx.win();
    setState(() {
      phase = 'goal';
      banner = 'GOAL! ${widget.players[scorer].name} 🥅';
      bx = 0.5; by = 0.5; vx = 0; vy = 0;
      m0x = 0.5; m0y = 0.78; m1x = 0.5; m1y = 0.22;
    });
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted || over) return;
      setState(() {
        phase = 'play';
        banner = '';
        final a = _rnd.nextDouble() * pi * 2;
        vx = cos(a) * 0.25;
        vy = sin(a) * 0.25;
      });
    });
  }

  void _finish(int w) {
    setState(() => over = true);
    Sfx.win();
    final p = widget.players[w];
    widget.callbacks.finish(
      winner: p,
      headline: '${p.name} wins ${p.score}–${widget.players[1 - w].score}! 🏆',
      subline: 'Absolute puck wizardry. 🧙',
    );
  }

  void _dragMallet(DragUpdateDetails d, Size size, int who) {
    if (over || phase != 'play') return;
    if (widget.players[who].isBot) return;
    final nx = (d.localPosition.dx / size.width).clamp(0.06, 0.94);
    final ny = (d.localPosition.dy / size.height).clamp(
        who == 0 ? 0.56 : 0.06, who == 0 ? 0.94 : 0.44);
    setState(() {
      if (who == 0) {
        m0vx = (nx - m0x) / 0.016; m0vy = (ny - m0y) / 0.016;
        m0x = nx; m0y = ny;
      } else {
        m1vx = (nx - m1x) / 0.016; m1vy = (ny - m1y) / 0.016;
        m1x = nx; m1y = ny;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = ThemeController.of(context).theme;
    if (phase == 'diff') {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🤖', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 12),
              Text('How spicy should the bot be?',
                  style: TextStyle(color: t.text, fontSize: 20, fontWeight: FontWeight.w800),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              for (int i = 0; i < 3; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: WajihaButton(
                    label: _diffNames[i],
                    emoji: '',
                    primary: i == 1,
                    onTap: () {
                      Sfx.click();
                      setState(() {
                        difficulty = i;
                        phase = 'play';
                      });
                      widget.callbacks.setActivePlayer(0);
                    },
                  ),
                ),
            ],
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Text('${widget.players[0].score}  —  ${widget.players[1].score}',
              style: TextStyle(color: t.text, fontSize: 30, fontWeight: FontWeight.w900)),
          Text('First to 7', style: TextStyle(color: t.muted, fontSize: 12)),
          const SizedBox(height: 6),
          if (banner.isNotEmpty)
            Text(banner,
                style: TextStyle(color: t.accent, fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Expanded(
            child: LayoutBuilder(
              builder: (ctx, c) {
                final size = Size(c.maxWidth, c.maxHeight);
                return GestureDetector(
                  onPanUpdate: (d) {
                    final top = d.localPosition.dy < size.height * 0.5;
                    _dragMallet(d, size, top ? 1 : 0);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: t.surface,
                      borderRadius: t.radius,
                      border: Border.all(color: t.primary.withValues(alpha: 0.3), width: 2),
                    ),
                    child: Stack(
                      children: [
                        // center line + circle
                        Positioned(
                          left: 8, right: 8, top: size.height * 0.5 - 1,
                          child: Container(height: 2, color: t.muted.withValues(alpha: 0.5)),
                        ),
                        Positioned(
                          left: size.width * 0.5 - 40, top: size.height * 0.5 - 40,
                          child: Container(
                            width: 80, height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: t.muted.withValues(alpha: 0.5), width: 2),
                            ),
                          ),
                        ),
                        // goals
                        Positioned(
                          left: size.width * 0.33, top: 0, width: size.width * 0.34, height: 10,
                          child: Container(
                            decoration: BoxDecoration(
                              color: widget.players[1].color,
                              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(6)),
                            ),
                          ),
                        ),
                        Positioned(
                          left: size.width * 0.33, bottom: 0, width: size.width * 0.34, height: 10,
                          child: Container(
                            decoration: BoxDecoration(
                              color: widget.players[0].color,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                            ),
                          ),
                        ),
                        // puck
                        Positioned(
                          left: bx * size.width - 15, top: by * size.height - 15,
                          child: Container(
                            width: 30, height: 30,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: t.text,
                              boxShadow: [BoxShadow(color: t.text.withValues(alpha: 0.4), blurRadius: 8)],
                            ),
                          ),
                        ),
                        // mallets
                        _mallet(size, m0x, m0y, widget.players[0].color),
                        _mallet(size, m1x, m1y, widget.players[1].color),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          Text('Drag your mallet • smack the puck into their goal 🥅',
              style: TextStyle(color: t.muted, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _mallet(Size size, double x, double y, Color color) {
    return Positioned(
      left: x * size.width - 26, top: y * size.height - 26,
      child: Container(
        width: 52, height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(color: Colors.white.withValues(alpha: 0.7), width: 3),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 10)],
        ),
        child: Center(
          child: Container(
            width: 18, height: 18,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
