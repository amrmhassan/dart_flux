// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'flux_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FluxUser _$FluxUserFromJson(Map<String, dynamic> json) => FluxUser(
  email: json['email'] as String,
  id: json['id'] as String,
  data: json['data'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$FluxUserToJson(FluxUser instance) => <String, dynamic>{
  'email': instance.email,
  'id': instance.id,
  'data': instance.data,
};
