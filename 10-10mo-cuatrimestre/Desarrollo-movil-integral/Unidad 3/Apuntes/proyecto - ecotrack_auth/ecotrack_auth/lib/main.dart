// U2-S05-A03 — EcoTrack Auth (demo del docente).
//
// flutter run -> proveedor simulado (sin red)
// flutter run --dart-define=SESION_GUARDADA=true -> simulado, abre ya con sesión
// flutter run -d chrome --dart-define=EMULADOR=true
// -> Firebase Auth Emulator
// flutter run --dart-define=FIREBASE=true -> proyecto real de Firebase
// (antes: flutterfire configure)
//
// Este archivo es el único que elige el proveedor de identidad.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'datos/auth_repository.dart';
import 'datos/firebase_auth_repository.dart';
import 'datos/memoria_auth_repository.dart';
import 'dominio/usuario.dart';
import 'firebase_emulador.dart';

const _usarFirebase = bool.fromEnvironment('FIREBASE');
const _usarEmulador = bool.fromEnvironment('EMULADOR');
const _sesionGuardada = bool.fromEnvironment('SESION_GUARDADA');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(EcoTrackAuthApp(repositorio: await _crearRepositorio()));
}

Future<AuthRepository> _crearRepositorio() async {
  if (_usarEmulador) {
    final app = await Firebase.initializeApp(
      name: 'ecotrack-emulador',
      options: opcionesEmulador,
    );
    final auth = FirebaseAuth.instanceFor(app: app);
    await auth.useAuthEmulator(hostEmulador, 9099);
    return FirebaseAuthRepository(auth);
  }
  if (_usarFirebase) {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      throw UnsupportedError(
        'El modo Firebase real está configurado para Android.',
      );
    }
    await Firebase.initializeApp();
    return FirebaseAuthRepository(FirebaseAuth.instance);
  }
  return MemoriaAuthRepository(
    cuentas: {'demo@utez.edu.mx': 'ecotrack2026'},
    retardo: const Duration(milliseconds: 700),
    sesionGuardada: _sesionGuardada
        ? const Usuario(uid: 'uid-1', correo: 'demo@utez.edu.mx')
        : null,
  );
}
