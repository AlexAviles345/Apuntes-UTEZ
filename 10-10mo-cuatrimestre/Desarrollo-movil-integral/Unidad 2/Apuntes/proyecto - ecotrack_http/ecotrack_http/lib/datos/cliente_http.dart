import 'package:dio/dio.dart';

const urlBase = 'https://jsonplaceholder.typicode.com';

Dio crearDio({
  String baseUrl = urlBase,
  List<Interceptor> interceptores = const [],
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 8),
      responseType: ResponseType.json,
      headers: {'Accept': 'application/json'},
    ),
  );
  dio.interceptors.addAll(interceptores);
  return dio;
}
