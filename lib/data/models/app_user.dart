import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_user.freezed.dart';
part 'app_user.g.dart';

enum UserRole { student, staff, admin }

@freezed
abstract class AppUser with _$AppUser {
  const factory AppUser({
    required String id,
    required String registrationNumber,
    required String fullName,
    required UserRole role,
    required DateTime createdAt,
    String? department,
    String? yearOfStudy,
    String? email,
    String? phone,
  }) = _AppUser;

  factory AppUser.fromJson(Map<String, dynamic> json) =>
      _$AppUserFromJson(json);
}
