import 'package:dart_flux/utils/path_utils.dart';

void main(List<String> args) {
  bool mine = PathUtils.pathMatches(
    requestPath: '/user/userid/alskdf/asdlf/sldkj',
    handlerPath: '/user/*',
  );
  print(mine);
}
