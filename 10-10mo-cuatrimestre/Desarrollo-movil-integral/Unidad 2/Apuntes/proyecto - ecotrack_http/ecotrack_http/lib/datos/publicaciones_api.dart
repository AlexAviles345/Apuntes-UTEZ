import 'package:dio/dio.dart';
import 'package:ecotrack_http/datos/traducir_error.dart';
import 'package:ecotrack_http/dominio/falla_red.dart';
import 'package:ecotrack_http/dominio/publicacion.dart';

class PublicacionesApi {
  PublicacionesApi(this._dio);

  final Dio _dio;

  Future<List<Publicacion>> obtener({int limite = 10}) async {
    try {
      final respuesta = await _dio.get<Object?>(
        '/posts',
        queryParameters: {'_limit': limite},
      );

      final datos = respuesta.data;
      if (datos is! List) throw const RespuestaInvalida();
      return [
        for (final item in datos)
          switch (item) {
            Map<String, dynamic> json => Publicacion.fromJson(json),
            _ => throw const RespuestaInvalida(),
          },
      ];
    } on DioException catch (e) {
      throw traducirError(e);
    } on FormatException {
      throw const RespuestaInvalida();
    }
  }
}
