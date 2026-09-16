import 'package:flutter/material.dart';

// TODO(next release): re-enable AdMob.
// This widget is temporarily inert because `google_mobile_ads` and
// `AppConstants.bannerAdUnitId` are commented out in pubspec.yaml /
// core/constants.dart. It is not referenced anywhere in the app right
// now — restore the implementation below alongside re-enabling those.
//
// import 'package:google_mobile_ads/google_mobile_ads.dart';
// import '../core/constants.dart';
//
// class BannerAdWidget extends StatefulWidget {
//   const BannerAdWidget({super.key});
//
//   @override
//   State<BannerAdWidget> createState() => _BannerAdWidgetState();
// }
//
// class _BannerAdWidgetState extends State<BannerAdWidget> {
//   BannerAd? _bannerAd;
//   bool _isLoaded = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _loadAd();
//   }
//
//   void _loadAd() {
//     _bannerAd = BannerAd(
//       adUnitId: AppConstants.bannerAdUnitId,
//       size: AdSize.banner,
//       request: const AdRequest(),
//       listener: BannerAdListener(
//         onAdLoaded: (ad) {
//           if (mounted) {
//             setState(() => _isLoaded = true);
//           }
//         },
//         onAdFailedToLoad: (ad, error) {
//           ad.dispose();
//           _bannerAd = null;
//           if (mounted) {
//             setState(() => _isLoaded = false);
//           }
//         },
//       ),
//     )..load();
//   }
//
//   @override
//   void dispose() {
//     _bannerAd?.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (!_isLoaded || _bannerAd == null) {
//       return const SizedBox.shrink();
//     }
//
//     return Container(
//       width: double.infinity,
//       color: Colors.white,
//       alignment: Alignment.center,
//       height: _bannerAd!.size.height.toDouble(),
//       child: AdWidget(ad: _bannerAd!),
//     );
//   }
// }

/// Placeholder used only so the file compiles cleanly while ads are
/// disabled. Not referenced anywhere in the app.
class BannerAdWidget extends StatelessWidget {
  const BannerAdWidget({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
