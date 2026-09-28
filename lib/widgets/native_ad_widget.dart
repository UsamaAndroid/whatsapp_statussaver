import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../core/constants.dart';

/// Native advanced ad rendered with AdMob's bundled small template, styled to
/// match the app palette. No platform-side NativeAdFactory is needed.
///
/// Renders nothing until an ad has loaded, so an unfilled request leaves no
/// empty strip. A failed load retries on an exponential backoff rather than
/// leaving the slot blank for as long as the page stays alive — real
/// inventory does not fill every request the way debug test ads do.
class NativeAdWidget extends StatefulWidget {
  const NativeAdWidget({super.key});

  @override
  State<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget> {
  NativeAd? _nativeAd;
  bool _isLoaded = false;
  bool _isLoading = false;
  int _consecutiveLoadFailures = 0;
  Timer? _retryTimer;

  /// Height of TemplateType.small.
  static const double _adHeight = 120;

  static const Duration _initialRetryDelay = Duration(seconds: 5);
  static const Duration _maxRetryDelay = Duration(minutes: 2);
  static const int _maxBackoffSteps = 6;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    if (_isLoading || _isLoaded) return;
    _isLoading = true;

    final NativeAd nativeAd = NativeAd(
      adUnitId: AppConstants.nativeAdUnitId,
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.small,
        mainBackgroundColor: Colors.white,
        cornerRadius: 12,
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: AppConstants.darkGreen,
          size: 14,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.black54,
          size: 12,
        ),
        tertiaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.black45,
          size: 11,
        ),
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          backgroundColor: AppConstants.primaryGreen,
          size: 13,
        ),
      ),
      listener: NativeAdListener(
        onAdLoaded: (Ad ad) {
          _isLoading = false;
          _consecutiveLoadFailures = 0;
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            _nativeAd = ad as NativeAd;
            _isLoaded = true;
          });
          if (kDebugMode) {
            debugPrint('Native ad loaded');
          }
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          ad.dispose();
          _isLoading = false;
          if (kDebugMode) {
            debugPrint(
              'Native ad failed: ${error.message} (code ${error.code})',
            );
          }
          _scheduleRetry();
        },
      ),
    );

    nativeAd.load();
  }

  void _scheduleRetry() {
    if (!mounted) return;
    _retryTimer?.cancel();
    _consecutiveLoadFailures++;

    final int step = _consecutiveLoadFailures.clamp(1, _maxBackoffSteps);
    final int multiplier = 1 << (step - 1); // 1, 2, 4, 8, 16, 32
    Duration delay = _initialRetryDelay * multiplier;
    if (delay > _maxRetryDelay) delay = _maxRetryDelay;

    if (kDebugMode) {
      debugPrint(
        'Native ad: retrying load in ${delay.inSeconds}s '
        '(attempt #$_consecutiveLoadFailures)',
      );
    }

    _retryTimer = Timer(delay, () {
      if (mounted && !_isLoaded) _loadAd();
    });
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _nativeAd;
    if (!_isLoaded || ad == null) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      top: false,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
        child: SizedBox(
          height: _adHeight,
          width: double.infinity,
          child: AdWidget(ad: ad),
        ),
      ),
    );
  }
}
