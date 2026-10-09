import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A side in the match: bottom (index 0) or top (index 1).
class AirPlayer {
  final String name;
  final Color color;
  final bool isBot;
  int score = 0;

  AirPlayer({required this.name, required this.color, required this.isBot});
}

/// Bot skill tiers (RULES.md §11). Champion is a Pro feature.
enum BotDifficulty { rookie, skilled, champion }

/// Match phases owned entirely by the engine. The UI only renders.
/// [serve] = puck is centered, play resumes shortly. [goal] = goal
/// celebration, input locked, serve follows. [over] = match finished.
enum MatchPhase { serve, play, goal, over }

/// Engine → UI/audio events. The screen/audio layer subscribes via [onEvent].
enum MatchEvent { serve, hit, wall, goal, win, lose }

/// Air Hockey engine: deterministic physics, match state machine, bot AI.
///
/// The engine owns ALL timing: the 60fps physics/AI tick, the single
/// phase-transition timer, and a 3-second watchdog that recovers any phase
/// found without a live timer. Stuck states are impossible by construction.
/// The UI only renders state and forwards drag input.
class AirHockeyEngine extends ChangeNotifier {
  final List<AirPlayer> players;
  final BotDifficulty botDifficulty;

  static const int winScore = 7;
  static const double puckR = 0.028;
  static const double malletR = 0.055;
  static const double goalHalfWidth = 0.16;
  static const double maxPuckSpeed = 1.7;
  static const double maxMalletSpeed = 2.6;

  MatchPhase phase = MatchPhase.serve;
  bool paused = false;
  bool over = false;
  int? winner;
  String banner = '';
  double goalT = 0; // 0..1 goal-celebration progress for the UI
  int lastScorer = -1;

  // Puck.
  double px = 0.5, py = 0.5, pvx = 0, pvy = 0;
  // Mallets: index 0 = bottom side, index 1 = top side.
  final List<double> mx = [0.5, 0.5];
  final List<double> my = [0.78, 0.22];
  final List<double> mvx = [0, 0];
  final List<double> mvy = [0, 0];

  MatchEvent? _lastEvent;
  void Function(MatchEvent event)? onEvent;

  final _rand = Random();
  Timer? _tick; // 60fps physics + AI loop
  Timer? _timer; // single phase-transition timer
  Timer? _watchdog; // stuck-state recovery
  bool _disposed = false;
  double _aiThink = 0; // accumulated time since last AI decision
  double _aiTx = 0.5, _aiTy = 0.2; // current AI target
  double _deadPuckT = 0; // seconds the puck has been nearly still

  static const _aiSpeed = [0.5, 0.95, 1.35];
  static const _aiThinkInterval = [0.45, 0.2, 0.1];

  AirHockeyEngine({required this.players, required this.botDifficulty}) {
    banner = 'Get ready…';
    _tick = Timer.periodic(
        const Duration(milliseconds: 16), (_) => _step(1 / 60));
    _watchdog = Timer.periodic(const Duration(seconds: 3), (_) => _recover());
    _arm(const Duration(milliseconds: 1000), _startPlay);
  }

  bool get _botTop => players[1].isBot;

  @override
  void dispose() {
    _disposed = true;
    _tick?.cancel();
    _timer?.cancel();
    _watchdog?.cancel();
    super.dispose();
  }

  void _arm(Duration d, void Function() fn) {
    if (_disposed || paused) return;
    _timer?.cancel();
    _timer = Timer(d, () {
      _timer = null;
      if (!_disposed && !paused) fn();
    });
  }

  /// Pause: freeze physics and the phase timer. Resume re-arms the phase.
  void setPaused(bool v) {
    if (paused == v || _disposed || over) return;
    paused = v;
    if (v) {
      _tick?.cancel();
      _tick = null;
      _timer?.cancel();
      _timer = null;
    } else {
      _tick ??= Timer.periodic(
          const Duration(milliseconds: 16), (_) => _step(1 / 60));
      _recover();
    }
    notifyListeners();
  }

  /// Watchdog: if a phase timer ever dies without progress, recover.
  /// Makes stuck states impossible by construction. Respects [paused].
  void _recover() {
    if (_disposed || over || paused || _timer != null) return;
    _tick ??= Timer.periodic(
        const Duration(milliseconds: 16), (_) => _step(1 / 60));
    if (phase == MatchPhase.serve) {
      _startPlay();
    } else if (phase == MatchPhase.goal) {
      _serve();
    }
    // phase == play needs no timer: the tick loop drives it.
  }

  /// Restart the whole match.
  void restart() {
    if (_disposed) return;
    for (final p in players) {
      p.score = 0;
    }
    over = false;
    winner = null;
    lastScorer = -1;
    goalT = 0;
    _serve();
    notifyListeners();
  }

  void _serve() {
    phase = MatchPhase.serve;
    banner = 'Get ready…';
    px = 0.5;
    py = 0.5;
    pvx = 0;
    pvy = 0;
    goalT = 0;
    _deadPuckT = 0;
    mx[0] = 0.5;
    my[0] = 0.78;
    mx[1] = 0.5;
    my[1] = 0.22;
    mvx[0] = mvy[0] = mvx[1] = mvy[1] = 0;
    _arm(const Duration(milliseconds: 1000), _startPlay);
    notifyListeners();
  }

  void _startPlay() {
    if (_disposed || paused || over) return;
    phase = MatchPhase.play;
    banner = '';
    // Serve the puck toward the side that just conceded (or random on the
    // opening serve) so they reach it first — fair and never ambiguous.
    double dir;
    if (lastScorer < 0) {
      dir = _rand.nextBool() ? 1 : -1;
    } else {
      dir = lastScorer == 0 ? -1 : 1; // toward the conceder's half
    }
    final ang = (_rand.nextDouble() - 0.5) * 0.6;
    pvx = sin(ang) * 0.5;
    pvy = dir * cos(ang) * 0.5;
    _emit(MatchEvent.serve);
    notifyListeners();
  }

  void _goal(int scorer) {
    lastScorer = scorer;
    players[scorer].score += 1;
    _emit(MatchEvent.goal);
    if (players[scorer].score >= winScore) {
      over = true;
      winner = scorer;
      phase = MatchPhase.over;
      banner = '${players[scorer].name} wins!';
      // The screen maps this to a win or lose sound: it knows which
      // sides are human.
      _emit(MatchEvent.win);
      notifyListeners();
      return;
    }
    phase = MatchPhase.goal;
    banner = 'GOAL!  ${players[scorer].name}';
    goalT = 0;
    _arm(const Duration(milliseconds: 1600), _serve);
    notifyListeners();
  }

  void _emit(MatchEvent e) {
    _lastEvent = e;
    onEvent?.call(e);
  }

  /// The most recent engine event (handy for tests).
  @visibleForTesting
  MatchEvent? get lastEvent => _lastEvent;

  /// Human drag input. Side 0 = bottom half, side 1 = top half.
  /// Ignored for bot sides, while paused, or outside live play.
  void dragSide(int side, double nx, double ny) {
    if (_disposed ||
        paused ||
        over ||
        phase != MatchPhase.play ||
        players[side].isBot) {
      return;
    }
    const dt = 1 / 60;
    final cx = nx.clamp(malletR, 1 - malletR);
    double cy;
    if (side == 0) {
      cy = ny.clamp(0.5 + malletR * 0.4, 1 - malletR);
    } else {
      cy = ny.clamp(malletR, 0.5 - malletR * 0.4);
    }
    final vx = ((cx - mx[side]) / dt).clamp(-maxMalletSpeed, maxMalletSpeed);
    final vy = ((cy - my[side]) / dt).clamp(-maxMalletSpeed, maxMalletSpeed);
    mvx[side] = vx;
    mvy[side] = vy;
    mx[side] = cx;
    my[side] = cy;
  }

  // ------------------------------------------------------------ physics tick
  void _step(double dt) {
    if (_disposed || paused || over) return;
    if (phase == MatchPhase.play) {
      if (_botTop) _aiStep(dt);
      _physics(dt);
      // Dead-puck guard: a puck nobody can reach must never stall a match.
      final sp = sqrt(pvx * pvx + pvy * pvy);
      if (sp < 0.03) {
        _deadPuckT += dt;
        if (_deadPuckT > 6) {
          _deadPuckT = 0;
          pvx = (_rand.nextDouble() - 0.5) * 0.4;
          pvy = (_rand.nextBool() ? 1 : -1) * 0.35;
        }
      } else {
        _deadPuckT = 0;
      }
    } else if (phase == MatchPhase.goal) {
      goalT = (goalT + dt / 1.6).clamp(0.0, 1.0);
    }
    notifyListeners();
  }

  void _physics(double dt) {
    // Air friction.
    final f = (1 - 0.55 * dt);
    pvx *= f;
    pvy *= f;
    // Cap puck speed.
    final sp = sqrt(pvx * pvx + pvy * pvy);
    if (sp > maxPuckSpeed) {
      pvx *= maxPuckSpeed / sp;
      pvy *= maxPuckSpeed / sp;
    }
    px += pvx * dt;
    py += pvy * dt;
    // Side rails.
    if (px < puckR) {
      px = puckR;
      if (pvx < -0.15) _emit(MatchEvent.wall);
      pvx = -pvx;
    }
    if (px > 1 - puckR) {
      px = 1 - puckR;
      if (pvx > 0.15) _emit(MatchEvent.wall);
      pvx = -pvx;
    }
    // End lines: goal mouth or rail bounce.
    final inMouth = (px - 0.5).abs() < goalHalfWidth;
    if (py <= 0) {
      if (inMouth) {
        _goal(0); // top goal belongs to side 1: side 0 scores
        return;
      }
      py = 0;
      if (pvy < -0.15) _emit(MatchEvent.wall);
      pvy = -pvy;
    }
    if (py >= 1) {
      if (inMouth) {
        _goal(1); // bottom goal belongs to side 0: side 1 scores
        return;
      }
      py = 1;
      if (pvy > 0.15) _emit(MatchEvent.wall);
      pvy = -pvy;
    }
    _collide(0);
    _collide(1);
  }

  void _collide(int side) {
    final dx = px - mx[side], dy = py - my[side];
    final dist = sqrt(dx * dx + dy * dy);
    final minDist = puckR + malletR;
    if (dist < minDist && dist > 0.0001) {
      final nx = dx / dist, ny = dy / dist;
      px = mx[side] + nx * minDist;
      py = my[side] + ny * minDist;
      final rvx = pvx - mvx[side], rvy = pvy - mvy[side];
      final vn = rvx * nx + rvy * ny;
      if (vn < 0) {
        pvx -= 1.9 * vn * nx;
        pvy -= 1.9 * vn * ny;
        // Mallet momentum transfers into the shot.
        pvx += mvx[side] * 0.85;
        pvy += mvy[side] * 0.85;
        final impact = sqrt(pvx * pvx + pvy * pvy);
        if (impact > 0.12) _emit(MatchEvent.hit);
      }
    }
  }

  // ------------------------------------------------------------------- AI
  void _aiStep(double dt) {
    final d = botDifficulty.index;
    _aiThink += dt;
    if (_aiThink >= _aiThinkInterval[d]) {
      _aiThink = 0;
      _aiDecide(d);
    }
    // Glide toward the target at the tier's top speed — visibly deliberate.
    final dx = _aiTx - mx[1], dy = _aiTy - my[1];
    final dist = sqrt(dx * dx + dy * dy);
    if (dist > 0.0001) {
      final step = min(dist, _aiSpeed[d] * dt);
      mvx[1] = dx / dist * step / dt;
      mvy[1] = dy / dist * step / dt;
      mx[1] += dx / dist * step;
      my[1] += dy / dist * step;
    } else {
      mvx[1] = 0;
      mvy[1] = 0;
    }
    mx[1] = mx[1].clamp(malletR, 1 - malletR);
    my[1] = my[1].clamp(malletR, 0.5 - malletR * 0.4);
  }

  /// Predict where the puck will be in [secs], with one rail bounce.
  (double, double) _predict(double secs) {
    double x = px, y = py, vx = pvx, vy = pvy;
    double t = secs;
    const step = 1 / 60;
    while (t > 0) {
      t -= step;
      x += vx * step;
      y += vy * step;
      if (x < puckR) {
        x = puckR;
        vx = -vx;
      }
      if (x > 1 - puckR) {
        x = 1 - puckR;
        vx = -vx;
      }
    }
    return (x, y);
  }

  void _aiDecide(int d) {
    final puckOnAiSide = py < 0.5;
    final puckSpeed = sqrt(pvx * pvx + pvy * pvy);
    final threatening = pvy < -0.05; // puck heading toward AI goal

    if (d == 0) {
      // ROOKIE: hangs back, shadows the puck, only clears slow close pucks.
      _aiTx = (0.5 + (px - 0.5) * 0.6).clamp(0.12, 0.88);
      _aiTy = 0.22;
      if (puckOnAiSide && puckSpeed < 0.35) {
        final dist = sqrt((px - mx[1]) * (px - mx[1]) +
            (py - my[1]) * (py - my[1]));
        if (dist < 0.35) {
          // Shove it back down-table: get behind, push through.
          _aiTx = (px + (px - 0.5) * 0.2).clamp(0.12, 0.88);
          _aiTy = (py - 0.10).clamp(0.08, 0.42);
        }
      }
      return;
    }

    if (puckOnAiSide || threatening) {
      if (threatening && !puckOnAiSide) {
        // SKILLED/CHAMPION: retreat to guard the goal mouth.
        _aiTx = (0.5 + (px - 0.5) * 0.8).clamp(0.15, 0.85);
        _aiTy = 0.10;
        return;
      }
      // Puck is on the AI half: intercept, then attack.
      final lookAhead = d == 2 ? 0.5 : 0.35;
      final (ix, iy) = _predict(lookAhead);
      final distToPuck =
          sqrt((px - mx[1]) * (px - mx[1]) + (py - my[1]) * (py - my[1]));
      if (puckSpeed < 0.55 && distToPuck < 0.4) {
        // Attack: line up behind the puck, aim at the far corner away
        // from the human mallet.
        final targetX = mx[0] < 0.5 ? 0.64 : 0.36;
        final aimX = targetX - px, aimY = 1.0 - py;
        final al = sqrt(aimX * aimX + aimY * aimY);
        _aiTx = (px - aimX / al * 0.11).clamp(0.12, 0.88);
        _aiTy = (py - aimY / al * 0.11).clamp(0.08, 0.42);
      } else {
        _aiTx = ix.clamp(0.12, 0.88);
        _aiTy = (iy - 0.02).clamp(0.08, 0.42);
      }
    } else {
      // Puck on the human half and not threatening: hold a ready position,
      // drifting with the puck.
      _aiTx = (0.5 + (px - 0.5) * 0.45).clamp(0.15, 0.85);
      _aiTy = d == 2 ? 0.28 : 0.20;
    }
  }
}
