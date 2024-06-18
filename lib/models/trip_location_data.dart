import 'package:hive/hive.dart';
part 'trip_location_data.g.dart';

@HiveType(typeId: 2)
class TripLocationData {
  @HiveField(0)
  final String previousLoc;
  
  @HiveField(1)
  final String currentLoc;
  
  @HiveField(2)
  final double distance;
  
  @HiveField(3)
  final String tripId;
  
  @HiveField(4)
  final String userId;

  TripLocationData({
    required this.previousLoc,
    required this.currentLoc,
    required this.distance,
    required this.tripId,
    required this.userId,
  });
}
