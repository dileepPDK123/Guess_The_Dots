import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/ads_service.dart';

/// Adaptive AdMob banner. No-op on web.
class AppBannerAd extends ConsumerStatefulWidget {
  const AppBannerAd({super.key});

  @override
  ConsumerState<AppBannerAd> createState() => _AppBannerAdState();
}

class _AppBannerAdState extends ConsumerState<AppBannerAd> {
  BannerAd? _ad;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) return;
    final ads = ref.read(adsProvider);
    if (ads.removeAdsEntitled) return;
    _load(ads);
  }

  Future<void> _load(AdsService ads) async {
    await ads.ensureInitialized();
    final ad = BannerAd(
      size: AdSize.banner,
      adUnitId: ads.bannerUnitId,
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() {}),
        onAdFailedToLoad: (ad, err) => ad.dispose(),
      ),
      request: const AdRequest(),
    );
    await ad.load();
    if (mounted) {
      setState(() => _ad = ad);
    }
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (kIsWeb || ad == null) return const SizedBox.shrink();
    return SizedBox(
      width: ad.size.width.toDouble(),
      height: ad.size.height.toDouble(),
      child: AdWidget(ad: ad),
    );
  }
}
