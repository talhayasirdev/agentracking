import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

class HiveUtil {
  static late final BoxCollection boxCollection;
  static late final CollectionBox<Map> box;

  static Future<void> init() async {
    final appDocDirectory = await getApplicationDocumentsDirectory();

    final boxCollection = await BoxCollection.open(
      'UserTrack', // Name of your database
      {'TrackTime'}, // Names of your boxes
      path: '${appDocDirectory.path}/',
    );
    box = await boxCollection.openBox('TrackTime');
    await addTime(DateTime.now().toString());
    await addLocation(
        const PositionModel(latitude: 19.07283, longitude: 72.88261));
  }

  static Future<void> addLocation(PositionModel positionModel) async {
    await box.put('location', {
      'latitude': positionModel.latitude,
      'longitude': positionModel.longitude
    });
  }

  static Future<PositionModel> getLocation() async {
    final map = await box.get('location');
    final latitude = map!['latitude'] as double;
    final longitude = map!['longitude'] as double;
    final positionModel =
        PositionModel(latitude: latitude, longitude: longitude);
    return positionModel;
  }

  static Future<void> addTime(String data) async {
    box.put('time', {'time': data});
  }

  static Future<String> getTime() async {
    final map = await box.get('time');
    return map!['time'] as String;
  }
}

class PositionModel {
  const PositionModel({required this.latitude, required this.longitude});
  final double latitude;
  final double longitude;
}
