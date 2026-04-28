import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Tiny IAP wrapper. Two products:
///   * `gtd_remove_ads` ($2.99) — non-consumable; persists `removeAdsEntitled`.
///   * `gtd_hint_bundle_10` ($0.99) — consumable; awards 10 hint tokens.
///
/// Web is a no-op. Both stores will need product IDs registered before launch.
class IapService {
  static const String removeAdsId = 'gtd_remove_ads';
  static const String hintBundleId = 'gtd_hint_bundle_10';

  final _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;
  Map<String, ProductDetails> _products = {};

  Future<void> ensureInitialized({
    required void Function() onRemoveAds,
    required void Function() onHintBundle,
  }) async {
    if (kIsWeb) return;
    final available = await _iap.isAvailable();
    if (!available) return;
    final res =
        await _iap.queryProductDetails({removeAdsId, hintBundleId});
    _products = {for (final p in res.productDetails) p.id: p};
    _sub = _iap.purchaseStream.listen((details) {
      for (final d in details) {
        switch (d.status) {
          case PurchaseStatus.purchased:
          case PurchaseStatus.restored:
            if (d.productID == removeAdsId) onRemoveAds();
            if (d.productID == hintBundleId) onHintBundle();
            if (d.pendingCompletePurchase) _iap.completePurchase(d);
            break;
          case PurchaseStatus.error:
          case PurchaseStatus.canceled:
            if (d.pendingCompletePurchase) _iap.completePurchase(d);
            break;
          case PurchaseStatus.pending:
            break;
        }
      }
    });
  }

  ProductDetails? get removeAdsProduct => _products[removeAdsId];
  ProductDetails? get hintBundleProduct => _products[hintBundleId];

  Future<void> buyRemoveAds() async {
    final p = _products[removeAdsId];
    if (p == null) return;
    await _iap.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: p));
  }

  Future<void> buyHintBundle() async {
    final p = _products[hintBundleId];
    if (p == null) return;
    await _iap.buyConsumable(purchaseParam: PurchaseParam(productDetails: p));
  }

  Future<void> restore() async {
    if (kIsWeb) return;
    await _iap.restorePurchases();
  }

  void dispose() => _sub?.cancel();
}

final iapProvider = Provider<IapService>((_) => IapService());
