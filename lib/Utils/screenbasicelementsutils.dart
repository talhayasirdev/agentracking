import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/ticker_provider.dart';

import '../main.dart';

late Size size;
late double screenWidth,
    screenHeight,
    fontSize,
    clientHeight,
    topBarSize,
    bottomBarSize;

double customWidth([double size = 1]) {
  return screenWidth * size;
}

double customHeight([double size = 1]) {
  return screenHeight * size;
}

double customClientHeight([double size = 1]) {
  return clientHeight * size;
}

double customFontSize([double size = 0.05]) {
  return fontSize * size;
}

void initialize(BuildContext context) {
  size = MediaQuery.of(context).size;
  screenWidth = size.width;
  topBarSize = MediaQuery.of(context).padding.top;
  bottomBarSize = MediaQuery.of(context).padding.bottom;
  screenHeight = size.height - topBarSize;
  clientHeight = screenHeight - kToolbarHeight - kBottomNavigationBarHeight;
  fontSize = (screenWidth * 0.8 + screenHeight) / 2;
}

//dismiss dialog
// void dismissDialog() async {
//   final permission = await Geolocator.checkPermission();
//   if (permission == LocationPermission.always &&
//       GeolocatorUtil.isPermissionDialogActive) {
//     GeolocatorUtil.isPermissionDialogActive = false;
//     Navigator.of(NavigatorUtil.context, rootNavigator: true).pop('dialog');
//   }
//   final serviceEnabled = await Geolocator.isLocationServiceEnabled();
//   if (serviceEnabled && GeolocatorUtil.isServicesDialogActive) {
//     GeolocatorUtil.isServicesDialogActive = false;
//     Navigator.of(NavigatorUtil.context, rootNavigator: true).pop('dialog');
//   }
// }
