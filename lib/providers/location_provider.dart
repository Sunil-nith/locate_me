import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../models/trip_location_data.dart';
import '../services/location_service.dart';
import '../services/hive_service.dart';

abstract class LocationState {
  const LocationState();
}

class InitialLocationState extends LocationState {
  const InitialLocationState();
}

class LoadingLocationState extends LocationState {
  const LoadingLocationState();
}

class TripStartedLocationState extends LocationState {
  final Position previousPosition;
  final String trackingStatus;
  final String currentTripId;
  final String userId;

  const TripStartedLocationState({
    required this.previousPosition,
    required this.trackingStatus,
    required this.currentTripId,
    required this.userId,
  });
}

class TripCompletedLocationState extends LocationState {
  final TripLocationData? startLocData;
  final TripLocationData? endLocData;
  final double totalDistance;

  const TripCompletedLocationState({
    this.startLocData,
    this.endLocData,
    required this.totalDistance,
  });
}

class ErrorLocationState extends LocationState {
  final String errorMessage;

  const ErrorLocationState(this.errorMessage);
}

class LocationNotifier extends StateNotifier<LocationState> {
  late StreamSubscription<Position> _positionStream;

  LocationNotifier() : super(const InitialLocationState());

  Future<void> startTracking(String userPhone) async {
    state = const LoadingLocationState();
    String currentTripId = DateTime.now().millisecondsSinceEpoch.toString();
    if (!await LocationService.checkLocationServicesEnabled() || !await LocationService.checkAndRequestLocationPermissions()) {
      state = const InitialLocationState();
      return;
    }
    try {
      Position? previousPosition = await LocationService.getCurrentPosition();
      if (previousPosition == null) {
        state = const InitialLocationState();
        return;
      }
      state = TripStartedLocationState(
        previousPosition: previousPosition,
        trackingStatus: 'Tracking is in progress...',
        currentTripId: currentTripId,
        userId: userPhone,
      );
      _addTripLocationData(previousPosition, previousPosition, 0);
      _getPositionUpdates();
    } catch (e) {
      state = ErrorLocationState("Error starting tracking: $e");
    }
  }

  void stopTracking(BuildContext context) {
    final currentState = state;
    if (currentState is! TripStartedLocationState) {
      _showAlert(context, 'Start Tracking', 'Please start the trip first.');
    } else {
      _showAlert(context, 'Confirm Stop', 'Are you sure you want to stop tracking?', isStopConfirmation: true);
    }
  }

  void _showAlert(BuildContext context, String title, String content, {bool isStopConfirmation = false}) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: <Widget>[
          if (isStopConfirmation)
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          TextButton(
            child: Text(isStopConfirmation ? 'Stop' : 'OK'),
            onPressed: () {
              Navigator.of(context).pop();
              if (isStopConfirmation) _performStopTracking();
            },
          ),
        ],
      ),
    );
  }

  void _getPositionUpdates() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );
    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen((Position position) {
      if (state is TripStartedLocationState) {
        final currentState = state as TripStartedLocationState;
        double distance = Geolocator.distanceBetween(
          currentState.previousPosition.latitude,
          currentState.previousPosition.longitude,
          position.latitude,
          position.longitude,
        ) / 1000;
        _addTripLocationData(currentState.previousPosition, position, distance);
        state = TripStartedLocationState(
          previousPosition: position,
          trackingStatus: currentState.trackingStatus,
          currentTripId: currentState.currentTripId,
          userId: currentState.userId,
        );
            }
    });
  }

  void _addTripLocationData(Position previous, Position current, double distance) {
    final currentState = state as TripStartedLocationState;
    final data = TripLocationData(
      previousLoc: '${previous.latitude}, ${previous.longitude}',
      currentLoc: '${current.latitude}, ${current.longitude}',
      distance: distance,
      tripId: currentState.currentTripId,
      userId: currentState.userId,
    );
    HiveService.addTripLocationData(data);
  }

  void _performStopTracking() {
    final currentState = state as TripStartedLocationState;
    state = const LoadingLocationState();
    stopListening();
    HiveService.getTripLocationDataByTripId(currentState.currentTripId).then((tripLocations) {
      TripLocationData? startLocData = tripLocations.isNotEmpty ? tripLocations.first : null;
      TripLocationData? endLocData = tripLocations.isNotEmpty ? tripLocations.last : null;

      _calculateTotalDistance(currentState.currentTripId).then((total) {
        state = TripCompletedLocationState(
          startLocData: startLocData,
          endLocData: endLocData,
          totalDistance: total,
        );
      });
    }).catchError((error) {
      print('Error getting trip location data: $error');
      state = ErrorLocationState('Error getting trip location data: $error');
    });
  }

  Future<double> _calculateTotalDistance(String tripId) async {
    double totalDistance = 0;
    try {
      final locations = await HiveService.getTripLocationDataByTripId(tripId);
      for (var location in locations) {
        totalDistance += location.distance;
      }
      return totalDistance;
    } catch (e) {
      print('Error calculating total distance: $e');
      return 0;
    }
  }



  void stopListening() {
    _positionStream.cancel();
  }
}

final locationProvider = StateNotifierProvider<LocationNotifier, LocationState>((ref) {
  return LocationNotifier();
});
