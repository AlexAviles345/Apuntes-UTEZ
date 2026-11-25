import 'dart:async';

import 'package:ecotrack_auth/dominio/usuario.dart';
import 'package:flutter/cupertino.dart';

import '../datos/auth_repository.dart';
import '../dominio/falla_auth.dart';
import '../dominio/reglas_acceso.dart';

sealed class EstadoSesion{
  const EstadoSesion();
}

class Verificando extends EstadoSesion {
  const Verificando();
}

class SinSesion extends EstadoSesion {
  const SinSesion();
}

class ConSesion extends EstadoSesion {
  const ConSesion(this.usuario);
  final Usuario usuario;
}

class SesionViewModel extends ChangeNotifier {
  SesionViewModel(this._repositorio) {
    _suscripcion = _repositorio.cambiosDeSesion().listen(_alCambiarSesion);
  }

  final AuthRepository _repositorio;
  late final StreamSubscription<Usuario?> _suscripcion;

  EstadoSesion estado = const Verificando();
  bool procesando = false;
  String? error;

  Usuario? get usuario => switch (estado) {
    ConSesion(:final usuario) => usuario,
    _ => null,
  };

// La fuente de verdad de "¿hay sesión?" es el proveedor, no este método: // el estado solo cambia cuando el flujo de cambiosDeSesion() lo dice.
  void _alCambiarSesion(Usuario? usuario) {
    estado = usuario == null ? const SinSesion() : ConSesion(usuario);
    notifyListeners();
  }

  Future<bool> iniciarSesion(String correo, String contrasena) => _ejecutar(
    validarCorreo(correo) ?? validarContrasena(contrasena),
        () => _repositorio.iniciarSesion(correo, contrasena),
  );

  Future<bool> registrar(
      String correo,
      String contrasena,
      String confirmacion,
      ) => _ejecutar(
    validarCorreo(correo) ??
        validarContrasena(contrasena) ??
        validarConfirmacion(contrasena, confirmacion),
        () => _repositorio.registrar(correo, contrasena),
  );

  Future<void> cerrarSesion() => _repositorio.cerrarSesion();

  void limpiarError() {
    error = null;
    notifyListeners();
  }

  Future<bool> _ejecutar(String? motivo, Future<void> Function() accion) async {
// Evita el doble envío si tocan el botón dos veces.
    if (procesando) return false;
    if (motivo != null) {
      error = motivo;
      notifyListeners();
      return false;
    }

    procesando = true;
    error = null;
    notifyListeners();
    try {
      await accion();
      return true;
    } on FallaAuth catch (falla) {
      error = falla.mensaje;
      return false;
    } finally {
      procesando = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _suscripcion.cancel();
    super.dispose();
  }
}