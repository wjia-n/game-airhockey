import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../services/audio_service.dart';
import '../services/iap_service.dart';
import '../services/settings_service.dart';
import '../theme/rink_art.dart';
import '../theme/rink_themes.dart';

/// Air Hockey PRO: Free-vs-Pro comparison, real purchase, restore, tip jar.
/// All prices come from the store — never hardcoded, never placeholders.
class ProScreen extends StatefulWidget {
  final RinkAudio audio;
  final RinkSettings settings;
  final StoreService store;

  const ProScreen({
    super.key,
    required this.audio,
    required this.settings,
    required this.store,
  });

  @override
  State<ProScreen> createState() => _ProScreenState();
}

class _ProScreenState extends State<ProScreen> {
  RinkThemeDef get _t => RinkThemes.byId(
        widget.settings.themeId,
        custom: widget.settings.customTheme,
      );

  @override
  void initState() {
    super.initState();
    widget.store.proPurchased.addListener(_onPro);
    widget.store.lastThanks.addListener(_onThanks);
  }

  void _onPro() {
    if (widget.store.proPurchased.value && mounted) {
      widget.settings.setPro(true);
      widget.audio.win();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PRO unlocked — enjoy everything!',
              style: Rink.body(15, theme: _t)),
          backgroundColor: _t.woodDeep,
          behavior: SnackBarBehavior.floating,
        ),
      );
      widget.store.proPurchased.value = false;
    }
  }

  void _onThanks() {
    final msg = widget.store.lastThanks.value;
    if (msg == null || !mounted) return;
    widget.audio.win();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: Rink.body(15, theme: _t)),
        backgroundColor: _t.woodDeep,
        behavior: SnackBarBehavior.floating,
      ),
    );
    widget.store.lastThanks.value = null;
  }

  @override
  void dispose() {
    widget.store.proPurchased.removeListener(_onPro);
    widget.store.lastThanks.removeListener(_onThanks);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    final s = widget.settings;
    final store = widget.store;
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
              widget.audio.click();
              Navigator.of(context).pop();
            },
          ),
          title: Text('✦  Air Hockey PRO', style: Rink.display(22, theme: t)),
        ),
        body: SafeArea(
          child: ListenableBuilder(
            listenable: s,
            builder: (_, _) => SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              child: Column(
                children: [
                  _ComparisonCard(theme: t, isPro: s.isPro),
                  const SizedBox(height: 16),
                  _BuyCard(
                    theme: t,
                    settings: s,
                    store: store,
                    audio: widget.audio,
                  ),
                  const SizedBox(height: 16),
                  _TipJarCard(
                    theme: t,
                    store: store,
                    audio: widget.audio,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ComparisonCard extends StatelessWidget {
  final RinkThemeDef theme;
  final bool isPro;
  const _ComparisonCard({required this.theme, required this.isPro});

  @override
  Widget build(BuildContext context) {
    final t = theme;
    const rows = [
      ('Table themes', '4 classics', 'All 12 + custom creator'),
      ('Mallet styles', '4', 'All 8'),
      ('Puck styles', '4', 'All 8'),
      ('Bot skill', 'Rookie + Skilled', '+ Champion AI'),
      ('2-player local', 'Yes', 'Yes'),
      ('Custom theme creator', '—', 'Yes'),
      ('Match stats', 'Yes', 'Yes'),
    ];
    return RinkCard(
      title: 'Free vs PRO',
      theme: t,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.black.withValues(alpha: 0.3),
          ),
          child: Table(
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(1.4),
              2: FlexColumnWidth(1.8),
            },
            children: [
              TableRow(
                children: [
                  _cell('', t, header: true),
                  _cell('FREE', t, header: true),
                  _cell('PRO', t, header: true, pro: true),
                ],
              ),
              for (final r in rows)
                TableRow(
                  children: [
                    _cell(r.$1, t),
                    _cell(r.$2, t),
                    _cell(r.$3, t, pro: true),
                  ],
                ),
            ],
          ),
        ),
        if (isPro)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text('✦ PRO is active on this device. Enjoy!',
                style: Rink.label(14, theme: t)),
          ),
      ],
    );
  }

  Widget _cell(String text, RinkThemeDef t,
      {bool header = false, bool pro = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      child: Text(
        text,
        style: header
            ? Rink.label(13, theme: t, color: pro ? t.accentLight : null)
            : Rink.body(12,
                theme: t,
                color: pro ? t.accentLight : t.ivory.withValues(alpha: 0.85)),
      ),
    );
  }
}

class _BuyCard extends StatelessWidget {
  final RinkThemeDef theme;
  final RinkSettings settings;
  final StoreService store;
  final RinkAudio audio;
  const _BuyCard({
    required this.theme,
    required this.settings,
    required this.store,
    required this.audio,
  });

  @override
  Widget build(BuildContext context) {
    final t = theme;
    final s = settings;
    return RinkCard(
      title: 'Unlock PRO',
      theme: t,
      children: [
        if (s.isPro)
          Text('PRO is already unlocked — thank you! 💛',
              style: Rink.body(14, theme: t))
        else if (!store.storeReady)
          Text(
            'PRO unlock will appear here once the store products are set up. (${store.error ?? 'not ready'})',
            style: Rink.body(13,
                theme: t, color: t.ivory.withValues(alpha: 0.7)),
          )
        else ...[
          Text('One-time purchase. Yours forever, on every device.',
              style: Rink.body(13,
                  theme: t, color: t.ivory.withValues(alpha: 0.8))),
          const SizedBox(height: 12),
          _buyRow(t, store.proProduct, '✦  Unlock PRO',
              () => store.buyPro(), primary: true),
        ],
        const SizedBox(height: 10),
        ValueListenableBuilder<String?>(
          valueListenable: store.purchaseError,
          builder: (_, err, _) => err == null
              ? const SizedBox.shrink()
              : Text(err,
                  style: Rink.body(12, theme: t, color: Colors.redAccent)),
        ),
        ValueListenableBuilder<bool>(
          valueListenable: store.purchaseInProgress,
          builder: (_, busy, _) => busy
              ? Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2)),
                      const SizedBox(width: 8),
                      Text('Contacting the store…',
                          style: Rink.body(12, theme: t)),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () {
            audio.click();
            store.restore();
          },
          child: Text('Restore purchases',
              style: Rink.label(13, theme: t).copyWith(
                  decoration: TextDecoration.underline)),
        ),
      ],
    );
  }

  Widget _buyRow(RinkThemeDef t, ProductDetails? product, String label,
      VoidCallback onBuy,
      {bool primary = false}) {
    return GestureDetector(
      onTap: () {
        audio.click();
        onBuy();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: primary
              ? LinearGradient(colors: [t.accentLight, t.accent])
              : null,
          color: primary ? null : Colors.black.withValues(alpha: 0.3),
          border: Border.all(
              color: primary ? t.accentLight : t.accent, width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label,
                style: Rink.label(16,
                    theme: t, color: primary ? t.woodDeep : t.accentLight)),
            if (product != null) ...[
              const SizedBox(width: 10),
              Text(product.price,
                  style: Rink.label(16,
                      theme: t, color: primary ? t.woodDeep : t.ivory)),
            ],
          ],
        ),
      ),
    );
  }
}

class _TipJarCard extends StatelessWidget {
  final RinkThemeDef theme;
  final StoreService store;
  final RinkAudio audio;
  const _TipJarCard(
      {required this.theme, required this.store, required this.audio});

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return RinkCard(
      title: '☕  Tip Jar',
      theme: t,
      children: [
        Text(
          'Air Hockey is free forever. A coffee keeps the tables polished!',
          style:
              Rink.body(12, theme: t, color: t.ivory.withValues(alpha: 0.8)),
        ),
        const SizedBox(height: 10),
        if (store.storeReady) ...[
          Row(
            children: [
              Expanded(
                  child: _tip(t, store.coffeeProduct, '☕', () {
                if (store.coffeeProduct != null) {
                  store.buyTip(store.coffeeProduct!);
                }
              })),
              const SizedBox(width: 10),
              Expanded(
                  child: _tip(t, store.chocolateProduct, '🍫', () {
                if (store.chocolateProduct != null) {
                  store.buyTip(store.chocolateProduct!);
                }
              })),
            ],
          ),
        ] else
          Text(store.error ?? 'Tip jar opening soon…',
              style: Rink.body(12,
                  theme: t, color: t.ivory.withValues(alpha: 0.6))),
      ],
    );
  }

  Widget _tip(RinkThemeDef t, ProductDetails? product, String emoji,
      VoidCallback onTap) {
    if (product == null) return const SizedBox.shrink();
    return GestureDetector(
      onTap: () {
        audio.click();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: t.accent.withValues(alpha: 0.6), width: 2),
          color: Colors.black.withValues(alpha: 0.3),
        ),
        alignment: Alignment.center,
        child: Text('$emoji  ${product.price}',
            style: Rink.label(15, theme: t)),
      ),
    );
  }
}
