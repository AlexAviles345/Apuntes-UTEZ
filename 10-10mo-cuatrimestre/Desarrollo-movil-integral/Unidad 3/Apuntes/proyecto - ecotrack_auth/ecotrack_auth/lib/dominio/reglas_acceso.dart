const longitudMinimaContrasena = 8;

final _formatoCorreo = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

// Validar correo
String? validarCorreo(String correo){
  final limpio = correo.trim();

  if(limpio.isEmpty) return 'Escribe tu correo';
  if(!_formatoCorreo.hasMatch(limpio)) return 'Ese correo no es válido';

  return null;
}

// Validar contraseña
// que no sea vacio
// Y que cumpla con la longitud minima
String? validarContrasena(String contrasena){
  if(contrasena.isEmpty) return 'Escribe tu contraseña';
  if(contrasena.length < longitudMinimaContrasena) {
    return 'Usa al menos $longitudMinimaContrasena caracteres';
  };
  return null;
}

// Validar confirmacion
// deben comparar la contraseña con la contraseña de confirmacion
String? validarConfirmacion(String contrasena, String confirmacion){
  if (confirmacion != contrasena) return 'Las contraseñas no coinciden';
  return null;
}