import 'package:collection/collection.dart';

class FormErrorHelper {
  final Map<dynamic, dynamic>? errors;
  FormErrorHelper({this.errors});
  get hasErrors => this.errors != null;
  bool hasError(String key) =>
      hasErrors ? this.errors!.containsKey(key) : false;
  String? message(String key) {
    if (hasError(key)) {
      dynamic errorElement = this
          .errors!
          .entries
          .firstWhereOrNull((element) => element.key == key);
      if (errorElement != null) {
        return errorElement!.value;
      } else {
        return null;
      }
    } else {
      return null;
    }
  }
}