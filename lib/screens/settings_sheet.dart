import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/player_state.dart';
import '../theme/app_radii.dart';
import '../theme/app_text.dart';
import '../theme/royal_velvet.dart';

class SettingsSheet extends ConsumerWidget {
  const SettingsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      backgroundColor: Colors.transparent,
      builder: (_) => const SettingsSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final v = context.velvet;
    final player = ref.watch(playerProvider);
    final notifier = ref.read(playerProvider.notifier);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: v.bg2,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadii.xxl),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: v.lineStrong,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child:
                      Text('Settings', style: AppText.displayM(color: v.text1)),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: v.text2),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Expanded(
              child: ListView(
                controller: controller,
                children: [
                  _section('Game'),
                  _toggle(
                    context,
                    icon: Icons.vibration_rounded,
                    label: 'Haptics',
                    value: player.hapticsEnabled,
                    onChanged: (v) => notifier.setSetting(haptics: v),
                  ),
                  _toggle(
                    context,
                    icon: Icons.volume_up_rounded,
                    label: 'Sound',
                    value: player.soundEnabled,
                    onChanged: (v) => notifier.setSetting(sound: v),
                  ),
                  _toggle(
                    context,
                    icon: Icons.visibility_rounded,
                    label: 'Colorblind mode',
                    subtitle: 'Adds shapes (●■▲◆★✕) to dots',
                    value: player.colorblindEnabled,
                    onChanged: (v) => notifier.setSetting(colorblind: v),
                  ),
                  _toggle(
                    context,
                    icon: Icons.notifications_rounded,
                    label: 'Daily reminder',
                    value: player.dailyReminderEnabled,
                    onChanged: (v) => notifier.setSetting(dailyReminder: v),
                  ),
                  const SizedBox(height: 18),
                  _section('Account'),
                  _row(
                    context,
                    icon: Icons.person_outline_rounded,
                    label: 'Sign in',
                    trailing: 'Anonymous',
                    onTap: () {},
                  ),
                  _row(
                    context,
                    icon: Icons.delete_outline_rounded,
                    label: 'Delete account',
                    danger: true,
                    onTap: () {},
                  ),
                  const SizedBox(height: 18),
                  _section('About'),
                  _row(
                    context,
                    icon: Icons.policy_outlined,
                    label: 'Privacy policy',
                    onTap: () {},
                  ),
                  _row(
                    context,
                    icon: Icons.gavel_rounded,
                    label: 'Terms of service',
                    onTap: () {},
                  ),
                  _row(
                    context,
                    icon: Icons.favorite_outline_rounded,
                    label: 'Credits',
                    onTap: () {},
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text('v1.0.0 (build 1)',
                        style: AppText.mono(color: v.text3, size: 12)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String label) => Builder(builder: (context) {
        final v = context.velvet;
        return Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 6, left: 4),
          child: Text(label, style: AppText.tag(color: v.text3)),
        );
      });

  Widget _toggle(
    BuildContext context, {
    required IconData icon,
    required String label,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final v = context.velvet;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: v.bg3,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Row(
        children: [
          Icon(icon, color: v.text2, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppText.body(color: v.text1)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: AppText.caption(color: v.text3).copyWith(fontSize: 11)),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: v.accent,
          ),
        ],
      ),
    );
  }

  Widget _row(
    BuildContext context, {
    required IconData icon,
    required String label,
    String? trailing,
    bool danger = false,
    VoidCallback? onTap,
  }) {
    final v = context.velvet;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: v.bg3,
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          child: Row(
            children: [
              Icon(icon, color: danger ? v.accent : v.text2, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label,
                    style: AppText.body(color: danger ? v.accent : v.text1)),
              ),
              if (trailing != null)
                Text(trailing, style: AppText.caption(color: v.text3)),
              const SizedBox(width: 6),
              Icon(Icons.chevron_right_rounded, color: v.text3, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
