// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AppUser _$AppUserFromJson(Map<String, dynamic> json) => _AppUser(
  id: json['id'] as String,
  registrationNumber: json['registrationNumber'] as String,
  fullName: json['fullName'] as String,
  role: $enumDecode(_$UserRoleEnumMap, json['role']),
  createdAt: DateTime.parse(json['createdAt'] as String),
  department: json['department'] as String?,
  yearOfStudy: json['yearOfStudy'] as String?,
  email: json['email'] as String?,
  phone: json['phone'] as String?,
);

Map<String, dynamic> _$AppUserToJson(_AppUser instance) => <String, dynamic>{
  'id': instance.id,
  'registrationNumber': instance.registrationNumber,
  'fullName': instance.fullName,
  'role': _$UserRoleEnumMap[instance.role]!,
  'createdAt': instance.createdAt.toIso8601String(),
  'department': instance.department,
  'yearOfStudy': instance.yearOfStudy,
  'email': instance.email,
  'phone': instance.phone,
};

const _$UserRoleEnumMap = {
  UserRole.student: 'student',
  UserRole.staff: 'staff',
  UserRole.admin: 'admin',
};
