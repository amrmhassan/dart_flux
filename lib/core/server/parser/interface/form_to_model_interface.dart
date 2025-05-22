import 'package:dart_flux/core/server/parser/interface/bytes_file_saver_interface.dart';
import 'package:dart_flux/core/server/parser/interface/form_data_interface.dart';

abstract class FormToModelInterface {
  late FormDataInterface form;
  late BytesFileSaverInterface? fileSaver;
  Future<Map<dynamic, dynamic>> converter();
}
