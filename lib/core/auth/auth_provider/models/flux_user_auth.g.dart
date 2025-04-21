// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'flux_user_auth.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FluxUserAuth _$FluxUserAuthFromJson(Map<String, dynamic> json) => FluxUserAuth(
  email: json['email'] as String,
  id: json['id'] as String,
  passwordHash: json['passwordHash'] as String,
  revokeDate:
      json['revokeDate'] == null
          ? null
          : DateTime.parse(json['revokeDate'] as String),
);

Map<String, dynamic> _$FluxUserAuthToJson(FluxUserAuth instance) =>
    <String, dynamic>{
      'email': instance.email,
      'id': instance.id,
      'passwordHash': instance.passwordHash,
      'revokeDate': instance.revokeDate?.toIso8601String(),
    };
