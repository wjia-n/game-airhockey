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
    widget.store.lastThanks.addListener(_onThanks);
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
          title: Text('☕  Tip Jar', style: Rink.display(22, theme: t)),
        ),
        body: SafeArea(
          child: ListenableBuilder(
            listenable: s,
            builder: (_, _) => SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              child: Column(
                children: [
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
                  child: _tip(t, store.coffeeProduct, '🍩', () {
                if (store.coffeeProduct != null) {
                  store.buyTip(store.coffeeProduct!);
                }
              })),
              const SizedBox(width: 10),
              Expanded(
                  child: _tip(t, store.chocolateProduct, '🍪', () {
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
