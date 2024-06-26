import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locate_me2/models/user_details.dart';

abstract class UserDetailsState {
  const UserDetailsState();
}

class InitialUserDetailsState extends UserDetailsState {
  const InitialUserDetailsState();
}

class LoadingUserDetailsState extends UserDetailsState {
  const LoadingUserDetailsState();
}

class LoadedUserDetailsState extends UserDetailsState {
  final List<UserDetails> users;

  const LoadedUserDetailsState({required this.users});
}

class ErrorUserDetailsState extends UserDetailsState {
  final String errorMessage;

  const ErrorUserDetailsState(this.errorMessage);
}

class UserDetailsNotifier extends StateNotifier<UserDetailsState> {
  final Dio _dio = Dio();
  final int page;

  UserDetailsNotifier(this.page) : super(const InitialUserDetailsState()) {
    fetchUserDetails();
  }

  Future<void> fetchUserDetails() async {
    try {
      state = const LoadingUserDetailsState();
      const String baseUrl = 'https://reqres.in/api';
      const String endpoint = '/users';
      final String url = '$baseUrl$endpoint?page=$page';
      final response = await _dio.get(url);

      if (response.statusCode == 200) {
        final jsonData = response.data['data'] as List<dynamic>;
        final List<UserDetails> users =
            jsonData.map((e) => UserDetails.fromJson(e)).toList();
        state = LoadedUserDetailsState(users: users);
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      state = ErrorUserDetailsState('Error fetching user data: $e');
    }
  }
}

final userDetailsProvider =
    StateNotifierProvider.family<UserDetailsNotifier, UserDetailsState, int>(
        (ref, page) {
  return UserDetailsNotifier(page);
});
