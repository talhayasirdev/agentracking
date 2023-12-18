// ignore_for_file: unreachable_from_main

import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> notificationTap(NotificationResponse notificationResponse) async {
  log('LocalNotificationUtil::notificationTapBackground $notificationResponse');
}

class ReceivedNotification {
  ReceivedNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.payload,
  });

  final String id;
  final String? title;
  final String? body;
  final Map<String, dynamic> payload;
}

class LocalNotificationUtil {
  static final flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );

  static const notifictionsChannel = AndroidNotificationChannel(
    'all_notifications_channel_id',
    'All Notifications Channel',
    description: 'This channel is used for all notifications',
    importance: Importance.max,
  );

  static final androidDetails = AndroidNotificationDetails(
    notifictionsChannel.id,
    notifictionsChannel.name,
    ticker: 'ticker',
    priority: Priority.high,
    color: Colors.grey,
    channelDescription: notifictionsChannel.description,
  );

  static final notificationDetails = NotificationDetails(
    iOS: iosDetails,
    android: androidDetails,
  );

  static Future<void> init() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const darwinSettings = DarwinInitializationSettings(
      requestCriticalPermission: true,
    );

    const initializationSettings = InitializationSettings(
      iOS: darwinSettings,
      android: androidSettings,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: notificationTap,
    );

    await requestPermissions();

    await appOpenFromNotification();
  }

  static Future<void> requestPermissions() async {
    if (Platform.isIOS || Platform.isMacOS) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    } else if (Platform.isAndroid) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()!
          .requestNotificationsPermission();
    }
  }

  static Future<void> showNotification(
    ReceivedNotification receivedNotification,
  ) async {
    log('LocalNotificationUtil::showNotification: title ${receivedNotification.title}, body ${receivedNotification.body}');
    try {
      // using now time and round of it to in 1000 so that each time create
      // a new notification
      final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      await flutterLocalNotificationsPlugin.show(
        notificationId,
        receivedNotification.title,
        receivedNotification.body,
        notificationDetails,
        payload: receivedNotification.payload.toString(),
      );
    } on Exception catch (e) {
      log('LocalNotificationUtil::showNotification $e');
    }
  }

  static Future<void> appOpenFromNotification() async {
    final notificationAppLaunchDetails =
        await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
    if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
      final payload =
          notificationAppLaunchDetails!.notificationResponse?.payload;
      log('LocalNotificationUtil::appOpenFromNotification $payload');
    }
  }
}
