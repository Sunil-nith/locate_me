import 'package:hive/hive.dart';
part 'user_model.g.dart';

@HiveType(typeId: 0)
class User {
  @HiveField(0)
  String phoneNumber;

  @HiveField(1)
  String password;

  User({required this.phoneNumber, required this.password});
}
