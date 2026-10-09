import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';
import '../engine/airhockey_engine.dart';
import '../services/audio_service.dart';
import '../services/iap_service.dart';
import '../services/settings_service.dart';
import '../theme/rink_art.dart';
import '../theme/rink_themes.dart';
import 'custom_theme_screen.dart';
import 'game_screen.dart';
import 'pro_screen.dart';
import 'settings_screen.dart';

const _storeUrl =
    'https://play.google.com/store/apps/details?id=com.gameswajiha.airhockey';

/// Main menu — Arcade Rink edition.
/// Logo, PLAY, mode setup (solo vs AI / 2 players, difficulty), theme picker,
/// mallet & puck styles, player renaming, tip jar, settings.
class MenuScreen extends StatefulWidget {
  final RinkAudio audio;
  final RinkSettings settings;

  const MenuScreen({super.key, required this.audio, required this.settings});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final StoreService _store = StoreService();

  RinkSettings get _s => widget.settings;
  RinkThemeDef get _t =>
      RinkThemes.byId(_s.themeId, custom: _s.customTheme);

  @override
  void initState() {
    super.initState();
    widget.audio.startMenuMusic();
    _store.init().then((_) {
      if (mounted) setState(() {});
    });
    _store.lastThanks.addListener(_onThanks);
    _store.proPurchased.addListener(_onPro);
  }

  void _onThanks() {
    final msg = _store.lastThanks.value;
    if (msg == null || !mounted) return;
    widget.audio.win();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: Rink.body(15, theme: _t)),
        backgroundColor: _t.woodDeep,
        behavior: SnackBarBehavior.floating,
      ),
    );
    _store.lastThanks.value = null;
  }

  void _onPro() {
    if (_store.proPurchased.value && mounted) {
      widget.settings.setPro(true);
      _store.proPurchased.value = false;
      setState(() {});
    }
  }

  @override
  void dispose() {
    _store.lastThanks.removeListener(_onThanks);
    _store.proPurchased.removeListener(_onPro);
    _store.dispose();
    super.dispose();
  }

  /// Real in-app review flow: the Play in-app review sheet when available,
  /// otherwise fall back to opening the store listing. No fake dialogs.
  Future<void> _requestReview() async {
    final review = InAppReview.instance;
    try {
      if (await review.isAvailable()) {
        await review.requestReview();
      } else {
        await review.openStoreListing(appStoreId: null);
      }
    } catch (_) {
      // Review UI unavailable on this device/build: stay silent, no fake UI.
    }
  }

  void _play() {
    widget.audio.matchStart();
    final t = _t;
    final solo = _s.mode == 0;
    final players = [
      AirPlayer(
          name: _s.playerNames[0], color: t.sideColors[0], isBot: false),
      AirPlayer(
        name: _s.playerNames[1],
        color: t.sideColors[1],
        isBot: solo,
      ),
    ];
    final engine = AirHockeyEngine(
      players: players,
      botDifficulty: BotDifficulty.values[_s.difficulty],
    );
    // App-scoped music: keep playing across screens. GameScreen switches
    // to the game track on entry; we switch back to menu music on return.
    Navigator.of(context)
        .push(MaterialPageRoute(
      builder: (_) => GameScreen(
        engine: engine,
        audio: widget.audio,
        settings: _s,
      ),
    ))
        .then((_) {
      if (mounted) widget.audio.startMenuMusic();
    });
  }

  void _openPro() {
    widget.audio.click();
    Navigator.of(context)
        .push(MaterialPageRoute(
      builder: (_) => ProScreen(
        audio: widget.audio,
        settings: _s,
        store: _store,
      ),
    ))
        .then((_) {
      if (mounted) setState(() {});
    });
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
            listenable: _s,
            builder: (_, _) => SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  // Logo plaque.
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: t.accent, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.6),
                          offset: const Offset(0, 8),
                          blurRadius: 18,
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset('assets/airhockey_logo.png',
                        fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 14),
                  Text('Air Hockey', style: Rink.display(46, theme: t)),
                  Text(
                    'THE ARCADE RINK EDITION',
                    style: Rink.label(12, theme: t),
                  ),
                  const SizedBox(height: 22),
                  RinkButton(
                      label: '▶  Play', onTap: _play, theme: t, width: 260),
                  const SizedBox(height: 12),
                  _proButton(t),
                  const SizedBox(height: 22),
                  _ModeCard(theme: t),
                  const SizedBox(height: 14),
                  _ThemeCard(theme: t),
                  const SizedBox(height: 14),
                  _StyleCard(theme: t),
                  const SizedBox(height: 14),
                  _NamesCard(theme: t),
                  const SizedBox(height: 14),
                  _SupportCard(theme: t, store: _store),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      RinkIconButton(
                        theme: t,
                        icon: Icons.share,
                        label: 'Share',
                        onTap: () async {
                          widget.audio.click();
                          await SharePlus.instance.share(ShareParams(
                              text:
                                  'Play Air Hockey with me! $_storeUrl'));
                        },
                      ),
                      const SizedBox(width: 22),
                      RinkIconButton(
                        theme: t,
                        icon: Icons.star_rate,
                        label: 'Rate',
                        onTap: () async {
                          widget.audio.click();
                          await _requestReview();
                        },
                      ),
                      const SizedBox(width: 22),
                      RinkIconButton(
                        theme: t,
                        icon: Icons.settings,
                        label: 'Settings',
                        onTap: () async {
                          widget.audio.click();
                          await Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => SettingsScreen(
                              audio: widget.audio,
                              settings: _s,
                            ),
                          ));
                          if (mounted) setState(() {});
                        },
                      ),
                      const SizedBox(width: 26),
                      RinkIconButton(
                        theme: t,
                        icon: Icons.help_outline,
                        label: 'How to Play',
                        onTap: () {
                          widget.audio.click();
                          _showHowTo(context, t);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (_s.gamesPlayed > 0)
                    Text(
                      'Wins: ${_s.wins}   •   Games: ${_s.gamesPlayed}   •   Goals: ${_s.goalsScored}',
                      style: Rink.label(12, theme: t),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('assets/wajiha_logo.png',
                          width: 22, height: 22, fit: BoxFit.contain),
                      const SizedBox(width: 8),
                      Text('Credits: WAJIHA',
                          style: Rink.label(12, theme: t)),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _proButton(RinkThemeDef t) {
    return GestureDetector(
      onTap: _openPro,
      child: Container(
        width: 260,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(colors: [
            t.accent.withValues(alpha: 0.9),
            t.accentDark,
          ]),
          border: Border.all(color: t.accentLight, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              offset: const Offset(0, 4),
              blurRadius: 8,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          _s.isPro ? '✦  PRO ACTIVE' : '✦  Get PRO',
          style: Rink.label(17, theme: t, color: t.woodDeep),
        ),
      ),
    );
  }

  void _showHowTo(BuildContext context, RinkThemeDef t) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(colors: [t.railMid, t.railDark]),
            border: Border.all(color: t.accent, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('How to Play', style: Rink.display(24, theme: t)),
              const SizedBox(height: 12),
              Text(
                '• Drag your mallet to smack the puck — first to 7 goals wins.\n'
                '• Your mallet stays on your half: defend your goal, attack theirs.\n'
                '• Bank shots off the wooden rails for style.\n'
                '• Solo: pick the bot\'s skill — Rookie, Skilled, or Champion (Pro).\n'
                '• 2 Players: pass the phone — top half vs bottom half.',
                style: Rink.body(14, theme: t),
              ),
              const SizedBox(height: 16),
              Center(
                child: RinkButton(
                  label: 'Got it!',
                  theme: t,
                  width: 160,
                  onTap: () {
                    widget.audio.click();
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ cards

/// Mode setup: solo vs AI (with difficulty) or 2-player local.
class _ModeCard extends StatelessWidget {
  final RinkThemeDef theme;
  const _ModeCard({required this.theme});

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_MenuScreenState>()!;
    final s = state.widget.settings;
    final audio = state.widget.audio;
    final t = theme;
    final solo = s.mode == 0;
    return RinkCard(
      title: '🎮  Game Mode',
      theme: t,
      children: [
        RinkSegmented<int>(
          values: const [0, 1],
          labels: const ['🤖 Solo vs AI', '👥 2 Players'],
          selected: s.mode,
          theme: t,
          onSelect: (v) {
            audio.click();
            s.setSetup(mode: v, difficulty: s.difficulty);
          },
        ),
        if (solo) ...[
          const SizedBox(height: 12),
          Text('Bot skill', style: Rink.body(13, theme: t)),
          const SizedBox(height: 8),
          RinkSegmented<int>(
            values: const [0, 1, 2],
            labels: const ['Rookie', 'Skilled', 'Champion'],
            selected: s.difficulty,
            theme: t,
            locked: const [false, false, true],
            onSelect: (v) {
              if (v == 2 && !s.isPro) {
                state._openPro();
                return;
              }
              audio.click();
              s.setSetup(mode: s.mode, difficulty: v);
            },
          ),
          if (!s.isPro)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('Champion AI is a PRO feature',
                  style: Rink.body(11,
                      theme: t,
                      color: t.ivory.withValues(alpha: 0.6))),
            ),
        ] else
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
                'Pass-and-play on one phone: bottom half vs top half.',
                style: Rink.body(12,
                    theme: t, color: t.ivory.withValues(alpha: 0.7))),
          ),
      ],
    );
  }
}

/// Table theme picker: 12 themes + custom, Pro-gated.
class _ThemeCard extends StatelessWidget {
  final RinkThemeDef theme;
  const _ThemeCard({required this.theme});

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_MenuScreenState>()!;
    final s = state.widget.settings;
    final audio = state.widget.audio;
    final t = theme;
    final catalog = RinkThemes.catalog(custom: s.customTheme);
    return RinkCard(
      title: '🎨  Table Theme',
      theme: t,
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.82,
          ),
          itemCount: catalog.length,
          itemBuilder: (_, i) {
            final th = catalog[i];
            final locked =
                !s.isPro && (th.id == 'custom' || RinkThemes.isProTheme(th.id));
            final selected = s.themeId == th.id;
            return GestureDetector(
              onTap: () {
                if (locked) {
                  state._openPro();
                  return;
                }
                if (th.id == 'custom') {
                  audio.click();
                  Navigator.of(context)
                      .push(MaterialPageRoute(
                    builder: (_) => CustomThemeScreen(
                      audio: audio,
                      settings: s,
                    ),
                  ))
                      .then((_) {
                    if (state.mounted) state.setState(() {});
                  });
                  return;
                }
                audio.click();
                s.setTheme(th.id);
              },
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? t.accentLight : t.railLight,
                        width: selected ? 3 : 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          offset: const Offset(0, 3),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        Column(
                          children: [
                            Expanded(
                                flex: 2,
                                child: Container(color: th.railMid)),
                            Expanded(
                              flex: 5,
                              child: Container(
                                color: th.surfaceLight,
                                child: Center(
                                  child: Container(
                                    width: 26,
                                    height: 26,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: th.lineColor, width: 2),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                                flex: 2,
                                child: Container(color: th.railMid)),
                          ],
                        ),
                        if (locked)
                          Container(
                            color: Colors.black.withValues(alpha: 0.45),
                            child: const Center(
                              child: Icon(Icons.lock,
                                  color: Colors.white70, size: 20),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    th.id == 'custom' ? 'Custom' : th.name.split(' ').first,
                    style: Rink.label(10, theme: t),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          },
        ),
        if (!s.isPro)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('More tables + the custom theme creator are PRO',
                style: Rink.body(11,
                    theme: t, color: t.ivory.withValues(alpha: 0.6))),
          ),
      ],
    );
  }
}

/// Mallet + puck style pickers.
class _StyleCard extends StatelessWidget {
  final RinkThemeDef theme;
  const _StyleCard({required this.theme});

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_MenuScreenState>()!;
    final s = state.widget.settings;
    final audio = state.widget.audio;
    final t = theme;
    return RinkCard(
      title: '🏒  Mallet & Puck',
      theme: t,
      children: [
        Text('Mallet', style: Rink.body(13, theme: t)),
        const SizedBox(height: 8),
        SizedBox(
          height: 74,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: MalletStyles.all.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final st = MalletStyles.all[i];
              final locked = !s.isPro && MalletStyles.isPro(i);
              final selected = s.malletStyle == i;
              return GestureDetector(
                onTap: () {
                  if (locked) {
                    state._openPro();
                    return;
                  }
                  audio.click();
                  s.setMalletStyle(i);
                },
                child: Column(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: st.body,
                        border: Border.all(
                          color:
                              selected ? t.accentLight : Colors.black45,
                          width: selected ? 3 : 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            offset: const Offset(0, 3),
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: st.grip,
                            ),
                          ),
                          if (locked)
                            const Icon(Icons.lock,
                                color: Colors.white70, size: 16),
                        ],
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(st.name.split(' ').first,
                        style: Rink.label(9, theme: t)),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Text('Puck', style: Rink.body(13, theme: t)),
        const SizedBox(height: 8),
        SizedBox(
          height: 74,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: PuckStyles.all.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final st = PuckStyles.all[i];
              final locked = !s.isPro && PuckStyles.isPro(i);
              final selected = s.puckStyle == i;
              return GestureDetector(
                onTap: () {
                  if (locked) {
                    state._openPro();
                    return;
                  }
                  audio.click();
                  s.setPuckStyle(i);
                },
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: st.body,
                        border: Border.all(
                          color:
                              selected ? t.accentLight : Colors.black45,
                          width: selected ? 3 : 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            offset: const Offset(0, 3),
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      child: locked
                          ? const Icon(Icons.lock,
                              color: Colors.white70, size: 15)
                          : null,
                    ),
                    const SizedBox(height: 3),
                    Text(st.name.split(' ').first,
                        style: Rink.label(9, theme: t)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Renameable players: saved on EVERY keystroke, committed on focus loss.
class _NamesCard extends StatelessWidget {
  final RinkThemeDef theme;
  const _NamesCard({required this.theme});

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_MenuScreenState>()!;
    final s = state.widget.settings;
    final t = theme;
    final solo = s.mode == 0;
    return RinkCard(
      title: '✏️  Players',
      theme: t,
      children: [
        _NameField(
          label: 'Bottom side (you)',
          initial: s.playerNames[0],
          theme: t,
          onChanged: (v) => s.setPlayerName(0, v),
          onFocusLost: () => s.commitNames(),
        ),
        const SizedBox(height: 10),
        _NameField(
          label: solo ? 'Top side (bot)' : 'Top side',
          initial: s.playerNames[1],
          theme: t,
          onChanged: (v) => s.setPlayerName(1, v),
          onFocusLost: () => s.commitNames(),
        ),
      ],
    );
  }
}

class _NameField extends StatefulWidget {
  final String label;
  final String initial;
  final RinkThemeDef theme;
  final ValueChanged<String> onChanged;
  final VoidCallback onFocusLost;

  const _NameField({
    required this.label,
    required this.initial,
    required this.theme,
    required this.onChanged,
    required this.onFocusLost,
  });

  @override
  State<_NameField> createState() => _NameFieldState();
}

class _NameFieldState extends State<_NameField> {
  late final TextEditingController _c;
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _c = TextEditingController(text: widget.initial);
    _focus = FocusNode();
    _focus.addListener(() {
      if (!_focus.hasFocus) widget.onFocusLost(); // commit on focus loss
    });
  }

  @override
  void didUpdateWidget(covariant _NameField old) {
    super.didUpdateWidget(old);
    // Keep external changes (e.g. reset) in sync, but never fight typing.
    if (!_focus.hasFocus && _c.text != widget.initial) {
      _c.text = widget.initial;
    }
  }

  @override
  void dispose() {
    _focus.dispose();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: Rink.body(12, theme: t)),
        const SizedBox(height: 4),
        TextField(
          controller: _c,
          focusNode: _focus,
          maxLength: 16,
          style: Rink.body(15, theme: t),
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: Colors.black.withValues(alpha: 0.3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: t.accent.withValues(alpha: 0.5)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: t.accent.withValues(alpha: 0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: t.accentLight, width: 2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          onChanged: widget.onChanged, // save on EVERY keystroke
          onSubmitted: (_) => _focus.unfocus(),
        ),
      ],
    );
  }
}

/// Tip jar + support links.
class _SupportCard extends StatelessWidget {
  final RinkThemeDef theme;
  final StoreService store;
  const _SupportCard({required this.theme, required this.store});

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_MenuScreenState>()!;
    final audio = state.widget.audio;
    final t = theme;
    return RinkCard(
      title: '💛  Support the Maker',
      theme: t,
      children: [
        Text(
          'Air Hockey is free forever. Tips keep the tables polished!',
          style:
              Rink.body(12, theme: t, color: t.ivory.withValues(alpha: 0.8)),
        ),
        const SizedBox(height: 10),
        if (store.storeReady) ...[
          Row(
            children: [
              Expanded(child: _tipButton(context, audio, t, store.coffeeProduct, '☕')),
              const SizedBox(width: 10),
              Expanded(
                  child:
                      _tipButton(context, audio, t, store.chocolateProduct, '🍫')),
            ],
          ),
        ] else
          Text(
            store.error ?? 'Tip jar opening soon…',
            style: Rink.body(12,
                theme: t, color: t.ivory.withValues(alpha: 0.6)),
          ),
      ],
    );
  }

  Widget _tipButton(BuildContext context, RinkAudio audio, RinkThemeDef t,
      ProductDetails? product, String emoji) {
    if (product == null) return const SizedBox.shrink();
    return GestureDetector(
      onTap: () {
        audio.click();
        store.buyTip(product);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: t.accent.withValues(alpha: 0.6), width: 2),
          color: Colors.black.withValues(alpha: 0.3),
        ),
        alignment: Alignment.center,
        child: Text('$emoji  ${product.price}',
            style: Rink.label(14, theme: t)),
      ),
    );
  }
}
