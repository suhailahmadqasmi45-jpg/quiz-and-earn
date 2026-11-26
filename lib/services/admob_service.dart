import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../core/audio/audio_manager.dart';

class AdMobService {
  static final AdMobService _instance = AdMobService._internal();
  factory AdMobService() => _instance;
  AdMobService._internal();

  // User's Live AdMob Ad Unit IDs from screenshots
  static const String liveInterstitialId = 'ca-app-pub-3495522069039077/3732002968';
  static const String liveRewardedInterstitialId = 'ca-app-pub-3495522069039077/4179880479';
  static const String liveRewardedId = 'ca-app-pub-3495522069039077/6634779737';
  static const String liveNativeAdvancedId = 'ca-app-pub-3495522069039077/7756289718';

  // Google Official Test IDs (Instant fallback during initial AdMob unit propagation window)
  static const String testInterstitialId = 'ca-app-pub-3940256099942544/1033173712';
  static const String testRewardedInterstitialId = 'ca-app-pub-3940256099942544/5354046379';
  static const String testRewardedId = 'ca-app-pub-3940256099942544/5224354917';
  static const String testNativeAdvancedId = 'ca-app-pub-3940256099942544/2247696110';

  InterstitialAd? _interstitialAd;
  RewardedInterstitialAd? _rewardedInterstitialAd;
  RewardedAd? _rewardedAd;

  bool _isInterstitialLoading = false;
  bool _isRewardedInterstitialLoading = false;
  bool _isRewardedLoading = false;

  bool isAdsEnabled = true;

  Future<void> init() async {
    try {
      await MobileAds.instance.initialize();
      preloadAllAds();
    } catch (e) {
      debugPrint('AdMob initialization notice: $e');
    }
  }

  void preloadAllAds() {
    loadInterstitialAd();
    loadRewardedInterstitialAd();
    loadRewardedAd();
  }

  // 1. Interstitial Ad (Used on Quiz Click, Wallet Click, ATM Card Flip)
  void loadInterstitialAd({bool useFallback = false}) {
    if (_isInterstitialLoading || _interstitialAd != null) return;
    _isInterstitialLoading = true;

    final adUnitId = useFallback ? testInterstitialId : liveInterstitialId;

    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialLoading = false;
          _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              AudioManager().restoreAfterAd();
              ad.dispose();
              _interstitialAd = null;
              loadInterstitialAd(); // Preload next
            },
            onAdFailedToShowFullScreenContent: (ad, err) {
              AudioManager().restoreAfterAd();
              ad.dispose();
              _interstitialAd = null;
              loadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (err) {
          _isInterstitialLoading = false;
          _interstitialAd = null;
          debugPrint('Interstitial failed to load on $adUnitId: ${err.message}');
          // If live unit is still propagating on AdMob servers (< 1hr), retry with test unit
          if (!useFallback) {
            loadInterstitialAd(useFallback: true);
          }
        },
      ),
    );
  }

  void showInterstitialAd({VoidCallback? onClosed}) {
    if (!isAdsEnabled) {
      onClosed?.call();
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
          onClosed?.call();
        },
        onAdFailedToShowFullScreenContent: (ad, err) {
          AudioManager().restoreAfterAd();
          ad.dispose();
          _interstitialAd = null;
          loadInterstitialAd();
          onClosed?.call();
        },
      );
      _interstitialAd!.show();
    } else if (_rewardedInterstitialAd != null) {
      // Fallback to rewarded interstitial if ready
      showRewardedInterstitialAd(onClosed: onClosed);
    } else {
      loadInterstitialAd();
      onClosed?.call();
    }
  }

  // 2. Rewarded Interstitial Ad (Used before revealing answers or quiz milestones)
  void loadRewardedInterstitialAd({bool useFallback = false}) {
    if (_isRewardedInterstitialLoading || _rewardedInterstitialAd != null) return;
    _isRewardedInterstitialLoading = true;

    final adUnitId = useFallback ? testRewardedInterstitialId : liveRewardedInterstitialId;

    RewardedInterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedInterstitialAd = ad;
          _isRewardedInterstitialLoading = false;
          _rewardedInterstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              AudioManager().restoreAfterAd();
              ad.dispose();
              _rewardedInterstitialAd = null;
              loadRewardedInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (ad, err) {
              AudioManager().restoreAfterAd();
              ad.dispose();
              _rewardedInterstitialAd = null;
              loadRewardedInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (err) {
          _isRewardedInterstitialLoading = false;
          _rewardedInterstitialAd = null;
          debugPrint('Rewarded interstitial failed to load on $adUnitId: ${err.message}');
          if (!useFallback) {
            loadRewardedInterstitialAd(useFallback: true);
          }
        },
      ),
    );
  }

  void showRewardedInterstitialAd({VoidCallback? onClosed, VoidCallback? onReward}) {
    if (!isAdsEnabled) {
      onClosed?.call();
      return;
    }

    if (_rewardedInterstitialAd != null) {
      AudioManager().duckForAd();
      _rewardedInterstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          AudioManager().restoreAfterAd();
          ad.dispose();
          _rewardedInterstitialAd = null;
          loadRewardedInterstitialAd();
          onClosed?.call();
        },
        onAdFailedToShowFullScreenContent: (ad, err) {
          AudioManager().restoreAfterAd();
          ad.dispose();
          _rewardedInterstitialAd = null;
          loadRewardedInterstitialAd();
          onClosed?.call();
        },
      );
      _rewardedInterstitialAd!.show(
        onUserEarnedReward: (ad, reward) {
          onReward?.call();
        },
      );
    } else {
      loadRewardedInterstitialAd();
      onClosed?.call();
    }
  }

  // 3. Rewarded Video Ad (Used for 50:50, Extra Time, and Clue Hints)
  void loadRewardedAd({bool useFallback = false}) {
    if (_isRewardedLoading || _rewardedAd != null) return;
    _isRewardedLoading = true;

    final adUnitId = useFallback ? testRewardedId : liveRewardedId;

    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedLoading = false;
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
        },
        onAdFailedToLoad: (err) {
          _isRewardedLoading = false;
          _rewardedAd = null;
          debugPrint('Rewarded ad failed on $adUnitId: ${err.message}');
          if (!useFallback) {
            loadRewardedAd(useFallback: true);
          }
        },
      ),
    );
  }

  void showRewardedHintAd({
    required VoidCallback onRewardGranted,
    required Function(String error) onAdFailed,
  }) {
    if (!isAdsEnabled) {
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
      loadRewardedAd();
      onRewardGranted(); // Gracefully grant hint so user isn't stuck
    }
  }

  // 4. Answer-show trigger ("answe show hon sa pahal add dikhega har quiz me")
  void showQuizAnswerAd({required VoidCallback onProceed}) {
    if (!isAdsEnabled) {
      onProceed();
      return;
    }

    if (_rewardedInterstitialAd != null) {
      showRewardedInterstitialAd(onClosed: onProceed);
    } else if (_interstitialAd != null) {
      showInterstitialAd(onClosed: onProceed);
    } else {
      preloadAllAds();
      onProceed();
    }
  }

  // Legacy compatibility helpers
  bool get isRewardedAdsEnabled => isAdsEnabled;
  set isRewardedAdsEnabled(bool val) => isAdsEnabled = val;
  bool get isInterstitialAdsEnabled => isAdsEnabled;
  set isInterstitialAdsEnabled(bool val) => isAdsEnabled = val;

  void showTransitionInterstitial({required VoidCallback onClosed}) {
    showInterstitialAd(onClosed: onClosed);
  }
}
