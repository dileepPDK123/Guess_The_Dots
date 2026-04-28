import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' as gma;

/// AdMob bridge — silent on failure, no-op on web.
///
/// **IMPORTANT:** the unit IDs below are Google's official TEST IDs. Replace
/// with real IDs from AdMob console before publishing.
///
/// Banner: bottom of game screen
/// Interstitial: occasionally between games
/// Rewarded: hint, second-chance, +2x XP, +10 coins
class AdsService {
  static const _testBannerAndroid = 'ca-app-pub-3940256099942544/6300978111';
  static const _testBannerIos = 'ca-app-pub-3940256099942544/2934735716';
  static const _testInterstitialAndroid =
      'ca-app-pub-3940256099942544/1033173712';
  static const _testInterstitialIos =
      'ca-app-pub-3940256099942544/4411468910';
  static const _testRewardedAndroid =
      'ca-app-pub-3940256099942544/5224354917';
  static const _testRewardedIos =
      'ca-app-pub-3940256099942544/1712485313';

  bool _initialized = false;
  bool removeAdsEntitled = false;

  Future<void> ensureInitialized() async {
    if (_initialized || kIsWeb) {
      _initialized = true;
      return;
    }
    try {
      await gma.MobileAds.instance.initialize();
      _initialized = true;
    } catch (e) {
      debugPrint('Ads: init failed: $e');
    }
  }

  String get bannerUnitId => defaultTargetPlatform == TargetPlatform.iOS
      ? _testBannerIos
      : _testBannerAndroid;

  String get interstitialUnitId =>
      defaultTargetPlatform == TargetPlatform.iOS
          ? _testInterstitialIos
          : _testInterstitialAndroid;

  String get rewardedUnitId => defaultTargetPlatform == TargetPlatform.iOS
      ? _testRewardedIos
      : _testRewardedAndroid;

  /// Load + show an interstitial. Returns true on success.
  Future<bool> showInterstitial() async {
    if (kIsWeb || removeAdsEntitled) return false;
    await ensureInitialized();
    final completer = _Completer<bool>();
    gma.InterstitialAd.load(
      adUnitId: interstitialUnitId,
      request: const gma.AdRequest(),
      adLoadCallback: gma.InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = gma.FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              completer.complete(true);
            },
            onAdFailedToShowFullScreenContent: (ad, _) {
              ad.dispose();
              completer.complete(false);
            },
          );
          ad.show();
        },
        onAdFailedToLoad: (_) => completer.complete(false),
      ),
    );
    return completer.future;
  }

  /// Show a rewarded ad. Returns true if the user earned the reward.
  Future<bool> showRewarded() async {
    if (kIsWeb) return false;
    await ensureInitialized();
    final completer = _Completer<bool>();
    var earned = false;
    gma.RewardedAd.load(
      adUnitId: rewardedUnitId,
      request: const gma.AdRequest(),
      rewardedAdLoadCallback: gma.RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = gma.FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              completer.complete(earned);
            },
            onAdFailedToShowFullScreenContent: (ad, _) {
              ad.dispose();
              completer.complete(false);
            },
          );
          ad.show(onUserEarnedReward: (_, _) => earned = true);
        },
        onAdFailedToLoad: (_) => completer.complete(false),
      ),
    );
    return completer.future;
  }
}

/// Lightweight Future-completer to avoid pulling in `dart:async`'s Completer
/// imports at multiple call sites.
class _Completer<T> {
  final _c = <Function(T)>[];
  T? _value;
  bool _done = false;

  Future<T> get future {
    if (_done) return Future.value(_value as T);
    return Future(() async {
      while (!_done) {
        await Future.delayed(const Duration(milliseconds: 80));
      }
      return _value as T;
    });
  }

  void complete(T value) {
    if (_done) return;
    _done = true;
    _value = value;
    for (final cb in _c) {
      cb(value);
    }
    _c.clear();
  }
}

final adsProvider = Provider<AdsService>((_) => AdsService());
