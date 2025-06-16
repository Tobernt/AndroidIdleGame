import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Handles in-app purchases for removing ads and enabling the permanent
/// gold bonus. This service restores previous purchases on startup.
class PurchaseService {
  static const String _kProductId = 'permanent_gold_bonus';

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  bool get isAvailable => _available;
  bool _available = false;

  /// Called when the purchase is successfully completed or restored.
  final VoidCallback onPurchase;

  PurchaseService({required this.onPurchase});

  Future<void> init() async {
    _available = await _iap.isAvailable();
    if (!_available) return;

    final purchaseUpdated = _iap.purchaseStream;
    _sub = purchaseUpdated.listen(_onPurchaseUpdated, onDone: () {
      _sub?.cancel();
    });

    await _iap.restorePurchases();
  }

  Future<void> buyPermanentBonus() async {
    if (!_available) return;
    final response = await _iap.queryProductDetails({_kProductId});
    if (response.notFoundIDs.isNotEmpty || response.productDetails.isEmpty) {
      return;
    }
    final product = response.productDetails.first;
    final purchaseParam = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  void _onPurchaseUpdated(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _completePurchase(purchase);
          break;
        case PurchaseStatus.error:
        case PurchaseStatus.canceled:
        case PurchaseStatus.pending:
          break;
      }
    }
  }

  Future<void> _completePurchase(PurchaseDetails purchase) async {
    await _iap.completePurchase(purchase);
    onPurchase();
  }

  void dispose() {
    _sub?.cancel();
  }
}
