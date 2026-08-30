/// Represents the user's premium subscription status.
class PremiumStatus {
  /// Whether the user has an active premium subscription.
  final bool isPremium;

  /// The product identifier of the active entitlement, if any.
  final String? entitlementId;

  /// Expiration date of the current subscription, if any.
  final DateTime? expirationDate;

  const PremiumStatus({
    this.isPremium = false,
    this.entitlementId,
    this.expirationDate,
  });

  /// A free-tier user with no subscription.
  static const free = PremiumStatus();

  PremiumStatus copyWith({
    bool? isPremium,
    String? entitlementId,
    DateTime? expirationDate,
  }) {
    return PremiumStatus(
      isPremium: isPremium ?? this.isPremium,
      entitlementId: entitlementId ?? this.entitlementId,
      expirationDate: expirationDate ?? this.expirationDate,
    );
  }

  @override
  String toString() =>
      'PremiumStatus(isPremium: $isPremium, entitlement: $entitlementId)';
}
