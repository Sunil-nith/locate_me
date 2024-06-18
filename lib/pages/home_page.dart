import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:locate_me2/models/trip_location_data.dart';
import 'package:locate_me2/providers/auth_provider.dart';
import 'package:locate_me2/providers/location_provider.dart';
import 'package:provider/provider.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => LocationProvider(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('LocateMe'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                Provider.of<AuthProvider>(context, listen: false)
                    .logout(context);
              },
            ),
          ],
        ),
        body: PopScope(
          canPop: false,
          onPopInvoked: (didPop) async {
            await _showExitConfirmationDialog(context);
          },
          child: FutureBuilder(
            future: Hive.openBox<TripLocationData>('trip_location_data'),
            builder: (BuildContext context,
                AsyncSnapshot<Box<TripLocationData>> snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                if (!snapshot.hasError && snapshot.hasData) {
                  return Consumer<LocationProvider>(
                    builder: (context, locationProvider, _) {
                      return locationProvider.isLoading
                          ? const Center(
                              child: CircularProgressIndicator(),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Center(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      String? userId =
                                          Provider.of<AuthProvider>(context,
                                                  listen: false)
                                              .currentUserPhone;
                                      locationProvider.startTracking(userId!);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 40.0),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(20.0),
                                      ),
                                    ),
                                    child: const Text(
                                      'Start Tracking',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 18.0),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Center(
                                  child: ElevatedButton(
                                    onPressed: () =>
                                        locationProvider.stopTracking(context),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 40.0),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(20.0),
                                      ),
                                    ),
                                    child: const Text(
                                      'Stop Tracking',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 18.0),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                if (locationProvider.trackingStatus.isNotEmpty)
                                  Text(
                                    locationProvider.trackingStatus,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 18.0,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                const SizedBox(height: 20),
                                if (locationProvider.startLocData != null &&
                                    locationProvider.endLocData != null)
                                  Card(
                                    elevation: 3.0,
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Start Location: ${locationProvider.startLocData!.previousLoc}',
                                            style:
                                                const TextStyle(fontSize: 16.0),
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            'End Location: ${locationProvider.endLocData!.currentLoc}',
                                            style:
                                                const TextStyle(fontSize: 16.0),
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            'Total Distance: ${locationProvider.totalDistance.toStringAsFixed(2)} km',
                                            style:
                                                const TextStyle(fontSize: 16.0),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            );
                    },
                  );
                } else {
                  return const Center(
                    child: Text(
                      'Error opening Hive box',
                      style: TextStyle(color: Colors.red, fontSize: 18.0),
                    ),
                  );
                }
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            },
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: Consumer<LocationProvider>(
          builder: (context, locationProvider, _) {
            return ElevatedButton(
              onPressed: () => locationProvider.continueToSecondScreen(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
              ),
              child: const Text(
                'Continue',
                style: TextStyle(color: Colors.white, fontSize: 18.0),
              ),
            );
          },
        ),
      ),
    );
  }

 Future<bool> _showExitConfirmationDialog(BuildContext context) async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Exit'),
        content: const Text('Are you sure you want to exit?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              SystemNavigator.pop(); // Close the app
            },
            child: const Text('Exit'),
          ),
        ],
      ),
    ) ?? false;
  }
}
