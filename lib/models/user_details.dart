import 'package:freezed_annotation/freezed_annotation.dart';
part 'user_details.freezed.dart';
part 'user_details.g.dart';

@freezed
class UserDetails with _$UserDetails {
  const factory UserDetails({
    required int id,
    required String email,
    required String first_name,
    required String last_name,
    required String avatar,
  }) = _UserDetails;

  factory UserDetails.fromJson(Map<String, dynamic> json) => _$UserDetailsFromJson(json);
}
