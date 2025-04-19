import 'package:dart_flux/core/server/routing/models/model.dart';
import 'package:json_annotation/json_annotation.dart';
part 'tokens_model.g.dart';

@JsonSerializable(explicitToJson: true)
class TokensModel implements ModelInterface {
  final String accessToken;
  final String refreshToken;

  const TokensModel({required this.accessToken, required this.refreshToken});

  @override
  TokensModel fromJson(Json json) => _$TokensModelFromJson(json);

  @override
  Json toJson() => _$TokensModelToJson(this);
}
