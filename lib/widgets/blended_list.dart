import 'package:flutter/material.dart';

import '../theme/app_radii.dart';
import '../theme/app_text.dart';
import '../theme/royal_velvet.dart';

/// Single row inside a [BlendedListContainer]. Designed to feel like an iOS
/// settings row, not a button: 34×34 icon tile, label, optional trailing label,
/// optional trailing chev.
class BlendedListRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailing; // e.g. "74% win" or "2 new"
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? labelColor;

  const BlendedListRow({
    super.key,
    required this.icon,
    required this.label,
    this.trailing,
    this.onTap,
    this.iconColor,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    final v = context.velvet;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: v.bg3,
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: Icon(icon, size: 18, color: iconColor ?? v.text2),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: AppText.body(color: labelColor ?? v.text1).copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (trailing != null) ...[
              Text(trailing!, style: AppText.caption(color: v.text3)),
              const SizedBox(width: 8),
            ],
            Icon(Icons.chevron_right_rounded, color: v.text3, size: 22),
          ],
        ),
      ),
    );
  }
}

/// Wraps [BlendedListRow]s in a single elevated card with hairline dividers
/// between rows. The whole thing reads as ONE container, not separate buttons.
class BlendedListContainer extends StatelessWidget {
  final List<BlendedListRow> rows;

  const BlendedListContainer({super.key, required this.rows});

  @override
  Widget build(BuildContext context) {
    final v = context.velvet;
    final children = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      if (i > 0) {
        children.add(Padding(
          padding: const EdgeInsets.only(left: 16 + 34 + 14),
          child: Divider(color: v.line, height: 1, thickness: 1),
        ));
      }
      children.add(rows[i]);
    }
    return Container(
      decoration: BoxDecoration(
        color: v.bg2,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        boxShadow: v.el1,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: Column(children: children),
      ),
    );
  }
}
