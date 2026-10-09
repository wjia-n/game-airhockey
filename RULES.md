# Air Hockey — Rules

The authoritative source of truth for this game. If the implementation
conflicts with this document, fix the implementation.

## 1. Objective

Score goals by sliding the puck into your opponent's goal mouth. The first
side to reach 7 goals wins the match.

## 2. Setup

- The table is portrait: side 0 (bottom) defends the bottom goal, side 1
  (top) defends the top goal.
- Each side has one mallet. The puck starts dead-center.
- Modes: **Solo vs AI** (bottom = human, top = AI) or **2-Player local**
  (bottom vs top, pass-and-play on one phone).
- AI skill tiers: **Rookie** < **Skilled** < **Champion** (Pro).
- Mallets start at their home marks; the puck is served toward the side
  that just conceded (random direction on the opening serve).

## 3. Turn order

Air hockey is real-time — there are no turns. Both mallets move freely and
simultaneously at all times during live play.

## 4. Legal moves

- Drag your mallet anywhere inside your own half. The bottom mallet may
  never cross the center line into the top half, and vice versa.
- Striking, pushing, deflecting or blocking the puck with your mallet.
- Banking the puck off the side rails and the end rails outside the goal
  mouth.

## 5. Illegal moves

- A mallet may not enter the opponent's half (the engine clamps it).
- Touching the opponent's mallet with your finger does nothing — mallets
  cannot collide with each other, only with the puck.
- No input is accepted during serve countdowns, goal celebrations, pause,
  or after the match ends.

## 6. Captures

Not applicable — there are no captures in air hockey. Possession changes
only by striking or intercepting the puck.

## 7. Special rules

- **Serve:** after every goal (and at match start) the puck is centered and
  play resumes after a short countdown. The puck drifts toward the side
  that conceded, so they reach it first.
- **Dead puck:** if the puck sits nearly still for more than ~6 seconds of
  live play, it is nudged back toward the center so a match can never stall.
- **Pause:** pausing freezes physics and all timers; resuming re-arms the
  current phase exactly where it stopped.

## 8. Scoring

- A goal is scored when the puck fully crosses an end line inside the goal
  mouth (|x − center| < goal mouth half-width).
- Puck hitting an end rail outside the mouth bounces back — no goal.
- Each goal is worth 1 point. Scores are shown on each side's strip.

## 9. Winning conditions

First side to **7 goals** wins the match immediately. There is no overtime:
7 is always reachable, so a winner is guaranteed.

## 10. Draw conditions

Draws are impossible — play continues until someone reaches 7 goals.

## 11. AI strategy

- **Rookie:** slow mallet, thinks every 0.45s. Holds a home position,
  shadows the puck's x-position, and only clears slow pucks that come
  close. Never attacks deliberately.
- **Skilled:** faster, thinks every 0.2s. Predicts the puck 0.35s ahead,
  retreats to guard the goal mouth when threatened, and attacks loose
  pucks on its half by lining up behind them and aiming at the far corner
  away from the human mallet.
- **Champion:** fastest, thinks every 0.1s. Predicts 0.5s ahead including
  one rail bounce, defends the mouth aggressively, and strikes loose pucks
  with corner-aimed shots.
- The AI mallet is always visible and moves smoothly toward its targets —
  it never teleports and never plays invisibly.

## 12. Edge cases

- Puck wedged exactly on the center line: legal, either side may strike it
  by reaching the line.
- Puck overlapping a mallet after a goal: positions reset on every serve,
  so overlap cannot persist.
- App backgrounded mid-match: physics and music pause; both resume on
  return. The watchdog re-arms any phase timer that died.
- Both sides reaching 7 simultaneously: impossible — one goal is processed
  per physics tick and the match ends at the first 7th goal.

## 13. Test cases

1. Drag the bottom mallet: it follows the finger and stays in the bottom
   half (clamped at the center line).
2. Strike the puck into the top goal mouth: bottom score +1, GOAL banner,
   horn sound, puck re-served toward the top side.
3. Strike the puck at the top end rail outside the mouth: puck bounces,
   no goal, clack sound.
4. Solo vs Rookie: the top mallet visibly defends and occasionally clears.
5. Solo vs Champion (Pro): the top mallet intercepts, aims corners, and is
   clearly faster than Skilled.
6. 2-Player: both halves draggable simultaneously; top strip labels the
   top-half player.
7. Background the app mid-match and return: match resumes, music resumes.
8. Reach 7 goals: victory dialog shows the winner and final score; Rematch
   resets to 0–0; stats (wins/games/goals) persist.
9. Rename both players, kill the app, reopen: names appear in the same
   slots, in order.
