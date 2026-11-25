// DOMINIO — fallas de autenticación con el mensaje que ve la persona.
//
// La app nunca muestra el código crudo del proveedor ('invalid-credential',
// 'network-request-failed'…): lo traduce la capa de datos a una de estas.

sealed class FallaAuth implements Exception {
  const FallaAuth(this.mensaje);
  final String mensaje;

  @override
  String toString() => mensaje;
}

// Un solo mensaje para "no existe" y "contraseña incorrecta": así no se le
// dice a un atacante qué correos están registrados (enumeración de cuentas).
class CredencialesInvalidas extends FallaAuth {
  const CredencialesInvalidas() : super('Correo o contraseña incorrectos');
}

class CorreoEnUso extends FallaAuth {
  const CorreoEnUso() : super('Ya existe una cuenta con ese correo');
}

class ContrasenaDebil extends FallaAuth {
  const ContrasenaDebil() : super('Esa contraseña es muy débil');
}

class CorreoInvalido extends FallaAuth {
  const CorreoInvalido() : super('Ese correo no es válido');
}

class DemasiadosIntentos extends FallaAuth {
  const DemasiadosIntentos()
      : super('Demasiados intentos. Espera unos minutos e inténtalo de nuevo');
}

class SinConexion extends FallaAuth {
  const SinConexion()
      : super('Sin conexión. Revisa tu red e inténtalo de nuevo');
}

class FallaDesconocida extends FallaAuth {
  const FallaDesconocida() : super('No pudimos completar la operación');
}