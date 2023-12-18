import 'package:agenttracking/Utils/agent_tracking_util.dart';
import 'package:agenttracking/Utils/geolocator_util.dart';
import 'package:agenttracking/Utils/localnotifications_util.dart';
import 'package:agenttracking/Utils/location_service.dart';
import 'package:agenttracking/Utils/screenbasicelementsutils.dart';
import 'package:flutter/material.dart';
import 'package:geocode/geocode.dart';
import 'package:geocoding/geocoding.dart';

import 'package:geolocator/geolocator.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    initialize(context);
    GeolocatorUtil.init(context);
    // Future.delayed(Duration.zero).then((value) async {
    //   await LocalNotificationUtil.init();
    //   await AgentTrackingUtil.initializeService();
    // });

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Tracking the location',
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await getCurrentLocation();
          // LocalNotificationUtil.showNotification(ReceivedNotification(
          //     id: "agentloc",
          //     title: 'Location Update',
          //     body:
          //         'Adress ${address.addressDetails.neighbourhood} street ${address.addressDetails.houseNumber}',
          //     payload: {}));
          // if (AgentTrackingUtil.isLocationServiceActive) {
          //   AgentTrackingUtil.stopLocationService();
          //   AgentTrackingUtil.isLocationServiceActive = false;
          //   ScaffoldMessenger.of(context).showSnackBar(
          //       const SnackBar(content: Text('Tracking has been stopped')));
          // }
          // } else {
          //   AgentTrackingUtil.initializeService();
          //   AgentTrackingUtil.isLocationServiceActive = true;

          //   ScaffoldMessenger.of(context).showSnackBar(
          //       const SnackBar(content: Text('Tracking has been started')));
          // }
        },
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}

Future<void> getCurrentLocation() async {
  Position position = await GeolocatorUtil.currentPosition();
  GeoCode geoCode = GeoCode();

  try {
    List<Placemark> placemarks =
        await placemarkFromCoordinates(24.862705, 67.028637);

    var address = await geoCode.reverseGeocoding(
        latitude: 24.862705, longitude: 67.028637);
    if (address.streetAddress == 'Throttled! See geocode.xyz/pricing') {
      await getCurrentLocation();
    } else {
      String currentadress =
          '${address.streetAddress},${placemarks[0].subLocality} ${placemarks[0].locality}, ${placemarks[0].administrativeArea},${placemarks[0].country}';
      print('$currentadress');
      LocalNotificationUtil.showNotification(ReceivedNotification(
          id: "agentloc",
          title: '${placemarks[0].subLocality}',
          body: '$currentadress',
          payload: {}));
    }
  } catch (e) {
    print(e);
    await getCurrentLocation();
  }
}
