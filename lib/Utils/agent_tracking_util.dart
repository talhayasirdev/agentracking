import 'dart:async';
import 'dart:ui';

import 'package:agenttracking/Utils/geolocator_util.dart';
import 'package:agenttracking/Utils/localnotifications_util.dart';
import 'package:agenttracking/Utils/location_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';

import 'hive_util.dart';

class AgentTrackingUtil {
  static const String bearerTokenMethod = 'bearerTokenMethod';
  static const String activeStatusUpdateMethod = 'activeStatusUpdateMethod';
  static const String stopServiceMethod = 'stopService';
  static bool isLocationServiceActive = true;
  static String? tBearerToken;
  static LocationSettings technicianTrackLocationSettings(Duration interval) {
    late LocationSettings locationSettings;

    const accuracy = LocationAccuracy.high;

    if (defaultTargetPlatform == TargetPlatform.android) {
      locationSettings = AndroidSettings(
        accuracy: accuracy,
        intervalDuration: interval,
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

  static Future<bool> startLocationService() async {
    //To update the current user location starting the background service

    unawaited(AgentTrackingUtil.initializeService());
    return true;
  }

  //Ios Functionality
  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    service.on(AgentTrackingUtil.stopServiceMethod).listen((event) {
      service.stopSelf();
    });

    await Geolocator.getCurrentPosition(timeLimit: const Duration(minutes: 1))
        .then((position) {
      /////////////////////////////
      showLocationNotification(position);
      /////////////////////////
    });
    Geolocator.getPositionStream(
      locationSettings:
          technicianTrackLocationSettings(const Duration(seconds: 1)),
    ).listen((event) async {
      /////////////////////////////
      showLocationNotification(event);
      /////////////////////////
    });
    return true;
  }

//Functionality Android
  @pragma('vm:entry-point')
  static Future<void> onStart(ServiceInstance service) async {
    StreamSubscription<Position>? locationStream;
    service.on(AgentTrackingUtil.stopServiceMethod).listen((event) {
      locationStream?.cancel();
      service.stopSelf();
    });
    HiveUtil.init();
    // LocationService.startTrackingLocation();
    await Geolocator.getCurrentPosition(timeLimit: const Duration(minutes: 2))
        .then((position) {
      showLocationNotification(position);
    });
    locationStream = Geolocator.getPositionStream(
      locationSettings:
          technicianTrackLocationSettings(const Duration(seconds: 1)),
    ).listen((event) async {
      trigger(event);
      //  unawaited(UserTrackApi.updateLocations(event, dio));
    });
  }

  static Future<void> trigger(Position position) async {
    final sDateTime = await HiveUtil.getTime();
    final lastLocationTime = DateTime.parse(sDateTime);
    final difference = DateTime.now().difference(lastLocationTime);
    //////////////////////////////////
    final previousLocation = await HiveUtil.getLocation();
    //checking last location and current location difference
    final distance = Geolocator.distanceBetween(
      previousLocation.latitude,
      previousLocation.longitude,
      position.latitude,
      position.longitude,
    );
    //updating location
    HiveUtil.addLocation(PositionModel(
        latitude: position.latitude, longitude: position.longitude));
    if (difference.inMinutes >= 1) {
      ////////////////////////////////////////
      showLocationNotification(position);
      ///////////////////
      await HiveUtil.addTime(
        DateTime.now().toString(),
      );
    }
  }

  static void stopLocationService() {
    service.invoke(AgentTrackingUtil.stopServiceMethod);
  }

  static void showLocationNotification(Position position) {
    LocalNotificationUtil.showNotification(ReceivedNotification(
        id: "agentloc",
        title: 'Location Update',
        body: 'Latitude ${position.latitude} Longitude ${position.longitude}',
        payload: {}));
  }

//initialize service
  static final service = FlutterBackgroundService();

  static Future<void> initializeService() async {
    await GeolocatorUtil.checkPermission();
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    const channel = AndroidNotificationChannel(
      'AgentTracking', // id
      'Agent Tracking Service', // title
      description: 'Channel for Foreground Service', // description
      importance: Importance.low, // importance must be at low or higher level
    );
    await flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(
        iOS: DarwinInitializationSettings(),
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        // this will be executed when app is in foreground or background in separated isolate
        onStart: AgentTrackingUtil.onStart,

        // auto start service
        autoStart: true,
        isForegroundMode: true,
        autoStartOnBoot: false,
        notificationChannelId: 'AgentTracking',
        initialNotificationTitle: 'CRM',
        initialNotificationContent: 'Tracking your location',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        // auto start service
        autoStart: true,

        // this will be executed when app is in foreground in separated isolate
        onForeground: onStart,
        onBackground: onIosBackground,

        // you have to enable background fetch capability on xcode project
      ),
    );

    await service.startService();
  }
}
