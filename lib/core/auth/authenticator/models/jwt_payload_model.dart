// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:dart_flux/constants/date_constants.dart';
import 'package:json_annotation/json_annotation.dart';

import 'package:dart_flux/core/server/routing/models/model.dart';

part 'jwt_payload_model.g.dart';

@JsonSerializable(explicitToJson: true)
class JwtPayloadModel {
  final String userId;
  final DateTime issuedAt;
  final TokenType type;

  /// expires after time in seconds
  int? expiresAfter;

  JwtPayloadModel({
    required this.userId,
    required this.issuedAt,
    required this.type,
    this.expiresAfter,
  });
  factory JwtPayloadModel.fromJson(Json json) =>
      _$JwtPayloadModelFromJson(json);

  Json toJson() => _$JwtPayloadModelToJson(this);

  bool get expired {
    if (expiresAfter == null) return false;
    final expiresAt = issuedAt.add(Duration(seconds: expiresAfter!));
    return utc.isAfter(expiresAt);
  }

  bool isRevoked(DateTime? revokedAt) {
    if (revokedAt == null) return false;
    return revokedAt.isAfter(issuedAt);
  }
}

enum TokenType {
  @JsonValue('access')
  access,
  @JsonValue('refresh')
  refresh,
}
