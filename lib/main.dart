import 'package:flutter/material.dart';
import 'package:locate_me2/pages/home_page.dart';
import 'package:locate_me2/pages/login_page.dart';
import 'package:locate_me2/providers/auth_provider.dart';
import 'package:locate_me2/providers/location_provider.dart';
import 'package:locate_me2/providers/user_details_provider.dart';
import 'package:locate_me2/services/hive_service.dart';
import 'package:locate_me2/utils/hive_init.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveInit.init();
  await HiveService.prepopulateUserData();
   runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserDetailsProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AuthProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
       home: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          if (authProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (authProvider.isLoggedIn) {
            return const HomePage();
          } else {
            return const LoginPage();
          }
        },
      ),
      ),
    );
  }
}
