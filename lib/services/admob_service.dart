import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../core/audio/audio_manager.dart';

class AdMobService {
  static final AdMobService _instance = AdMobService._internal();
  factory AdMobService() => _instance;
  AdMobService._internal();

  RewardedAd? _rewardedAd;
  InterstitialAd? _interstitialAd;

  bool _isRewardedLoading = false;
  bool _isInterstitialLoading = false;

  bool isRewardedAdsEnabled = true;
  bool isInterstitialAdsEnabled = true;

  // Google AdMob official test unit IDs for Android
  static const String testRewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';
  static const String testInterstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';

  Future<void> init() async {
    try {
      await MobileAds.instance.initialize();
      loadRewardedAd();
      loadInterstitialAd();
    } catch (e) {
      debugPrint('AdMob initialization notice: $e');
    }
  }

  void loadRewardedAd() {
    if (_isRewardedLoading || _rewardedAd != null) return;
    _isRewardedLoading = true;

    RewardedAd.load(
      adUnitId: testRewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedLoading = false;
          _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _rewardedAd = null;
              loadRewardedAd(); // Preload next
            },
            onAdFailedToShowFullScreenContent: (ad, err) {
              ad.dispose();
              _rewardedAd = null;
              loadRewardedAd();
            },
          );
        },
        onAdFailedToLoad: (err) {
          _isRewardedLoading = false;
          _rewardedAd = null;
          debugPrint('Rewarded ad failed to load: ${err.message}');
        },
      ),
    );
  }

  void loadInterstitialAd() {
    if (_isInterstitialLoading || _interstitialAd != null) return;
    _isInterstitialLoading = true;

    InterstitialAd.load(
      adUnitId: testInterstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialLoading = false;
          _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialAd = null;
              loadInterstitialAd(); // Preload next
            },
            onAdFailedToShowFullScreenContent: (ad, err) {
              ad.dispose();
              _interstitialAd = null;
              loadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (err) {
          _isInterstitialLoading = false;
          _interstitialAd = null;
          debugPrint('Interstitial ad failed to load: ${err.message}');
        },
      ),
    );
  }

  void showRewardedHintAd({
    required VoidCallback onRewardGranted,
    required Function(String error) onAdFailed,
  }) {
    if (!isRewardedAdsEnabled) {
      // If ads are disabled by admin, unlock hint directly
      onRewardGranted();
      return;
    }

    if (_rewardedAd != null) {
      AudioManager().duckForAd();
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          AudioManager().restoreAfterAd();
          ad.dispose();
          _rewardedAd = null;
          loadRewardedAd();
        },
        onAdFailedToShowFullScreenContent: (ad, err) {
          AudioManager().restoreAfterAd();
          ad.dispose();
          _rewardedAd = null;
          loadRewardedAd();
        },
      );
      _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          onRewardGranted();
        },
      );
    } else {
      // If ad isn't loaded yet, try reloading and grant reward gracefully so user isn't punished
      loadRewardedAd();
      onRewardGranted();
    }
  }

  void showTransitionInterstitial({required VoidCallback onClosed}) {
    if (!isInterstitialAdsEnabled) {
      onClosed();
      return;
    }

    if (_interstitialAd != null) {
      AudioManager().duckForAd();
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          AudioManager().restoreAfterAd();
          ad.dispose();
          _interstitialAd = null;
          loadInterstitialAd();
          onClosed();
        },
        onAdFailedToShowFullScreenContent: (ad, err) {
          AudioManager().restoreAfterAd();
          ad.dispose();
          _interstitialAd = null;
          loadInterstitialAd();
          onClosed();
        },
      );
      _interstitialAd!.show();
    } else {
      loadInterstitialAd();
      onClosed();
    }
  }
}
