import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locate_me2/models/user_details.dart';

@immutable
class UserDetailsState {
  final Map<int, List<UserDetails>> userDataPerPage;
  final bool isLoading;
  final bool hasError;
  final int currentPage;

  const UserDetailsState({
    this.userDataPerPage = const {},
    this.isLoading = false,
    this.hasError = false,
    this.currentPage = 1,
  });

  UserDetailsState copyWith({
    Map<int, List<UserDetails>>? userDataPerPage,
    bool? isLoading,
    bool? hasError,
    int? currentPage,
  }) {
    return UserDetailsState(
      userDataPerPage: userDataPerPage ?? this.userDataPerPage,
      isLoading: isLoading ?? this.isLoading,
      hasError: hasError ?? this.hasError,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}


class UserDetailsNotifier extends StateNotifier<UserDetailsState> {
  final Dio _dio = Dio();
  UserDetailsNotifier() : super(const UserDetailsState());

  Future<void> fetchUserDetails({int page = 1}) async {
    try {
      state = state.copyWith(isLoading: true, hasError: false);
      const String baseUrl = 'https://reqres.in/api';
      const String endpoint = '/users';
      final String url = '$baseUrl$endpoint?page=$page';
      final response = await _dio.get(url);
      if (response.statusCode == 200) {
        final jsonData = response.data['data'] as List<dynamic>;
        final List<UserDetails> users =
            jsonData.map((e) => UserDetails.fromJson(e)).toList();
        final newUserDataPerPage = Map<int, List<UserDetails>>.from(state.userDataPerPage);
        newUserDataPerPage[page] = users;
        state = state.copyWith(
          userDataPerPage: newUserDataPerPage,
          isLoading: false,
          currentPage: page,
        );
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print('Error fetching user data: $e');
      state = state.copyWith(hasError: true, isLoading: false);
    }
  }
}

final userDetailsProvider = StateNotifierProvider<UserDetailsNotifier, UserDetailsState>((ref) {
  return UserDetailsNotifier();
});
