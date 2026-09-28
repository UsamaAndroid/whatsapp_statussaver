import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../core/constants.dart';

/// Preloads and shows interstitial ads.
///
/// Loading is kept warm proactively rather than only starting when a show is
/// requested, and failed loads retry on an exponential backoff — so an ad is
/// usually already in memory by the time a screen transition needs one. If
/// nothing is ready the caller is never blocked: [onContinue] still runs
/// immediately.
class InterstitialAdService {
  InterstitialAdService._();

  static final InterstitialAdService instance = InterstitialAdService._();

  /// Retry backoff for failed loads: 5s, 10s, 20s, 40s, 80s, capped at 2min.
  static const Duration _initialRetryDelay = Duration(seconds: 5);
  static const Duration _maxRetryDelay = Duration(minutes: 2);
  static const int _maxBackoffSteps = 6;

  /// Minimum gap between two interstitials. Set to [Duration.zero] so every
  /// eligible trigger shows one, matching how this is configured elsewhere.
  ///
  /// If AdMob ever flags the app for ad frequency, raising this to something
  /// like `Duration(seconds: 45)` is the single-line mitigation — nothing
  /// else needs to change.
  static const Duration _minGapBetweenAds = Duration.zero;

  InterstitialAd? _interstitialAd;
  bool _isLoading = false;
  int _consecutiveLoadFailures = 0;
  Timer? _retryTimer;
  DateTime? _lastShownAt;

  bool get isReady => _interstitialAd != null;

  /// Loads a new interstitial unless one is already loaded or in flight.
  /// Safe to call eagerly and repeatedly.
  void preload() {
    if (_interstitialAd != null || _isLoading) return;

    _retryTimer?.cancel();
    _retryTimer = null;
    _isLoading = true;

    InterstitialAd.load(
      adUnitId: AppConstants.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _isLoading = false;
          _consecutiveLoadFailures = 0;
          _interstitialAd = ad;
          if (kDebugMode) {
            debugPrint('Interstitial loaded');
          }
        },
        onAdFailedToLoad: (LoadAdError error) {
          _isLoading = false;
          if (kDebugMode) {
            debugPrint(
              'Interstitial failed to load: ${error.message} '
              '(code ${error.code})',
            );
          }
          _scheduleRetry();
        },
      ),
    );
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    _consecutiveLoadFailures++;

    final int step = _consecutiveLoadFailures.clamp(1, _maxBackoffSteps);
    final int multiplier = 1 << (step - 1); // 1, 2, 4, 8, 16, 32
    Duration delay = _initialRetryDelay * multiplier;
    if (delay > _maxRetryDelay) delay = _maxRetryDelay;

    if (kDebugMode) {
      debugPrint(
        'Interstitial: retrying load in ${delay.inSeconds}s '
        '(attempt #$_consecutiveLoadFailures)',
      );
    }

    _retryTimer = Timer(delay, preload);
  }

  /// Shows an interstitial if one is ready and the frequency cap allows it,
  /// then runs [onContinue].
  ///
  /// [onContinue] always runs exactly once — after the ad is dismissed, or
  /// straight away when no ad is available. The user is never made to wait
  /// on an ad that hasn't loaded.
  Future<void> showThen({required VoidCallback onContinue}) async {
    // Keep the pipeline warm; no-op if already loaded or loading.
    preload();

    final DateTime? last = _lastShownAt;
    final bool tooSoon = last != null &&
        DateTime.now().difference(last) < _minGapBetweenAds;

    final InterstitialAd? ad = _interstitialAd;
    if (ad == null || tooSoon) {
      onContinue();
      return;
    }

    _interstitialAd = null;
    _lastShownAt = DateTime.now();

    var continued = false;
    void continueOnce() {
      if (continued) return;
      continued = true;
      onContinue();
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (InterstitialAd dismissedAd) {
        dismissedAd.dispose();
        preload();
        continueOnce();
      },
      onAdFailedToShowFullScreenContent:
          (InterstitialAd failedAd, AdError error) {
        failedAd.dispose();
        if (kDebugMode) {
          debugPrint('Interstitial failed to show: ${error.message}');
        }
        preload();
        continueOnce();
      },
    );

    ad.show();
  }

  void dispose() {
    _retryTimer?.cancel();
    _retryTimer = null;
    _interstitialAd?.dispose();
    _interstitialAd = null;
  }
}
