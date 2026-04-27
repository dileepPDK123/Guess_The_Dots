/// Contextual status text — ported from `game-engine.jsx::statusMessage`.
library;

import 'feedback.dart';

String statusMessage({
  required int rowIdx,
  required int filled,
  required int slotCount,
  required PipFeedback? lastFb,
  required bool solved,
  required bool lost,
}) {
  if (solved) return 'Cracked it! Amazing 🎉';
  if (lost) return 'So close — try again?';
  if (rowIdx == 0 && filled == 0) return 'Tap a color to fill the first dot';
  if (filled < slotCount && lastFb != null) {
    if (lastFb.green == slotCount - 1) return 'Nice — one to go!';
    if (lastFb.green >= 2) {
      return '${lastFb.green} in place · ${lastFb.yellow} wrong spot';
    }
    if (lastFb.green + lastFb.yellow == 0) return 'Hm, none match. Pivot?';
    return '${lastFb.green} in place · ${lastFb.yellow} wrong spot';
  }
  if (filled < slotCount) {
    return 'Tap a color to fill the next dot · $filled/$slotCount';
  }
  return 'Row complete — submit!';
}
