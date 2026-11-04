import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import '../datos/publicaciones_api.dart';
import '../dominio/falla_red.dart';
import '../dominio/publicacion.dart';
import 'mensajes.dart';

/// Los cinco estados posibles de la pantalla. Uno a la vez: no hay forma de
/// estar "cargando" y "con error" al mismo tiempo.
sealed class EstadoPublicaciones {
  const EstadoPublicaciones();
}

final class Inicial extends EstadoPublicaciones {
  const Inicial();
}

final class Cargando extends EstadoPublicaciones {
  const Cargando();
}

final class ConDatos extends EstadoPublicaciones {
  const ConDatos(this.publicaciones);

  final List<Publicacion> publicaciones;
}

final class Vacio extends EstadoPublicaciones {
  const Vacio();
}

final class ConError extends EstadoPublicaciones {
  const ConError(this.mensaje);

  final String mensaje;
}

class PublicacionesViewModel extends ChangeNotifier {
  PublicacionesViewModel(this._api);

  final PublicacionesApi _api;

  EstadoPublicaciones _estado = const Inicial();

  EstadoPublicaciones get estado => _estado;

  bool get cargando => _estado is Cargando;

  bool _liberado = false;

  Future<void> cargar() async {
    if (cargando) return;
    _cambiar(const Cargando());
    try {
      final publicaciones = await _api.obtener();
      _cambiar(publicaciones.isEmpty ? const Vacio() : ConDatos(publicaciones));
    } on FallaRed catch (falla) {
      _cambiar(ConError(mensajePara(falla)));
    } catch (e, pila) {
      developer.log(
        'Error no previsto',
        name: 'http',
        error: e,
        stackTrace: pila,
      );
      _cambiar(const ConError('Algo salió mal. Intenta de nuevo.'));
    }
  }

  void _cambiar(EstadoPublicaciones nuevo) {
    _estado = nuevo;
    if (!_liberado) notifyListeners();
  }

  @override
  void dispose() {
    _liberado = true;
    super.dispose();
  }
}
