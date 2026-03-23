import 'package:flutter/material.dart';

class Sizes {
  Sizes._();

  double _width = 0;
  double _height = 0;

  static const Size _designSize = Size(574.23, 1252.51);
  static final Sizes _instance = Sizes._();

  //construtor singleton
  factory Sizes() => _instance;

  double get width => _width;
  double get height => _height;

  static void init(
    BuildContext context, {
      Size designSize = _designSize,
    }
  ) {
    final deviceData = MediaQuery.maybeOf(context);

    final deviceSize = deviceData?.size ?? _designSize;

    _instance._height = deviceSize.height;
    _instance._width = deviceSize.width;
  }
}

extension SizesExt on num {
  double get w {
    return (this * Sizes._instance._width) / Sizes._designSize.width;
  }
  double get h {
    return (this * Sizes._instance._height) / Sizes._designSize.height;
  }
  double get s {
    final shortestSide = Sizes._instance._width < Sizes._instance._height
        ? Sizes._instance._width
        : Sizes._instance._height;

    final designShortestSide = Sizes._designSize.width < Sizes._designSize.height
        ? Sizes._designSize.width
        : Sizes._designSize.height;

    return (this * shortestSide) / designShortestSide;
  }
}