import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:locate_me2/models/trip_location_data.dart';
import 'package:locate_me2/pages/second_page.dart';
import 'package:locate_me2/services/location_service.dart';
import '../services/hive_service.dart';

class LocationProvider extends ChangeNotifier {
  Position? _currentPosition;
  Position? _previousPosition;
  bool _tracking = false;
  double totalDistance = 0.0;
  TripLocationData? _startLocData;
  TripLocationData? _endLocData;
  bool _isLoading = false;
  String _trackingStatus = '';
  bool _isTrackingStarted = false;
  String? _currentTripId;
  String _userId = '';
  late StreamSubscription<Position> _positionStream;

   Future<void> startTracking(String userPhone) async {
    _userId = userPhone;
    _isLoading = true;
    notifyListeners();
    _startLocData = null;
    _endLocData = null;
    _currentTripId = DateTime.now().millisecondsSinceEpoch.toString();

    if (!await LocationService.checkLocationServicesEnabled()) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    if (!await LocationService.checkAndRequestLocationPermissions()) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      _previousPosition = await LocationService.getCurrentPosition();
      if (_previousPosition == null) {
        _isLoading = false;
        notifyListeners();
        return;
      }
      _tracking = true;
      _addTripLocationData(_previousPosition!, _previousPosition!, 0);
      _trackingStatus = 'Tracking is in progress...';
      notifyListeners();
      _getPositionUpdates();
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error starting tracking: $e",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
      print('Error starting tracking: $e');
    } finally {
      _isLoading = false;
      _isTrackingStarted = true;
      notifyListeners();
    }
  }
  // Stop tracking method
  void stopTracking(BuildContext context) {
    if (!_isTrackingStarted) {
      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('Start Tracking'),
          content: const Text('Please start the trip first.'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('Confirm Stop'),
          content: const Text('Are you sure you want to stop tracking?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Stop'),
              onPressed: () {
                Navigator.of(context).pop();
                _performStopTracking();
              },
            ),
          ],
        ),
      );
    }
  }

  // Get position updates method
  void _getPositionUpdates() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );
    _positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position position) {
      if (_tracking) {
        _currentPosition = position;
        notifyListeners();
        if (_previousPosition != null) {
          double distance = Geolocator.distanceBetween(
                _previousPosition!.latitude,
                _previousPosition!.longitude,
                _currentPosition!.latitude,
                _currentPosition!.longitude,
              ) /
              1000;
          _addTripLocationData(_previousPosition!, _currentPosition!, distance);
          _previousPosition = _currentPosition;
        }
      }
    });
  }

// Add trip location data method
  void _addTripLocationData(
      Position previous, Position current, double distance) {
    final data = TripLocationData(
      previousLoc: '${previous.latitude}, ${previous.longitude}',
      currentLoc: '${current.latitude}, ${current.longitude}',
      distance: distance,
      tripId: _currentTripId!,
      userId: _userId,
    );
    HiveService.addTripLocationData(data);
  }

  // Perform stop tracking method
  void _performStopTracking() {
    _isLoading = true;
    _trackingStatus = 'Stopping tracking...';
    notifyListeners();
    _tracking = false;
    stopListening();
    HiveService.getTripLocationDataByTripId(_currentTripId!)
        .then((tripLocations) {
      if (tripLocations.isEmpty) {
        _startLocData = null;
        _endLocData = null;
      } else {
        _startLocData = tripLocations.first;
        _endLocData = tripLocations.last;
      }
      _calculateTotalDistance().then((total) {
        totalDistance = total;
        _startLocData = _startLocData;
        _endLocData = _endLocData;
        _trackingStatus = '';
        _isLoading = false;
        _isTrackingStarted = false;
        notifyListeners();
      });
    }).catchError((error) {
      print('Error getting trip location data: $error');
      _isLoading = false;
      _trackingStatus = '';
      _isTrackingStarted = false;
      notifyListeners();
    });
  }

  // Calculate total distance method
  Future<double> _calculateTotalDistance() async {
    double totalDistance = 0;
    try {
      if (_currentTripId != null) {
        final locations =
            await HiveService.getTripLocationDataByTripId(_currentTripId!);
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

  // Continue to second screen method
  void continueToSecondScreen(BuildContext context) {
    if (_startLocData != null && _endLocData != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SecondScreen(
            startLoc: _startLocData!.previousLoc,
            endLoc: _endLocData!.currentLoc,
            totalDistance: totalDistance,
          ),
        ),
      );
    } else {
      Fluttertoast.showToast(
        msg: "Please complete a trip first to continue.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }



  // Stop listening to position updates
  void stopListening() {
    _positionStream.cancel();
  }

  // Getters for private variables
  bool get isLoading => _isLoading;
  String get trackingStatus => _trackingStatus;
  bool get isTrackingStarted => _isTrackingStarted;
  TripLocationData? get startLocData => _startLocData;
  TripLocationData? get endLocData => _endLocData;
}
