import 'dart:async';

import 'package:dart_flux/core/server/routing/interface/http_entity.dart';
import 'package:dart_flux/core/server/routing/models/flux_request.dart';
import 'package:dart_flux/core/server/routing/models/flux_response.dart';

/// this is the processor function that deals with either the middleware or the handler itself
typedef Processor =
    FutureOr<HttpEntity> Function(
      FluxRequest request,
      FluxResponse response,

      /// this is the arguments passed to the path itself like
      /// /users/:user_id/getInfo => path template
      /// /users/159876663/getInfo => actual request path
      /// {'user_id':159876663} this will be the pathArgs map
      Map<String, dynamic> pathArgs,
    );
