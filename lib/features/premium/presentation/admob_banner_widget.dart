import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../data/premium_providers.dart';

/// A banner ad widget that loads and displays a Google AdMob banner.
///
/// Usage:
///   Place at the bottom of a screen:
///   ```dart
///   Column(
///     children: [
///       Expanded(child: content),
///       const AdMobBannerWidget(),
///     ],
///   )
///   ```
///
/// The banner is hidden for premium users.
class AdMobBannerWidget extends ConsumerStatefulWidget {
  const AdMobBannerWidget({super.key});

  @override
  ConsumerState<AdMobBannerWidget> createState() => _AdMobBannerWidgetState();
}

class _AdMobBannerWidgetState extends ConsumerState<AdMobBannerWidget> {
  BannerAd? _ad;
  bool _isLoading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  Future<void> _loadAd() async {
    final adMobService = ref.read(adMobServiceProvider);
    final ad = await adMobService.loadBannerAd();
    if (mounted) {
      setState(() {
        _ad = ad;
        _isLoading = false;
        _failed = ad == null;
      });
    }
  }

  @override
  void dispose() {
    final ad = _ad;
    if (ad != null) {
      final adMobService = ref.read(adMobServiceProvider);
      // The widget disposes the banner it rendered, but only if the service
      // still owns it — a newer load may already have replaced and disposed it.
      if (identical(ad, adMobService.bannerAd)) {
        adMobService.disposeBannerAd();
      }
      _ad = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = ref.watch(isPremiumProvider);

    // No ads for premium users
    if (isPremium) return const SizedBox.shrink();

    if (_isLoading) {
      return Container(
        height: 50,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_failed || _ad == null) {
      return const SizedBox.shrink();
    }

    // Never render an ad the service may already have disposed or replaced —
    // AdWidget throws if its ad has been disposed.
    final adMobService = ref.read(adMobServiceProvider);
    if (!identical(_ad, adMobService.bannerAd)) {
      return const SizedBox.shrink();
    }

    return Container(
      alignment: Alignment.center,
      width: _ad!.size.width.toDouble(),
      height: _ad!.size.height.toDouble(),
      child: AdWidget(ad: _ad!),
    );
  }
}
