import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/player_state.dart';
import '../theme/app_radii.dart';
import '../theme/app_text.dart';
import '../theme/royal_velvet.dart';
import '../widgets/buttons.dart';

class RewardsScreen extends ConsumerStatefulWidget {
  const RewardsScreen({super.key});

  @override
  ConsumerState<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends ConsumerState<RewardsScreen> {
  int _tab = 0; // 0 = Shop, 1 = Season

  @override
  Widget build(BuildContext context) {
    final v = context.velvet;
    final p = ref.watch(playerProvider);
    return Scaffold(
      backgroundColor: v.bg1,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.chevron_left_rounded, color: v.text1),
          onPressed: () => Navigator.maybePop(context),
        ),
        centerTitle: true,
        title: Text('Rewards', style: AppText.title(color: v.text1)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: StatChip(
                label: '${p.coins}',
                icon: Icons.savings_rounded,
                accent: v.accent2,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
            child: Container(
              decoration: BoxDecoration(
                color: v.bg2,
                borderRadius: BorderRadius.circular(999),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  _TabButton(
                    label: 'Shop',
                    active: _tab == 0,
                    onTap: () => setState(() => _tab = 0),
                  ),
                  _TabButton(
                    label: 'Season',
                    active: _tab == 1,
                    onTap: () => setState(() => _tab = 1),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _tab == 0 ? _ShopTab(coins: p.coins) : _SeasonTab(level: p.level),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _TabButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final v = context.velvet;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? v.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppText.body(color: active ? Colors.white : v.text2)
                .copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

class _ShopTab extends StatelessWidget {
  final int coins;
  const _ShopTab({required this.coins});

  @override
  Widget build(BuildContext context) {
    final v = context.velvet;
    final items = [
      _Item('🪙', '10 Hint Tokens', '\$0.99', false, false),
      _Item('🎟️', '5 Extra Guess Tokens', '🪙 60', false, true),
      _Item('🎨', 'Arcade Theme', '🪙 200', true, true),
      _Item('💎', 'Gem Dot Style', '🪙 150', false, true),
    ];
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.85,
          children: [
            for (final it in items)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: v.bg2,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(color: v.line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: v.bg3,
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                      ),
                      child: Center(
                        child: Text(it.icon,
                            style: const TextStyle(fontSize: 22)),
                      ),
                    ),
                    const Spacer(),
                    Text(it.name,
                        style: AppText.body(color: v.text1).copyWith(
                            fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(it.price,
                        style: AppText.caption(color: v.accent2)
                            .copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: GhostButton(
                        label: it.owned ? 'Equip' : (it.spendsCoins ? 'Buy' : 'Get'),
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.lerp(v.accent, v.bg2, 0.6)!,
                Color.lerp(v.accent2, v.bg3, 0.7)!,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(color: v.accent.withValues(alpha: 0.45)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Remove Ads', style: AppText.title(color: v.text1)),
              const SizedBox(height: 4),
              Text('Hide banner + interstitial ads forever. Rewarded ads stay.',
                  style: AppText.caption(color: v.text2)),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  label: '\$2.99 — Remove Ads',
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Item {
  final String icon;
  final String name;
  final String price;
  final bool owned;
  final bool spendsCoins;
  const _Item(this.icon, this.name, this.price, this.owned, this.spendsCoins);
}

class _SeasonTab extends StatelessWidget {
  final int level;
  const _SeasonTab({required this.level});

  @override
  Widget build(BuildContext context) {
    final v = context.velvet;
    final milestones = [
      (5, 'Velvet Avatar Frame', '🎭'),
      (10, '+1 Streak Shield', '🛡️'),
      (20, 'Sphere Dot Style', '🌐'),
      (35, 'Obsidian Theme', '🌑'),
      (50, 'Arcade Theme', '🎮'),
    ];
    final pct = (level / 50).clamp(0.0, 1.0);
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: v.bg2,
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Velvet Season',
                  style: AppText.displayM(color: v.text1).copyWith(fontSize: 22)),
              const SizedBox(height: 4),
              Text('Lv $level / 50',
                  style: AppText.caption(color: v.text2)),
              const SizedBox(height: 12),
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: v.bg4,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: pct,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: LinearGradient(colors: [v.accent, v.accent2]),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        for (final m in milestones)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: level >= m.$1 ? v.accentSoft : v.bg2,
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(
                color: level >= m.$1 ? v.accent : v.line,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: v.bg3,
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  child: Center(
                    child: Text(m.$3, style: const TextStyle(fontSize: 18)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Lv ${m.$1}', style: AppText.tag(color: v.text3)),
                      const SizedBox(height: 2),
                      Text(m.$2,
                          style: AppText.body(color: v.text1)
                              .copyWith(fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                Icon(
                  level >= m.$1
                      ? Icons.check_circle_rounded
                      : Icons.lock_rounded,
                  color: level >= m.$1 ? v.accent : v.text3,
                  size: 20,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
