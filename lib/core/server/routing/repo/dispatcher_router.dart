import 'package:dart_flux/core/server/routing/repo/router.dart';

class DispatcherRouter extends Router {
  final List<Router> routers;
  DispatcherRouter(this.routers) {
    for (var router in routers) {
      this.router(router);
    }
  }
}
