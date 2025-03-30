// ignore_for_file: constant_identifier_names

import 'package:dart_flux/core/errors/server_error.dart';

enum HttpMethod {
  get,
  post,
  put,
  delete,
  head,
  connect,
  options,
  trace,
  patch,
  all,
}

HttpMethod methodFromString(String httpMethod) {
  var values = HttpMethod.values;
  int index = values.indexWhere(
    (e) => e.name.toLowerCase() == httpMethod.toLowerCase(),
  );
  if (index == -1) {
    throw ServerError('method $httpMethod not found');
  }
  return values[index];
}

// class HttpMethod {
//   static const _HttpMethodModel get = _GetMethod();
//   static const _HttpMethodModel post = _PostMethod();
//   static const _HttpMethodModel put = _PutMethod();
//   static const _HttpMethodModel delete = _DeleteMethod();
//   static const _HttpMethodModel head = _HeadMethod();
//   static const _HttpMethodModel connect = _CONNECTMethod();
//   static const _HttpMethodModel options = _OptionsMethod();
//   static const _HttpMethodModel trace = _TraceMethod();
//   static const _HttpMethodModel patch = _PatchMethod();

//   /// This will just use the request method
//   /// meaning that the `RoutingEntity` will run on each http method
//   static const _HttpMethodModel all = _All();

//   /// this is just useless
//   static const _HttpMethodModel unknown = _UnknownMethod();
// }

// class _HttpMethodModel {
//   final String method;
//   const _HttpMethodModel(this.method);
//   // static _HttpMethodModel fromString(String? m) {
//   //   String? method = m?.toLowerCase();
//   //   if (method == const _GetMethod().method) {
//   //     return const _GetMethod();
//   //   } else if (method == const _PostMethod().method) {
//   //     return const _PostMethod();
//   //   } else if (method == const _PutMethod().method) {
//   //     return const _PutMethod();
//   //   } else if (method == const _DeleteMethod().method) {
//   //     return const _DeleteMethod();
//   //   } else if (method == const _HeadMethod().method) {
//   //     return const _HeadMethod();
//   //   } else if (method == const _CONNECTMethod().method) {
//   //     return const _CONNECTMethod();
//   //   } else if (method == const _OptionsMethod().method) {
//   //     return const _OptionsMethod();
//   //   } else if (method == const _TraceMethod().method) {
//   //     return const _TraceMethod();
//   //   } else if (method == const _PatchMethod().method) {
//   //     return const _PatchMethod();
//   //   } else if (method == const _All().method) {
//   //     return const _All();
//   //   }
//   //   return const _UnknownMethod();
//   // }

//   @override
//   int get hashCode => method.hashCode;

//   @override
//   bool operator ==(Object other) {
//     return hashCode == other.hashCode;
//   }
// }

// class _GetMethod extends _HttpMethodModel {
//   const _GetMethod() : super('get');
// }

// class _PostMethod extends _HttpMethodModel {
//   const _PostMethod() : super('post');
// }

// class _PutMethod extends _HttpMethodModel {
//   const _PutMethod() : super('put');
// }

// class _DeleteMethod extends _HttpMethodModel {
//   const _DeleteMethod() : super('delete');
// }

// class _HeadMethod extends _HttpMethodModel {
//   const _HeadMethod() : super('head');
// }

// class _CONNECTMethod extends _HttpMethodModel {
//   const _CONNECTMethod() : super('connect');
// }

// class _OptionsMethod extends _HttpMethodModel {
//   const _OptionsMethod() : super('options');
// }

// class _TraceMethod extends _HttpMethodModel {
//   const _TraceMethod() : super('trace');
// }

// class _PatchMethod extends _HttpMethodModel {
//   const _PatchMethod() : super('patch');
// }

// class _All extends _HttpMethodModel {
//   const _All() : super('all');
// }

// class _UnknownMethod extends _HttpMethodModel {
//   const _UnknownMethod() : super('null');
// }
