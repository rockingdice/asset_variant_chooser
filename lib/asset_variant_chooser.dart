library asset_variant_chooser;

import 'dart:collection';

import 'package:flutter/widgets.dart';

const double _kLowDprLimit = 2.0;

class _AssetVariantChooser {
  static const assetName = "";

  //copied from painting/image_resolution.dart
  static const double _naturalResolution = 1.0;
  static final RegExp _extractRatioRegExp = RegExp(r'/?(\d+(\.\d*)?)x$');

  static double _parseScale(String key) {
    if (key == assetName) {
      return _naturalResolution;
    }

    final Uri assetUri = Uri.parse(key);
    String directoryPath = '';
    if (assetUri.pathSegments.length > 1) {
      directoryPath = assetUri.pathSegments[assetUri.pathSegments.length - 2];
    }

    final Match? match = _extractRatioRegExp.firstMatch(directoryPath);
    if (match != null && match.groupCount > 0)
      return double.parse(match.group(1)!);
    return _naturalResolution; // i.e. default to 1.0x
  }

  static String? _findBestVariant(
      SplayTreeMap<double, String> candidates, double value) {
    if (candidates.containsKey(value)) return candidates[value]!;
    final double? lower = candidates.lastKeyBefore(value);
    final double? upper = candidates.firstKeyAfter(value);
    if (lower == null) return candidates[upper];
    if (upper == null) return candidates[lower];

    // On screens with low device-pixel ratios the artifacts from upscaling
    // images are more visible than on screens with a higher device-pixel
    // ratios because the physical pixels are larger. Choose the higher
    // resolution image in that case instead of the nearest one.
    if (value < _kLowDprLimit || value > (lower + upper) / 2)
      return candidates[upper];
    else
      return candidates[lower];
  }
}

class AssetVariantChooser {
  static final AssetVariantChooser _singleton = AssetVariantChooser._internal();

  factory AssetVariantChooser() {
    return _singleton;
  }

  AssetVariantChooser._internal() {
    _candidates.addAll({1.0: "", 2.0: "2x", 3.0: "3x"});
  }

  SplayTreeMap<double, String> _candidates = SplayTreeMap();
  var _defaultRatioName = "";

  /// Return the best choice of resolution variants for current device pixel
  /// ratio in the String type.
  /// Example: "1.5x"
  String chooseVariant(BuildContext context) {
    var currentRatio = MediaQuery.of(context).devicePixelRatio;
    String bestVariant =
        _AssetVariantChooser._findBestVariant(_candidates, currentRatio) ??
            _defaultRatioName;
    return bestVariant;
  }

  /// Return the best choice of resolution variants for current device pixel
  /// ratio in the double type.
  /// Example: 1.5
  double chooseNumericVariant(BuildContext context) {
    var currentRatio = MediaQuery.of(context).devicePixelRatio;
    String bestVariant =
        _AssetVariantChooser._findBestVariant(_candidates, currentRatio) ??
            _defaultRatioName;
    if (bestVariant == _defaultRatioName) {
      bestVariant = _AssetVariantChooser.assetName;
    }

    return _AssetVariantChooser._parseScale(bestVariant);
  }

  /// Set available variants for each supported asset resolution.
  ///
  /// [pixelRatios] should be provided as "3x", "1.5x"..etc. The order is
  /// irrelevant.
  /// [defaultRatioName] can be optionally used if you want to use a different
  /// suffix for 1.0 ratio. [chooseVariant] will return this value if the ratio
  /// is 1.0.,
  void setAvailableVariants(List<String> pixelRatios,
      {String defaultRatioName = ""}) {
    _defaultRatioName = defaultRatioName;
    pixelRatios.forEach((element) {
      var ratio = _AssetVariantChooser._parseScale(element);
      _candidates.addEntries([MapEntry(ratio, element)]);
    });
    _candidates.clear();
    if (!_candidates.containsKey(1.0)) {
      _candidates.addEntries([MapEntry(1.0, _defaultRatioName)]);
    }
  }
}
