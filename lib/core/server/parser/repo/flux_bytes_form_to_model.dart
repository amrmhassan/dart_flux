import 'package:dart_flux/core/server/parser/interface/bytes_file_saver_interface.dart';
import 'package:dart_flux/core/server/parser/interface/form_data_interface.dart';
import 'package:dart_flux/core/server/parser/interface/form_to_model_interface.dart';

class FluxBytesFormToModel implements FormToModelInterface {
  @override
  FormDataInterface form;
  FluxBytesFormToModel(this.form, {this.fileSaver});

  @override
  Future<Map<dynamic, dynamic>> converter() async {
    Map<dynamic, dynamic> model = {};
    // we will know if the field is a list if we found a [] at it's key end or if we found multiple keys with the same name
    for (var field in form.fields) {
      var key = field.key;
      var fieldValue = field.value;
      if (key == null || key.isEmpty) {
        continue;
      }
      bool isList = model.containsKey(key) || key.endsWith('[]');
      if (isList) {
        var value = model[key];
        if (value is List) {
          value.add(fieldValue);
          model[key] = value;
        } else {
          model[key] = [fieldValue, value];
        }
      } else {
        model[key] = fieldValue;
      }
    }

    return model;
  }

  @override
  BytesFileSaverInterface? fileSaver;
}
