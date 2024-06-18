import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import '../models/user_model.dart';
import '../models/trip_location_data.dart';

class HiveInit {
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    try {
      final appDocumentDirectory =
          await path_provider.getApplicationDocumentsDirectory();
      await Hive.initFlutter(appDocumentDirectory.path);

      // Register adapters only if not already registered
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(UserAdapter());
      }
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(TripLocationDataAdapter());
      }
      _initialized = true;
    } catch (e) {
      print('Error initializing Hive: $e');
    }
  }
}
