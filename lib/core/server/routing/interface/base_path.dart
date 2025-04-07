import 'package:dart_flux/extensions/string_extensions.dart';
import 'package:dart_flux/utils/path_utils.dart';

abstract class BasePath {
  late String? pathTemplate;
  late BasePath? parent;

  BasePath() {
    setPath(pathTemplate);
  }

  void setPath(String? path) {
    String? pathTemplateCopy = path;
    if (pathTemplateCopy != null) {
      if (pathTemplateCopy == '/') {
        pathTemplate = '';
        return;
      }
      pathTemplateCopy = '/' + pathTemplateCopy.strip('/');
      pathTemplate = pathTemplateCopy;
    }
  }

  String? get finalPath {
    return PathUtils.finalPath(parent, pathTemplate);
  }
}
