import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../app/nb_animations.dart';
import '../../../app/theme.dart';
import '../data/premium_providers.dart';

/// Full-screen paywall that promotes PicSpeak Premium.
///
/// Shows:
///   - Feature highlights (unlimited scans, no ads, unlimited saves)
///   - Monthly and Annual plan cards
///   - "Restore Purchases" link
class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  Offering? _offering;
  bool _loading = true;
  bool _purchasing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOffering();
  }

  Future<void> _loadOffering() async {
    try {
      final repo = ref.read(revenueCatRepositoryProvider);
      final offering = await repo.getCurrentOffering();
      if (mounted) {
        setState(() {
          _offering = offering;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Could not load plans. Please try again.';
          _loading = false;
        });
      }
    }
  }

  Future<void> _purchase(Package package) async {
    setState(() {
      _purchasing = true;
      _error = null;
    });

    try {
      final repo = ref.read(revenueCatRepositoryProvider);
      final status = await repo.purchasePackage(package);

      if (mounted) {
        if (status.isPremium) {
          // Refresh premium status
          ref.invalidate(premiumStatusProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 Welcome to PicSpeak Premium!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true); // Return true = purchased
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Purchase failed. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }

  Future<void> _restore() async {
    setState(() {
      _purchasing = true;
      _error = null;
    });

    try {
      final repo = ref.read(revenueCatRepositoryProvider);
      final status = await repo.restorePurchases();

      if (mounted) {
        if (status.isPremium) {
          ref.invalidate(premiumStatusProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Purchases restored! You are Premium.'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No previous purchases found.'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Restore failed. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('PicSpeak Premium'),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: NbLoadingBlock())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Hero icon
                  Icon(
                    Icons.workspace_premium,
                    size: 80,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Unlock Full Potential',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Learn English faster with no limits',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Feature list
                  _FeatureRow(
                    icon: Icons.camera_alt,
                    title: 'Unlimited Scans',
                    subtitle: 'Scan as many objects as you want every day',
                  ),
                  _FeatureRow(
                    icon: Icons.block,
                    title: 'No Ads',
                    subtitle: 'Enjoy an ad-free learning experience',
                  ),
                  _FeatureRow(
                    icon: Icons.favorite,
                    title: 'Unlimited Favorites',
                    subtitle: 'Save all the words you want to learn',
                  ),
                  _FeatureRow(
                    icon: Icons.school,
                    title: 'Priority Updates',
                    subtitle: 'Get new features and categories first',
                  ),
                  const SizedBox(height: 32),

                  // Error message
                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(NbRadius.xs),
                      ),
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Package cards
                  if (_offering != null) ...[
                    ..._buildPackageCards(theme),
                  ] else ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          'Plans are loading... Pull down to refresh.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Restore button
                  TextButton(
                    onPressed: _purchasing ? null : _restore,
                    child: const Text('Restore Purchases'),
                  ),

                  const SizedBox(height: 16),

                  // Terms
                  Text(
                    'Subscription automatically renews unless auto-renew is turned off at least 24 hours before the end of the current period. '
                    'You can manage your subscriptions in your Google Play Store account settings.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
    );
  }

  List<Widget> _buildPackageCards(ThemeData theme) {
    final packages = _offering!.availablePackages;
    if (packages.isEmpty) {
      return [
        const Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'No plans available at the moment.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ];
    }

    return packages.map((package) {
      final isAnnual =
          package.packageType == PackageType.annual;
      final isMonthly =
          package.packageType == PackageType.monthly;

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: NbPressable(
          child: Card(
            elevation: isAnnual ? 4 : 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(NbRadius.xs),
              side: isAnnual
                  ? BorderSide(
                      color: theme.colorScheme.primary, width: 2)
                  : BorderSide.none,
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(NbRadius.xs),
              onTap: _purchasing ? null : () => _purchase(package),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isAnnual)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'BEST VALUE',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: theme
                                      .colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                          if (isAnnual) const SizedBox(height: 8),
                          Text(
                            isAnnual
                                ? 'Annual Plan'
                                : isMonthly
                                    ? 'Monthly Plan'
                                    : package.identifier,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            package.storeProduct.description,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          package.storeProduct.priceString,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        if (isAnnual)
                          Text(
                            '/year',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          )
                        else if (isMonthly)
                          Text(
                            '/month',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    _purchasing
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(NbRadius.xs),
            ),
            child: Icon(
              icon,
              color: theme.colorScheme.onPrimaryContainer,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
