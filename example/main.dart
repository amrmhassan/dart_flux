import 'package:dart_flux/core/app/models/fast_flux_app.dart';
import 'package:dart_flux/core/server/routing/repo/router.dart';

void main(List<String> args) async {
  var pathRouter = Router.crud('user');

  FastFluxApp app = FastFluxApp(pathRouter, port: 3000);
  await app.run();
}
