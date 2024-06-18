import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_model.dart';
import '../models/trip_location_data.dart';

class HiveService {
  static const String userBoxName = 'userBox';
  static const String tripLocationBoxName = 'trip_location_data';

  // Prepopulate user data
  static Future<void> prepopulateUserData() async {
    var userBox = await Hive.openBox<User>(userBoxName);
    if (userBox.isEmpty) {
      userBox.add(User(phoneNumber: '9035600155', password: '1234'));
      userBox.add(User(phoneNumber: '8090809090', password: '9876'));
      userBox.add(User(phoneNumber: '7070272625', password: '1234'));
    }
  }

  // Get user by phoneNumber and password
  static Future<User?> getUser(String phoneNumber, String password) async {
    var userBox = await Hive.openBox<User>(userBoxName);
    try {
      return userBox.values.firstWhere(
        (user) => user.phoneNumber == phoneNumber && user.password == password,
      );
    } catch (e) {
      return null;
    }
  }

  /// Opens the Hive box for TripLocationData and initializes Hive if needed.
  static Future<Box<TripLocationData>> _openTripLocationBox() async {
    if (!Hive.isBoxOpen(tripLocationBoxName)) {
      await Hive.openBox<TripLocationData>(tripLocationBoxName);
    }
    return Hive.box<TripLocationData>(tripLocationBoxName);
  }

  /// Adds a TripLocationData object to the Hive box.
  static Future<void> addTripLocationData(TripLocationData data) async {
    var box = await _openTripLocationBox();
    await box.add(data);
  }

  /// Retrieves TripLocationData objects for a specific tripId from the Hive box.
  static Future<List<TripLocationData>> getTripLocationDataByTripId(
      String tripId) async {
    var box = await _openTripLocationBox();
    return box.values.where((data) => data.tripId == tripId).toList();
  }
}
