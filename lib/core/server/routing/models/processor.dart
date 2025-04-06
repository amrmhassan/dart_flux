import 'dart:async';

import 'package:dart_flux/core/server/routing/interface/http_entity.dart';
import 'package:dart_flux/core/server/routing/models/flux_request.dart';
import 'package:dart_flux/core/server/routing/models/flux_response.dart';

/// A processor function type that deals with either middleware or handler logic.
///
/// This function type defines the signature for processors (middleware or handlers) that are responsible for handling
/// HTTP requests and responses. The processor function takes in the [FluxRequest], [FluxResponse], and a [pathArgs] map.
typedef Processor =
    FutureOr<HttpEntity> Function(
      FluxRequest request,
      FluxResponse response,

      /// A map of path arguments extracted from the request path.
      /// For example, for a path template like `/users/:user_id/getInfo`:
      /// - Path template: `/users/:user_id/getInfo`
      /// - Actual request path: `/users/159876663/getInfo`
      /// - pathArgs: `{'user_id': 159876663}`
      Map<String, dynamic> pathArgs,
    );

/// A processor handler function type that specifically returns a [FluxResponse].
///
/// This function type is for processor handlers that only deal with returning a [FluxResponse].
/// It processes the [FluxRequest], [FluxResponse], and a [pathArgs] map.
typedef ProcessorHandler =
    FutureOr<FluxResponse> Function(
      FluxRequest request,
      FluxResponse response,

      /// A map of path arguments extracted from the request path.
      /// Example usage:
      /// - Path template: `/users/:user_id/getInfo`
      /// - Request path: `/users/159876663/getInfo`
      /// - pathArgs: `{'user_id': 159876663}`
      Map<String, dynamic> pathArgs,
    );
