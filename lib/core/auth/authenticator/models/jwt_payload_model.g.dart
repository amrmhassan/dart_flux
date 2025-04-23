// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'jwt_payload_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

JwtPayloadModel _$JwtPayloadModelFromJson(Map<String, dynamic> json) =>
    JwtPayloadModel(
      userId: json['userId'] as String,
      issuedAt: DateTime.parse(json['issuedAt'] as String),
      type: $enumDecode(_$TokenTypeEnumMap, json['type']),
      expiresAfter: (json['expiresAfter'] as num?)?.toInt(),
    );

Map<String, dynamic> _$JwtPayloadModelToJson(JwtPayloadModel instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'issuedAt': instance.issuedAt.toIso8601String(),
      'type': _$TokenTypeEnumMap[instance.type]!,
      'expiresAfter': instance.expiresAfter,
    };

const _$TokenTypeEnumMap = {
  TokenType.access: 'access',
  TokenType.refresh: 'refresh',
};
