import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hive/hive.dart';
import 'package:locate_me2/models/trip_location_data.dart';
import 'package:locate_me2/pages/login_page.dart';
import 'package:locate_me2/pages/second_page.dart';
import 'package:locate_me2/providers/auth_provider.dart';
import 'package:locate_me2/providers/location_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationState = ref.watch(locationProvider);
    final authState = ref.watch(authProvider);

    ref.listen<AuthState>(authProvider, (prevState, currState) {
      if (currState is InitialAuthState) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
        Fluttertoast.showToast(msg: 'logout successful');
      } else if (currState is ErrorAuthState) {
        Fluttertoast.showToast(msg: currState.errorMessage);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('LocateMe'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authProvider.notifier).logout();
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
                return Consumer(builder: (context, watch, _) {
                  return locationState is LoadingLocationState
                      ? const Center(
                          child: CircularProgressIndicator(),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Center(
                              child: ElevatedButton(
                                onPressed: () {
                                  if (authState is AuthenticatedAuthState) {
                                    String? userId = authState.currentUserPhone;
                                    ref
                                        .read(locationProvider.notifier)
                                        .startTracking(userId);
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 40.0),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20.0),
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
                                onPressed: () => ref
                                    .read(locationProvider.notifier)
                                    .stopTracking(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 40.0),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20.0),
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
                            if (locationState is TripStartedLocationState)
                              Text(
                                locationState.trackingStatus,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            const SizedBox(height: 20),
                            if (locationState is TripCompletedLocationState)
                              Card(
                                elevation: 3.0,
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Start Location: ${locationState.startLocData?.previousLoc}',
                                        style: const TextStyle(fontSize: 16.0),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'End Location: ${locationState.endLocData?.currentLoc}',
                                        style: const TextStyle(fontSize: 16.0),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'Total Distance: ${locationState.totalDistance.toStringAsFixed(2)} km',
                                        style: const TextStyle(fontSize: 16.0),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        );
                });
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
      floatingActionButton: ElevatedButton(
        onPressed: () => _continueToSecondScreen(context, locationState),
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
      ),
    );
  }

  void _continueToSecondScreen(BuildContext context, LocationState state) {
    if (state is TripCompletedLocationState) {
      final currentState = state;
      if (currentState.startLocData != null &&
          currentState.endLocData != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SecondScreen(
              startLoc: currentState.startLocData!.previousLoc,
              endLoc: currentState.endLocData!.currentLoc,
              totalDistance: currentState.totalDistance,
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
    } else {
      Fluttertoast.showToast(
        msg: "Please complete a trip first to continue.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
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
                  SystemNavigator.pop();
                },
                child: const Text('Exit'),
              ),
            ],
          ),
        ) ??
        false;
  }
}
