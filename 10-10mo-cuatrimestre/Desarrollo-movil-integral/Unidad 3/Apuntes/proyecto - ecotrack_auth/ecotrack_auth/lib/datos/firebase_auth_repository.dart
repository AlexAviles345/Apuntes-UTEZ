// DATOS — adaptador de Firebase Authentication.
//
// Es el único archivo de la app que importa firebase_auth. Traduce:
// User de Firebase -> Usuario del dominio
// FirebaseAuthException -> FallaAuth del dominio

import 'package:firebase_auth/firebase_auth.dart';

import '../dominio/falla_auth.dart';
import '../dominio/usuario.dart';
import 'auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth);

  final FirebaseAuth _auth;

// authStateChanges() emite el usuario guardado al suscribirse: así se
// restaura la sesión al abrir la app, sin pedir la contraseña otra vez.
  @override
  Stream<Usuario?> cambiosDeSesion() => _auth.authStateChanges().map(_aUsuario);

  @override
  Future<Usuario> registrar(String correo, String contrasena) => _intentar(
        () => _auth.createUserWithEmailAndPassword(
      email: correo.trim(),
      password: contrasena,
    ),
  );

  @override
  Future<Usuario> iniciarSesion(String correo, String contrasena) => _intentar(
        () => _auth.signInWithEmailAndPassword(
      email: correo.trim(),
      password: contrasena,
    ),
  );

  @override
  Future<void> cerrarSesion() => _auth.signOut();

  Future<Usuario> _intentar(Future<UserCredential> Function() operacion) async {
    try {
      final credencial = await operacion();
      return _aUsuario(credencial.user)!;
    } on FirebaseAuthException catch (e) {
      throw traducirErrorAuth(e);
    }
  }

  static Usuario? _aUsuario(User? user) =>
      user == null ? null : Usuario(uid: user.uid, correo: user.email ?? '');
}

// Pública para poder probarla sin Firebase.
FallaAuth traducirErrorAuth(FirebaseAuthException e) => switch (e.code) {
// Con la protección contra enumeración de correos (activa por omisión en
// proyectos nuevos) Firebase responde 'invalid-credential' en ambos casos;
// los códigos viejos se agrupan igual para no filtrar cuál de los dos fue.
  'invalid-credential' ||
  'wrong-password' ||
  'user-not-found' ||
  'user-disabled' => const CredencialesInvalidas(),
  'email-already-in-use' => const CorreoEnUso(),
  'weak-password' ||
  'password-does-not-meet-requirements' => const ContrasenaDebil(),
  'invalid-email' => const CorreoInvalido(),
  'too-many-requests' => const DemasiadosIntentos(),
  'network-request-failed' => const SinConexion(),
  _ => const FallaDesconocida(),
};