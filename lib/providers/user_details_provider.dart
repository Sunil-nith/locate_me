import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:locate_me2/models/user_details.dart';

class UserDetailsProvider extends ChangeNotifier {
  final Dio _dio = Dio();
  final Map<int, List<UserDetails>> _userDataPerPage = {};
  bool _isLoading = false;
  bool _hasError = false;
  int _currentPage = 1;
  List<UserDetails> get userData => _userDataPerPage[_currentPage] ?? [];
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  int get currentPage => _currentPage;

  Future<void> fetchUserDetails({int page = 1}) async {
    try {
      _isLoading = true;
      _hasError = false;
      notifyListeners();
      const String baseUrl = 'https://reqres.in/api';
      const String endpoint = '/users';
      final String url = '$baseUrl$endpoint?page=$page';
      final response = await _dio.get(url);
      if (response.statusCode == 200) {
        final jsonData = response.data['data'] as List<dynamic>;
        final List<UserDetails> users =
            jsonData.map((e) => UserDetails.fromJson(e)).toList();
        _userDataPerPage[page] = users;
        _isLoading = false;
        _currentPage = page;
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print('Error fetching user data: $e');
      _hasError = true;
      _isLoading = false;
    } finally {
      notifyListeners();
    }
  }
}
