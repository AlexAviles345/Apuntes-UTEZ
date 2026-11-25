// DATOS — proveedor de identidad simulado, en memoria.
//
// Sirve para dar la clase sin internet y para las pruebas. Se comporta como
// Firebase en lo que importa: emite la sesión al suscribirse, rechaza con los
// mismos tipos de falla y puede simular que no hay red.

import 'dart:async';

import '../dominio/falla_auth.dart';
import '../dominio/usuario.dart';
import 'auth_repository.dart';

class MemoriaAuthRepository implements AuthRepository {
  MemoriaAuthRepository({
    Usuario? sesionGuardada,
    Map<String, String> cuentas = const {},
    this.retardo = Duration.zero,
  }) : _actual = sesionGuardada {
    cuentas.forEach((correo, contrasena) {
      _cuentas[correo] = _Cuenta('uid-${_cuentas.length + 1}', contrasena);
    });
    if (sesionGuardada != null) {
      _cuentas.putIfAbsent(
        sesionGuardada.correo,
            () => _Cuenta(sesionGuardada.uid, ''),
      );
    }
  }

  // Simula la latencia de la red para que se vea el estado "procesando".
  final Duration retardo;

  // Interruptor de la demo: con true, toda operación falla con SinConexion.
  bool sinRed = false;

  final Map<String, _Cuenta> _cuentas = {};
  final _cambios = StreamController<Usuario?>.broadcast();
  Usuario? _actual;

  // Cada suscriptor recibe primero la sesión actual y luego cada cambio.
  // Se conecta al flujo interno en el mismo instante de suscribirse para no
  // perder un cierre de sesión que ocurra justo después.
  @override
  Stream<Usuario?> cambiosDeSesion() {
    StreamSubscription<Usuario?>? interna;
    late final StreamController<Usuario?> salida;
    salida = StreamController<Usuario?>(
      onListen: () {
        salida.add(_actual);
        interna = _cambios.stream.listen(salida.add);
      },
      onCancel: () => interna?.cancel(),
    );
    return salida.stream;
  }

  @override
  Future<Usuario> registrar(String correo, String contrasena) async {
    await _esperarRed();
    final clave = correo.trim().toLowerCase();
    if (_cuentas.containsKey(clave)) throw const CorreoEnUso();
    if (contrasena.length < 6) throw const ContrasenaDebil();
    final cuenta = _Cuenta('uid-${_cuentas.length + 1}', contrasena);
    _cuentas[clave] = cuenta;
    return _abrirSesion(Usuario(uid: cuenta.uid, correo: clave));
  }

  @override
  Future<Usuario> iniciarSesion(String correo, String contrasena) async {
    await _esperarRed();
    final clave = correo.trim().toLowerCase();
    final cuenta = _cuentas[clave];
    // Mismo error si no existe o si la contraseña no coincide.
    if (cuenta == null || cuenta.contrasena != contrasena) {
      throw const CredencialesInvalidas();
    }
    return _abrirSesion(Usuario(uid: cuenta.uid, correo: clave));
  }

  @override
  Future<void> cerrarSesion() async {
    _actual = null;
    _cambios.add(null);
  }

  Usuario _abrirSesion(Usuario usuario) {
    _actual = usuario;
    _cambios.add(usuario);
    return usuario;
  }

  Future<void> _esperarRed() async {
    if (retardo > Duration.zero) await Future<void>.delayed(retardo);
    if (sinRed) throw const SinConexion();
  }
}

class _Cuenta {
  _Cuenta(this.uid, this.contrasena);
  final String uid;
  final String contrasena;
}