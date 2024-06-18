import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:locate_me2/models/user_model.dart';
import 'package:locate_me2/pages/home_page.dart';
import 'package:locate_me2/pages/login_page.dart';
import '../services/hive_service.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool _isLoggedIn = false;
  String? _currentUserPhone;

  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  String? get currentUserPhone => _currentUserPhone;

  Future<void> login(
      String phone, String password, BuildContext context) async {
    _isLoading = true;
    notifyListeners();

    if (phone.isEmpty) {
      _isLoading = false;
      Fluttertoast.showToast(msg: "Phone number cannot be empty");
      return;
    }

    if (password.isEmpty) {
      _isLoading = false;
      Fluttertoast.showToast(msg: "Password cannot be empty");
      return;
    }

    var user = await HiveService.getUser(phone, password);

    if (user != null) {
      _isLoading = false;
      _isLoggedIn = true;
      _currentUserPhone = user.phoneNumber;

      Fluttertoast.showToast(msg: "Login Successful");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } else {
      _isLoading = false;
      Fluttertoast.showToast(msg: "Invalid phone number or password");
    }
    notifyListeners();
  }

  String? getCurrentUserPhone() {
    return _currentUserPhone;
  }

  void logout(BuildContext context) {
    _isLoggedIn = false;
    Fluttertoast.showToast(msg: "Logged out successfully");
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
    notifyListeners();
  }

  Future<User?> getUser(String phone, String password) async {
    return await HiveService.getUser(phone, password);
  }
}