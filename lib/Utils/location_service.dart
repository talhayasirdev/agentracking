import 'dart:async';

import 'package:agenttracking/Utils/agent_tracking_util.dart';
import 'package:agenttracking/Utils/localnotifications_util.dart';
import 'package:location/location.dart';

class LocationService {
  static void startTrackingLocation() {
    Location location = Location();
    Timer.periodic(Duration(seconds: 20), (timer) async {
      LocationData locationData = await location.getLocation();
      showLocationNotification(locationData);
    });

    // location.onLocationChanged.listen((LocationData currentLocation) {
    //   // Use current location
    // });
  }

  static void showLocationNotification(LocationData position) {
    LocalNotificationUtil.showNotification(ReceivedNotification(
        id: "agentloc",
        title: 'Location Update',
        body: 'Latitude ${position.latitude} Longitude ${position.longitude}',
        payload: {}));
  }
}
