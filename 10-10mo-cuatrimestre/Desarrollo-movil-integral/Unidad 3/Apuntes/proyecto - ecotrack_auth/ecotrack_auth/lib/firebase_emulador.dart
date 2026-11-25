// Opciones para trabajar contra Firebase Local Emulator Suite.
//
// Los proyectos con id "demo-…" solo existen en el emulador: no hace falta
// cuenta de Firebase ni internet, y nada de lo que se haga sale de la máquina.
// Arrancar antes:  firebase emulators:start --project demo-ecotrack

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

const opcionesEmulador = FirebaseOptions(
  apiKey: 'demo-api-key',
  appId: '1:000000000000:web:0000000000000000000000',
  messagingSenderId: '000000000000',
  projectId: 'demo-ecotrack',
  authDomain: 'demo-ecotrack.firebaseapp.com',
);

// El emulador de Android ve la máquina anfitriona en 10.0.2.2, no en localhost.
// Para un teléfono físico: --dart-define=HOST_EMULADOR=<IP de la laptop>.
String get hostEmulador {
  const definido = String.fromEnvironment('HOST_EMULADOR');
  if (definido.isNotEmpty) return definido;
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return '10.0.2.2';
  }
  return 'localhost';
}