import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../domain/premium_status.dart';

/// RevenueCat-backed repository for managing subscriptions.
///
/// Configuration:
///   - The RevenueCat public SDK key is injected at build time via
///     `--dart-define=REVENUECAT_API_KEY=<your_public_key>` so the production
///     key never lives in source control. The default below is the TEST key:
///     purchases only work in production once you build with the real public
///     SDK key (`goog_...` for Google Play).
///   - Configure products in RevenueCat dashboard:
///       Offering: "default"
///       Product 1: "picspeak_monthly" ($2.99/mo)
///       Product 2: "picspeak_annual"  ($12.99/yr)
///       Entitlement: "picspeack_pro"
class RevenueCatRepository {
  static const String revenueCatApiKey = String.fromEnvironment(
    'REVENUECAT_API_KEY',
    defaultValue: 'test_wySTMdFBXQYwKpfVXEPAzwFeUz',
  );
  static const String entitlementId = 'picspeack_pro';

  bool _initialized = false;

  /// Initialize RevenueCat. Call once at app startup.
  Future<void> init() async {
    if (_initialized) return;

    try {
      // Keep verbose debug logs in development, but stay quiet in release.
      await Purchases.setLogLevel(kReleaseMode ? LogLevel.info : LogLevel.debug);

      final configuration = PurchasesConfiguration(revenueCatApiKey);
      await Purchases.configure(configuration);

      _initialized = true;
      debugPrint('RevenueCat initialized successfully');
    } catch (e) {
      debugPrint('RevenueCat initialization failed: $e');
      // Non-fatal — app continues in free mode.
    }
  }

  /// Identify the current user (call after Firebase Auth login).
  Future<void> identify(String userId) async {
    if (!_initialized) return;
    try {
      await Purchases.logIn(userId);
      debugPrint('RevenueCat identified user: $userId');
    } catch (e) {
      debugPrint('RevenueCat identify failed: $e');
    }
  }

  /// Log out the current RevenueCat user.
  Future<void> logout() async {
    if (!_initialized) return;
    try {
      await Purchases.logOut();
    } catch (e) {
      debugPrint('RevenueCat logout failed: $e');
    }
  }

  /// Returns the current premium status by checking active entitlements.
  Future<PremiumStatus> getPremiumStatus() async {
    if (!_initialized) return PremiumStatus.free;

    try {
      final customerInfo = await Purchases.getCustomerInfo();
      final entitlement =
          customerInfo.entitlements.all[entitlementId];

      if (entitlement != null && entitlement.isActive) {
        return PremiumStatus(
          isPremium: true,
          entitlementId: entitlement.identifier,
          expirationDate: entitlement.expirationDate != null
              ? DateTime.tryParse(entitlement.expirationDate!)
              : null,
        );
      }

      return PremiumStatus.free;
    } catch (e) {
      debugPrint('RevenueCat getPremiumStatus failed: $e');
      return PremiumStatus.free;
    }
  }

  /// Returns available offerings (subscription packages) from RevenueCat.
  Future<Offering?> getCurrentOffering() async {
    if (!_initialized) return null;

    try {
      final offerings = await Purchases.getOfferings();
      return offerings.current;
    } catch (e) {
      debugPrint('RevenueCat getOfferings failed: $e');
      return null;
    }
  }

  /// Purchase a package. Returns the updated premium status.
  Future<PremiumStatus> purchasePackage(Package package) async {
    if (!_initialized) return PremiumStatus.free;

    try {
      final customerInfo = await Purchases.purchasePackage(package);
      final entitlement =
          customerInfo.entitlements.all[entitlementId];

      if (entitlement != null && entitlement.isActive) {
        return PremiumStatus(
          isPremium: true,
          entitlementId: entitlement.identifier,
          expirationDate: entitlement.expirationDate != null
              ? DateTime.tryParse(entitlement.expirationDate!)
              : null,
        );
      }

      return PremiumStatus.free;
    } on PurchasesErrorCode catch (e) {
      if (e == PurchasesErrorCode.purchaseCancelledError) {
        debugPrint('Purchase cancelled by user');
        return PremiumStatus.free;
      }
      debugPrint('RevenueCat purchase failed: $e');
      rethrow;
    }
  }

  /// Restore previous purchases. Returns the updated premium status.
  Future<PremiumStatus> restorePurchases() async {
    if (!_initialized) return PremiumStatus.free;

    try {
      final customerInfo = await Purchases.restorePurchases();
      final entitlement =
          customerInfo.entitlements.all[entitlementId];

      if (entitlement != null && entitlement.isActive) {
        return PremiumStatus(
          isPremium: true,
          entitlementId: entitlement.identifier,
          expirationDate: entitlement.expirationDate != null
              ? DateTime.tryParse(entitlement.expirationDate!)
              : null,
        );
      }

      return PremiumStatus.free;
    } catch (e) {
      debugPrint('RevenueCat restore failed: $e');
      return PremiumStatus.free;
    }
  }
}
