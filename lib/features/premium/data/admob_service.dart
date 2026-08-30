import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Service that manages Google AdMob ads:
///   - Banner ads (bottom of camera screen)
///   - Rewarded ads (watch video for +3 bonus scans)
///
/// Ad Unit IDs:
///   - Replace the test IDs below with your real AdMob ad unit IDs.
///   - Use test IDs during development to avoid policy violations.
class AdMobService {
  // ── Real AdMob IDs ──────────────────────────────────────
  static const String _bannerAdUnitId =
      'ca-app-pub-8351736235154529/7484733148'; // PicSpeak Banner
  static const String _rewardedAdUnitId =
      'ca-app-pub-8351736235154529/7213270401'; // PicSpeak Rewarded

  BannerAd? _bannerAd;
  RewardedAd? _rewardedAd;
  bool _isRewardedLoading = false;

  /// Initialize the Mobile Ads SDK. Call once at app startup.
  Future<void> init() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      debugPrint('AdMob: skipped on non-mobile platform');
      return;
    }

    try {
      await MobileAds.instance.initialize();
      debugPrint('AdMob SDK initialized');
    } catch (e) {
      debugPrint('AdMob init failed: $e');
    }
  }

  // ── Banner Ad ───────────────────────────────────────────────

  /// Creates and loads a banner ad. Returns the loaded ad or null on failure.
  Future<BannerAd?> loadBannerAd() async {
    if (!Platform.isAndroid && !Platform.isIOS) return null;

    // Dispose the previous banner (if any) before reassigning so an ad is
    // never stranded when a new one is requested (tab switches / rebuilds).
    _bannerAd?.dispose();
    _bannerAd = null;

    try {
      _bannerAd = BannerAd(
        adUnitId: _bannerAdUnitId,
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) => debugPrint('Banner ad loaded'),
          onAdFailedToLoad: (ad, error) {
            debugPrint('Banner ad failed: ${error.message}');
            ad.dispose();
            // Only clear the current reference if it still points at this ad,
            // so a failing ad can't null out a newer one loading in its place.
            if (identical(_bannerAd, ad)) {
              _bannerAd = null;
            }
          },
        ),
      );

      await _bannerAd!.load();
      return _bannerAd;
    } catch (e) {
      debugPrint('Banner ad creation failed: $e');
      return null;
    }
  }

  /// Returns the loaded banner ad, or null if not loaded.
  BannerAd? get bannerAd => _bannerAd;

  /// Disposes and clears the currently loaded banner ad.
  ///
  /// Called by the banner widget when it leaves the widget tree so the native
  /// banner view is released instead of lingering for the app's lifetime.
  void disposeBannerAd() {
    _bannerAd?.dispose();
    _bannerAd = null;
  }

  // ── Rewarded Ad ─────────────────────────────────────────────

  /// Preloads a rewarded ad so it's ready when the user taps "Watch Ad".
  Future<void> preloadRewardedAd() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    if (_rewardedAd != null || _isRewardedLoading) return;

    _isRewardedLoading = true;

    try {
      await RewardedAd.load(
        adUnitId: _rewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _rewardedAd = ad;
            _isRewardedLoading = false;
            debugPrint('Rewarded ad loaded');
          },
          onAdFailedToLoad: (error) {
            _isRewardedLoading = false;
            debugPrint('Rewarded ad failed: ${error.message}');
          },
        ),
      );
    } catch (e) {
      _isRewardedLoading = false;
      debugPrint('Rewarded ad preload failed: $e');
    }
  }

  /// Shows the rewarded ad if loaded. Returns true if the user earned the reward.
  /// Returns false if the ad wasn't ready or the user didn't complete it.
  Future<bool> showRewardedAd() async {
    if (_rewardedAd == null) {
      debugPrint('Rewarded ad not ready — loading now...');
      await preloadRewardedAd();
      if (_rewardedAd == null) return false;
    }

    bool rewardEarned = false;

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        // Preload the next one
        preloadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('Rewarded ad show failed: ${error.message}');
        ad.dispose();
        _rewardedAd = null;
      },
    );

    await _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        rewardEarned = true;
        debugPrint('User earned reward: ${reward.amount} ${reward.type}');
      },
    );

    return rewardEarned;
  }

  /// Whether a rewarded ad is ready to show.
  bool get isRewardedAdReady => _rewardedAd != null;

  // ── Cleanup ─────────────────────────────────────────────────

  void dispose() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _rewardedAd?.dispose();
    _rewardedAd = null;
  }
}
