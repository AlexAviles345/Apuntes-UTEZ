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
import 'package:flutter/material.dart';

import 'app.dart';
import 'datos/auth_repository.dart';
import 'datos/firebase_auth_repository.dart';
import 'datos/memoria_auth_repository.dart';
import 'dominio/usuario.dart';
import 'firebase_emulador.dart';
import 'firebase_options.dart';

const _usarFirebase = bool.fromEnvironment('FIREBASE');
const _usarEmulador = bool.fromEnvironment('EMULADOR');
const _sesionGuardada = bool.fromEnvironment('SESION_GUARDADA');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(EcoTrackAuthApp(repositorio: await _crearRepositorio()));
}

Future<AuthRepository> _crearRepositorio() async {
  if (_usarEmulador) {
    await Firebase.initializeApp(options: opcionesEmulador);
    await FirebaseAuth.instance.useAuthEmulator(hostEmulador, 9099);
    return FirebaseAuthRepository(FirebaseAuth.instance);
  }
  if (_usarFirebase) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
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