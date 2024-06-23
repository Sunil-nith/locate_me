import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:locate_me2/models/user_model.dart';
import 'package:locate_me2/pages/home_page.dart';
import 'package:locate_me2/pages/login_page.dart';
import '../services/hive_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthState {
  final bool isLoading;
  final bool isLoggedIn;
  final String? currentUserPhone;

  AuthState({
    this.isLoading = false,
    this.isLoggedIn = false,
    this.currentUserPhone,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isLoggedIn,
    String? currentUserPhone,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      currentUserPhone: currentUserPhone ?? this.currentUserPhone,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState()) {
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userPhone = prefs.getString('userPhone');
    state = state.copyWith(
      isLoggedIn: userPhone != null,
      currentUserPhone: userPhone,
    );
  }

  Future<void> login(
      String phone, String password, BuildContext context) async {
    state = state.copyWith(isLoading: true);

    if (phone.isEmpty) {
      Fluttertoast.showToast(msg: "Phone number cannot be empty");
      state = state.copyWith(isLoading: false);
      return;
    }

    if (password.isEmpty) {
      Fluttertoast.showToast(msg: "Password cannot be empty");
      state = state.copyWith(isLoading: false);
      return;
    }

    var user = await HiveService.getUser(phone, password);

    if (user != null) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('userPhone', user.phoneNumber);

      state = state.copyWith(
        isLoading: false,
        isLoggedIn: true,
        currentUserPhone: user.phoneNumber,
      );

      Fluttertoast.showToast(msg: "Login Successful");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } else {
      Fluttertoast.showToast(msg: "Invalid phone number or password");
      state = state.copyWith(isLoading: false);
    }
  }

  void logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('userPhone');
    state = state.copyWith(
      isLoggedIn: false,
      currentUserPhone: null,
    );

    Fluttertoast.showToast(msg: "Logged out successfully");
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  Future<User?> getUser(String phone, String password) async {
    return await HiveService.getUser(phone, password);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
