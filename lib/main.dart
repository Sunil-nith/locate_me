import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locate_me2/pages/home_page.dart';
import 'package:locate_me2/pages/login_page.dart';
import 'package:locate_me2/providers/auth_provider.dart';
import 'package:locate_me2/services/hive_service.dart';
import 'package:locate_me2/utils/hive_init.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveInit.init();
  await HiveService.prepopulateUserData();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return MaterialApp(
      title: 'LocateMe',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: _buildInitialScreen(authState),
    );
  }

  Widget _buildInitialScreen(AuthState authState) {
    if (authState is AuthenticatedAuthState) {
      return const HomePage();
    } else {
      return const LoginPage();
    }
  }
}
