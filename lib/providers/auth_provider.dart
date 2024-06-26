import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locate_me2/models/user_model.dart';
import 'package:locate_me2/services/hive_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class AuthState {
  const AuthState();
}

class InitialAuthState extends AuthState {
  const InitialAuthState();
}

class LoadingAuthState extends AuthState {
  const LoadingAuthState();
}

class AuthenticatedAuthState extends AuthState {
  final String currentUserPhone;

  const AuthenticatedAuthState({
    required this.currentUserPhone,
  });
}

class ErrorAuthState extends AuthState {
  final String errorMessage;

  const ErrorAuthState(this.errorMessage);
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const InitialAuthState()) {
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userPhone = prefs.getString('userPhone');
    if (userPhone != null) {
      state = AuthenticatedAuthState(currentUserPhone: userPhone);
    }
  }

  Future<void> login(String phone, String password) async {
    state = const LoadingAuthState();

    if (phone.isEmpty) {
      state = const ErrorAuthState("Phone number cannot be empty");
      return;
    }

    if (password.isEmpty) {
      state = const ErrorAuthState("Password cannot be empty");
      return;
    }

    var user = await HiveService.getUser(phone, password);

    if (user != null) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('userPhone', user.phoneNumber);

      state = AuthenticatedAuthState(currentUserPhone: user.phoneNumber);
    } else {
      state = const ErrorAuthState("Invalid phone number or password");
    }
  }

  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('userPhone');
    state = const InitialAuthState();
  }

  Future<User?> getUser(String phone, String password) async {
    return await HiveService.getUser(phone, password);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
