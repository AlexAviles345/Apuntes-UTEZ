import 'package:dio/dio.dart';

enum ModoFalla {
  ninguna('Normal'),
  sinRed('Sin red'),
  lento('Lento (timeout)'),
  servidor500('Servidor 500'),
  noEncontrado404('Ruta 404'),
  vacio('Respuesta vacía'),
  jsonRoto('JSON con otra forma');

  const ModoFalla(this.etiqueta);

  final String etiqueta;
}

/// Solo para la demo: provoca en vivo las fallas que en clase no se pueden/// esperar a que ocurran solas. No va en una app de producción.////// Corta la petición antes de que salga a la red. Usa `true` en `reject` y/// `resolve` para que los interceptores siguientes (la bitácora) también se/// enteren.
class FallaSimuladaInterceptor extends Interceptor {
  FallaSimuladaInterceptor({this.esperaLento = const Duration(seconds: 3)});

  ModoFalla modo = ModoFalla.ninguna;
  final Duration esperaLento;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    switch (modo) {
      case ModoFalla.ninguna:
        handler.next(options);
      case ModoFalla.sinRed:
        handler.reject(
          DioException.connectionError(
            requestOptions: options,
            reason: 'Simulada: sin red',
          ),
          true,
        );
      case ModoFalla.lento:
        await Future<void>.delayed(esperaLento);
        handler.reject(
          DioException.receiveTimeout(
            timeout: options.receiveTimeout ?? esperaLento,
            requestOptions: options,
          ),
          true,
        );
      case ModoFalla.servidor500:
        handler.reject(_conCodigo(options, 500), true);
      case ModoFalla.noEncontrado404:
        handler.reject(_conCodigo(options, 404), true);
      case ModoFalla.vacio:
        handler.resolve(
          Response(requestOptions: options, statusCode: 200, data: <Object>[]),
          true,
        );
      case ModoFalla.jsonRoto:
        handler.resolve(
          Response(
            requestOptions: options,
            statusCode: 200,
            data: {'mensaje': 'esto no es una lista'},
          ),
          true,
        );
    }
  }

  DioException _conCodigo(RequestOptions options, int codigo) {
    return DioException.badResponse(
      statusCode: codigo,
      requestOptions: options,
      response: Response(
        requestOptions: options,
        statusCode: codigo,
        data: {'error': 'Simulado $codigo'},
      ),
    );
  }
}
