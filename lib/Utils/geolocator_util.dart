import 'dart:async';
import 'dart:io';

import 'package:agenttracking/Utils/screenbasicelementsutils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class GeolocatorUtil {
  static bool isPermissionDialogActive = false;
  static bool isServicesDialogActive = false;
  static bool isSnackbarActive = false;
  static late BuildContext context;
  static void init(BuildContext buildContext) {
    context = buildContext;
  }

  static Future<bool> checkPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    if (permission != LocationPermission.always) {
      if (Platform.isAndroid) {
        GeolocatorUtil.isPermissionDialogActive = true;

        await showDialog(
          barrierDismissible: false,
          context: context,
          builder: (context) => askPermissionDialog(context),
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // await showPermanentDeniedSnackbar();
    }
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();

      serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        GeolocatorUtil.isServicesDialogActive = true;
        await showDialog(
          barrierDismissible: false,
          context: context,
          builder: (context) => askUserLocationServicesDialog(context),
        );
        return Future.value(false);
      }
    }

    return Future.value(true);
  }

  static Future<Position> currentPosition() async {
    await checkPermission();
    return Geolocator.getCurrentPosition();
  }

  static Future<StreamSubscription<Position>?> continiusPositionWithNotfication(
    void Function(Position)? onData,
    Duration interval,
  ) async {
    try {
      await checkPermission();

      return Geolocator.getPositionStream(
        locationSettings: locationSettings(interval),
      ).listen(onData);
    } on Exception catch (e) {}

    return Future.value();
  }

  static LocationSettings locationSettings(Duration interval) {
    late LocationSettings locationSettings;

    const accuracy = LocationAccuracy.high;

    if (defaultTargetPlatform == TargetPlatform.android) {
      locationSettings = AndroidSettings(
        accuracy: accuracy,
        intervalDuration: interval,
        // foregroundNotificationConfig: const ForegroundNotificationConfig(
        //   enableWakeLock: true,
        //   notificationTitle: 'Sunset',
        //   notificationText: 'Tracking your location',
        // ),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      locationSettings = AppleSettings(
        accuracy: accuracy,
        showBackgroundLocationIndicator: true,
        pauseLocationUpdatesAutomatically: true,
        activityType: ActivityType.automotiveNavigation,
      );
    } else {
      locationSettings = const LocationSettings(
        accuracy: accuracy,
      );
    }

    return locationSettings;
  }

  static Future<void> showPermanentDeniedSnackbar() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Location permission is denied'),
            InkWell(
              onTap: () async {
                await openAppSettings();
              },
              child: const Text(
                'Open Settings',
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        ),
      ),
    );
  }

  //dialog for asking location permission
  static Widget askPermissionDialog(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: AlertDialog(
        backgroundColor: const Color.fromRGBO(60, 64, 66, 1),
        title: Column(
          children: [
            Icon(
              Icons.pin_drop,
              color: Color.fromRGBO(132, 201, 195, 1),
              size: customFontSize(0.08),
            ),
          ],
        ),
        content: SizedBox(
          width: customWidth(0.8),
          height: customHeight(0.1),
          child: Text(
            'Go to Location Permission settings and Select Allow all the Time',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: customFontSize(0.03),
            ),
          ),
        ),
        actions: [
          Column(
            children: [
              InkWell(
                onTap: () async {
                  await openAppSettings();
                },
                child: Container(
                  width: customWidth(0.88),
                  height: customHeight(0.065),
                  decoration: const BoxDecoration(
                      border: Border(
                          top: BorderSide(
                              color: Color.fromARGB(255, 97, 93, 93),
                              width: 0.4))),
                  child: Center(
                    child: Text(
                      'OPEN APP SETTINGS',
                      style: TextStyle(
                          color: Color.fromRGBO(132, 201, 195, 1),
                          fontWeight: FontWeight.w500,
                          fontSize: customFontSize(0.028)),
                    ),
                  ),
                ),
              ),
              InkWell(
                onTap: () async {
                  final permission = await Geolocator.checkPermission();
                  if (permission != LocationPermission.always) {
                    if (!GeolocatorUtil.isSnackbarActive) {
                      showSnackBar(context, 'Kindly Give permission first');
                    }
                  } else {
                    isPermissionDialogActive = false;
                    Navigator.of(context, rootNavigator: true).pop('dialog');
                  }
                },
                child: Container(
                  width: customWidth(0.88),
                  height: customHeight(0.065),
                  decoration: const BoxDecoration(
                      border: Border(
                          top: BorderSide(
                              color: Color.fromARGB(255, 97, 93, 93),
                              width: 0.4))),
                  child: Center(
                    child: Text(
                      'DISMISS',
                      style: TextStyle(
                          color: const Color.fromRGBO(132, 201, 195, 1),
                          fontWeight: FontWeight.w500,
                          fontSize: customFontSize(0.028)),
                    ),
                  ),
                ),
              )
            ],
          )
        ],
      ),
    );
  }

//dialog for asking user to turn on location services
  static Widget askUserLocationServicesDialog(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: AlertDialog(
        backgroundColor: const Color.fromRGBO(60, 64, 66, 1),
        title: Column(
          children: [
            Icon(
              Icons.pin_drop,
              color: const Color.fromRGBO(132, 201, 195, 1),
              size: customFontSize(0.08),
            ),
          ],
        ),
        content: SizedBox(
          width: customWidth(0.8),
          height: customHeight(0.06),
          child: Text(
            'Please turn on location Services',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: customFontSize(0.03),
            ),
          ),
        ),
        actions: [
          Column(
            children: [
              InkWell(
                onTap: () async {
                  await Geolocator.openLocationSettings();
                },
                child: Container(
                  width: customWidth(0.88),
                  height: customHeight(0.065),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: Color.fromARGB(255, 97, 93, 93),
                        width: 0.4,
                      ),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'OPEN LOCATION SETTINGS',
                      style: TextStyle(
                        color: const Color.fromRGBO(132, 201, 195, 1),
                        fontWeight: FontWeight.w500,
                        fontSize: customFontSize(0.028),
                      ),
                    ),
                  ),
                ),
              ),
              InkWell(
                onTap: () async {
                  final serviceEnabled =
                      await Geolocator.isLocationServiceEnabled();
                  if (!serviceEnabled) {
                    if (!GeolocatorUtil.isSnackbarActive) {
                      showSnackBar(context, 'Please turn on location');
                    }
                  } else {
                    isServicesDialogActive = false;
                    Navigator.of(context, rootNavigator: true).pop('dialog');
                  }
                },
                child: Container(
                  width: customWidth(0.88),
                  height: customHeight(0.065),
                  decoration: const BoxDecoration(
                      border: Border(
                          top: BorderSide(
                              color: Color.fromARGB(255, 97, 93, 93),
                              width: 0.4))),
                  child: Center(
                    child: Text(
                      'DISMISS',
                      style: TextStyle(
                        color: const Color.fromRGBO(132, 201, 195, 1),
                        fontWeight: FontWeight.w500,
                        fontSize: customFontSize(0.028),
                      ),
                    ),
                  ),
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}

//showsnackbar
void showSnackBar(BuildContext context, String message) {
  GeolocatorUtil.isSnackbarActive = true;
  ScaffoldMessenger.of(context)
      .showSnackBar(
        SnackBar(content: Text(message)),
      )
      .closed
      .then((value) {
    GeolocatorUtil.isSnackbarActive = false;
  });
}
//
// import 'dart:async';
// import 'dart:io';

// import 'package:flutter/material.dart';
// import 'package:location/location.dart';

// import 'package:agenttracking/Utils/screenbasicelementsutils.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:location/location.dart';

// Location location = Location();

// class GeolocatorUtil {
//   static bool isPermissionDialogActive = false;
//   static bool isServicesDialogActive = false;
//   static bool isSnackbarActive = false;
//   static late BuildContext context;
//   static void init(BuildContext buildContext) {
//     context = buildContext;
//   }

//   static Future<bool> checkPermission() async {
//     bool serviceEnabled;
//     var permission;

//     permission = await location.hasPermission();
//     if (permission == PermissionStatus.denied) {
//       permission = await location.hasPermission();

//       if (permission == PermissionStatus.denied) {
//         return Future.error('Location permissions are denied');
//       }
//     }
//     if (permission != PermissionStatus.granted) {
//       if (Platform.isAndroid) {
//         GeolocatorUtil.isPermissionDialogActive = true;
//         // ignore: use_build_context_synchronously
//         await showDialog(
//           barrierDismissible: false,
//           context: context,
//           builder: (context) => askPermissionDialog(context),
//         );
//       }
//     }

//     if (permission == PermissionStatus.deniedForever) {
//       // await showPermanentDeniedSnackbar();
//     }
//     serviceEnabled = await location.serviceEnabled();
//     if (!serviceEnabled) {
//       //await Geolocator.openLocationSettings();

//       serviceEnabled = await location.serviceEnabled();

//       if (!serviceEnabled) {
//         GeolocatorUtil.isServicesDialogActive = true;
//         await showDialog(
//           barrierDismissible: false,
//           context: context,
//           builder: (context) => askUserLocationServicesDialog(context),
//         );
//         return Future.value(false);
//       }
//     }

//     return Future.value(true);
//   }

//   static Future<LocationData> currentPosition() async {
//     await checkPermission();
//     return location.getLocation();
//   }

//   static Future<StreamSubscription<LocationData>?>
//       continiusPositionWithNotfication(
//     void Function(LocationData)? onData,
//     Duration interval,
//   ) async {
//     try {
//       await checkPermission();

//       return location.onLocationChanged.listen(onData);
//     } on Exception catch (e) {}

//     return Future.value();
//   }

//   // static LocationSettings locationSettings(Duration interval) {
//   //   late LocationSettings locationSettings;

//   //   const accuracy = LocationAccuracy.high;

//   //   if (defaultTargetPlatform == TargetPlatform.android) {
//   //     locationSettings = AndroidSettings(
//   //       accuracy: accuracy,
//   //       intervalDuration: interval,
//   //       // foregroundNotificationConfig: const ForegroundNotificationConfig(
//   //       //   enableWakeLock: true,
//   //       //   notificationTitle: 'Sunset',
//   //       //   notificationText: 'Tracking your location',
//   //       // ),
//   //     );
//   //   } else if (defaultTargetPlatform == TargetPlatform.iOS ||
//   //       defaultTargetPlatform == TargetPlatform.macOS) {
//   //     locationSettings = AppleSettings(
//   //       accuracy: accuracy,
//   //       showBackgroundLocationIndicator: true,
//   //       pauseLocationUpdatesAutomatically: true,
//   //       activityType: ActivityType.automotiveNavigation,
//   //     );
//   //   } else {
//   //     locationSettings = const LocationSettings(
//   //       accuracy: accuracy,
//   //     );
//   //   }

//   //   return locationSettings;
//   // }

//   static Future<void> showPermanentDeniedSnackbar() async {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             const Text('Location permission is denied'),
//             InkWell(
//               onTap: () async {
//                 // await openAppSettings();
//               },
//               child: const Text(
//                 'Open Settings',
//                 style: TextStyle(color: Colors.blue),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   //dialog for asking location permission
//   static Widget askPermissionDialog(BuildContext context) {
//     return WillPopScope(
//       onWillPop: () async {
//         return false;
//       },
//       child: AlertDialog(
//         backgroundColor: const Color.fromRGBO(60, 64, 66, 1),
//         title: Column(
//           children: [
//             Icon(
//               Icons.pin_drop,
//               color: Color.fromRGBO(132, 201, 195, 1),
//               size: customFontSize(0.08),
//             ),
//           ],
//         ),
//         content: SizedBox(
//           width: customWidth(0.8),
//           height: customHeight(0.1),
//           child: Text(
//             'Go to Location Permission settings and Select Allow all the Time',
//             textAlign: TextAlign.center,
//             style: TextStyle(
//               fontWeight: FontWeight.bold,
//               color: Colors.white,
//               fontSize: customFontSize(0.03),
//             ),
//           ),
//         ),
//         actions: [
//           Column(
//             children: [
//               InkWell(
//                 onTap: () async {
//                   // await openAppSettings();
//                 },
//                 child: Container(
//                   width: customWidth(0.88),
//                   height: customHeight(0.065),
//                   decoration: const BoxDecoration(
//                       border: Border(
//                           top: BorderSide(
//                               color: Color.fromARGB(255, 97, 93, 93),
//                               width: 0.4))),
//                   child: Center(
//                     child: Text(
//                       'OPEN APP SETTINGS',
//                       style: TextStyle(
//                           color: Color.fromRGBO(132, 201, 195, 1),
//                           fontWeight: FontWeight.w500,
//                           fontSize: customFontSize(0.028)),
//                     ),
//                   ),
//                 ),
//               ),
//               InkWell(
//                 onTap: () async {
//                   final permission = await location.hasPermission();
//                   if (permission != PermissionStatus.granted) {
//                     if (!GeolocatorUtil.isSnackbarActive) {
//                       showSnackBar(context, 'Kindly Give permission first');
//                     }
//                   } else {
//                     isPermissionDialogActive = false;
//                     Navigator.of(context, rootNavigator: true).pop('dialog');
//                   }
//                 },
//                 child: Container(
//                   width: customWidth(0.88),
//                   height: customHeight(0.065),
//                   decoration: const BoxDecoration(
//                       border: Border(
//                           top: BorderSide(
//                               color: Color.fromARGB(255, 97, 93, 93),
//                               width: 0.4))),
//                   child: Center(
//                     child: Text(
//                       'DISMISS',
//                       style: TextStyle(
//                           color: const Color.fromRGBO(132, 201, 195, 1),
//                           fontWeight: FontWeight.w500,
//                           fontSize: customFontSize(0.028)),
//                     ),
//                   ),
//                 ),
//               )
//             ],
//           )
//         ],
//       ),
//     );
//   }

// //dialog for asking user to turn on location services
//   static Widget askUserLocationServicesDialog(BuildContext context) {
//     return WillPopScope(
//       onWillPop: () async {
//         return false;
//       },
//       child: AlertDialog(
//         backgroundColor: const Color.fromRGBO(60, 64, 66, 1),
//         title: Column(
//           children: [
//             Icon(
//               Icons.pin_drop,
//               color: const Color.fromRGBO(132, 201, 195, 1),
//               size: customFontSize(0.08),
//             ),
//           ],
//         ),
//         content: SizedBox(
//           width: customWidth(0.8),
//           height: customHeight(0.06),
//           child: Text(
//             'Please turn on location Services',
//             textAlign: TextAlign.center,
//             style: TextStyle(
//               fontWeight: FontWeight.bold,
//               color: Colors.white,
//               fontSize: customFontSize(0.03),
//             ),
//           ),
//         ),
//         actions: [
//           Column(
//             children: [
//               InkWell(
//                 onTap: () async {
//                   //await Geolocator.openLocationSettings();
//                 },
//                 child: Container(
//                   width: customWidth(0.88),
//                   height: customHeight(0.065),
//                   decoration: const BoxDecoration(
//                     border: Border(
//                       top: BorderSide(
//                         color: Color.fromARGB(255, 97, 93, 93),
//                         width: 0.4,
//                       ),
//                     ),
//                   ),
//                   child: Center(
//                     child: Text(
//                       'OPEN LOCATION SETTINGS',
//                       style: TextStyle(
//                         color: const Color.fromRGBO(132, 201, 195, 1),
//                         fontWeight: FontWeight.w500,
//                         fontSize: customFontSize(0.028),
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//               InkWell(
//                 onTap: () async {
//                   final serviceEnabled = await location.serviceEnabled();
//                   if (!serviceEnabled) {
//                     if (!GeolocatorUtil.isSnackbarActive) {
//                       showSnackBar(context, 'Please turn on location');
//                     }
//                   } else {
//                     isServicesDialogActive = false;
//                     Navigator.of(context, rootNavigator: true).pop('dialog');
//                   }
//                 },
//                 child: Container(
//                   width: customWidth(0.88),
//                   height: customHeight(0.065),
//                   decoration: const BoxDecoration(
//                       border: Border(
//                           top: BorderSide(
//                               color: Color.fromARGB(255, 97, 93, 93),
//                               width: 0.4))),
//                   child: Center(
//                     child: Text(
//                       'DISMISS',
//                       style: TextStyle(
//                         color: const Color.fromRGBO(132, 201, 195, 1),
//                         fontWeight: FontWeight.w500,
//                         fontSize: customFontSize(0.028),
//                       ),
//                     ),
//                   ),
//                 ),
//               )
//             ],
//           )
//         ],
//       ),
//     );
//   }
// }

// //showsnackbar
// void showSnackBar(BuildContext context, String message) {
//   GeolocatorUtil.isSnackbarActive = true;
//   ScaffoldMessenger.of(context)
//       .showSnackBar(
//         SnackBar(content: Text(message)),
//       )
//       .closed
//       .then((value) {
//     GeolocatorUtil.isSnackbarActive = false;
//   });
// }
