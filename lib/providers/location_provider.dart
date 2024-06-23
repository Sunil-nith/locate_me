import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:locate_me2/pages/second_page.dart';
import '../models/trip_location_data.dart';
import '../services/location_service.dart';
import '../services/hive_service.dart';

class LocationState {
  final Position? currentPosition;
  final Position? previousPosition;
  final bool tracking;
  final double totalDistance;
  final TripLocationData? startLocData;
  final TripLocationData? endLocData;
  final bool isLoading;
  final String trackingStatus;
  final bool isTrackingStarted;
  final String? currentTripId;
  final String userId;

  LocationState({
    this.currentPosition,
    this.previousPosition,
    this.tracking = false,
    this.totalDistance = 0.0,
    this.startLocData,
    this.endLocData,
    this.isLoading = false,
    this.trackingStatus = '',
    this.isTrackingStarted = false,
    this.currentTripId,
    this.userId = '',
  });

  LocationState copyWith({
    Position? currentPosition,
    Position? previousPosition,
    bool? tracking,
    double? totalDistance,
    TripLocationData? startLocData,
    TripLocationData? endLocData,
    bool? isLoading,
    String? trackingStatus,
    bool? isTrackingStarted,
    String? currentTripId,
    String? userId,
  }) {
    return LocationState(
      currentPosition: currentPosition ?? this.currentPosition,
      previousPosition: previousPosition ?? this.previousPosition,
      tracking: tracking ?? this.tracking,
      totalDistance: totalDistance ?? this.totalDistance,
      startLocData: startLocData ?? this.startLocData,
      endLocData: endLocData ?? this.endLocData,
      isLoading: isLoading ?? this.isLoading,
      trackingStatus: trackingStatus ?? this.trackingStatus,
      isTrackingStarted: isTrackingStarted ?? this.isTrackingStarted,
      currentTripId: currentTripId ?? this.currentTripId,
      userId: userId ?? this.userId,
    );
  }
}

class LocationNotifier extends StateNotifier<LocationState> {
  late StreamSubscription<Position> _positionStream;
  LocationNotifier() : super(LocationState());

  
  Future<void> startTracking(String userPhone) async {
    state = state.copyWith(isLoading: true, userId: userPhone, startLocData: null, endLocData: null);
    String currentTripId = DateTime.now().millisecondsSinceEpoch.toString();
    state = state.copyWith(currentTripId: currentTripId);
    if (!await LocationService.checkLocationServicesEnabled() || !await LocationService.checkAndRequestLocationPermissions()) {
      state = state.copyWith(isLoading: false);
      return;
    }
    try {
      Position? previousPosition = await LocationService.getCurrentPosition();
      if (previousPosition == null) {
        state = state.copyWith(isLoading: false);
        return;
      }
      state = state.copyWith(previousPosition: previousPosition, tracking: true, trackingStatus: 'Tracking is in progress...');
      _addTripLocationData(previousPosition, previousPosition, 0);
      _getPositionUpdates();
    } catch (e) {
      Fluttertoast.showToast(msg: "Error starting tracking: $e", toastLength: Toast.LENGTH_LONG, gravity: ToastGravity.BOTTOM);
      print('Error starting tracking: $e');
    } finally {
      state = state.copyWith(isLoading: false, isTrackingStarted: true);
    }
  }

  void stopTracking(BuildContext context) {
    if (!state.isTrackingStarted) {
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
      if (state.tracking) {
        if (state.previousPosition != null) {
          double distance = Geolocator.distanceBetween(
            state.previousPosition!.latitude,
            state.previousPosition!.longitude,
            position.latitude,
            position.longitude,
          ) / 1000;
          _addTripLocationData(state.previousPosition!, position, distance);
          state = state.copyWith(previousPosition: position);
        }
      }
    });
  }

  void _addTripLocationData(Position previous, Position current, double distance) {
    final data = TripLocationData(
      previousLoc: '${previous.latitude}, ${previous.longitude}',
      currentLoc: '${current.latitude}, ${current.longitude}',
      distance: distance,
      tripId: state.currentTripId!,
      userId: state.userId,
    );
    HiveService.addTripLocationData(data);
  }

  void _performStopTracking() {
    state = state.copyWith(isLoading: true, trackingStatus: 'Stopping tracking...', tracking: false);
    stopListening();
    HiveService.getTripLocationDataByTripId(state.currentTripId!).then((tripLocations) {
      TripLocationData? startLocData = tripLocations.isNotEmpty ? tripLocations.first : null;
      TripLocationData? endLocData = tripLocations.isNotEmpty ? tripLocations.last : null;

      _calculateTotalDistance().then((total) {
        state = state.copyWith(
          startLocData: startLocData,
          endLocData: endLocData,
          totalDistance: total,
          trackingStatus: '',
          isLoading: false,
          isTrackingStarted: false,
        );
      });
    }).catchError((error) {
      print('Error getting trip location data: $error');
      state = state.copyWith(isLoading: false, trackingStatus: '', isTrackingStarted: false);
    });
  }

  Future<double> _calculateTotalDistance() async {
    double totalDistance = 0;
    try {
      if (state.currentTripId != null) {
        final locations = await HiveService.getTripLocationDataByTripId(state.currentTripId!);
        for (var location in locations) {
          totalDistance += location.distance;
        }
        return totalDistance;
      } else {
        throw 'No current trip ID available';
      }
    } catch (e) {
      print('Error calculating total distance: $e');
      return 0;
    }
  }

  void continueToSecondScreen(BuildContext context) {
    if (state.startLocData != null && state.endLocData != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SecondScreen(
            startLoc: state.startLocData!.previousLoc,
            endLoc: state.endLocData!.currentLoc,
            totalDistance: state.totalDistance,
          ),
        ),
      );
    } else {
      Fluttertoast.showToast(msg: "Please complete a trip first to continue.", toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.BOTTOM);
    }
  }

  void stopListening() {
    _positionStream.cancel();
  }
}

final locationProvider = StateNotifierProvider<LocationNotifier, LocationState>((ref) {
  return LocationNotifier();
});
