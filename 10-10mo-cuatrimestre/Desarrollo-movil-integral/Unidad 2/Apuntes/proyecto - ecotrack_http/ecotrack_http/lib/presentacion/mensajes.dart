import '../dominio/falla_red.dart';

/// Lo que lee la persona usuaria. Dice qué pasó y qué puede hacer; nunca
/// muestra la excepción ni la URL.
String mensajePara(FallaRed falla) {
  return switch (falla) {
    SinConexion() => 'Sin conexión. Revisa tu red e intenta de nuevo.',
    TiempoAgotado() =>
      'El servidor tardó demasiado en responder. Intenta de nuevo.',
    ErrorDelServidor(:final codigo) =>
      'El servidor tuvo un problema ($codigo). Intenta más tarde.',
    PeticionRechazada(codigo: 404) => 'No encontramos lo que buscabas.',
    PeticionRechazada(codigo: 401 || 403) =>
      'No tienes permiso para ver esta información.',
    PeticionRechazada() =>
      'La solicitud no es válida. Avisa al equipo de desarrollo.',
    RespuestaInvalida() =>
      'Llegaron datos que no entendemos. Avisa al equipo de desarrollo.',
  };
}
