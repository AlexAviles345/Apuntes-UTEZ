// DOMINIO - la identidad que la app necesita conocer. Dart puro.
//
// Minimización de datos (U2-S04-A01): de todo lo que trae el provedor de identidad,
// la app solo guarda el identificador y el correo.

class Usuario {
  const Usuario({required this.uid, required this.correo});

  // Identificador estable que asigna el provedor. Es la llave para todo lo
  // que pertenezca a esta persona (en S07 será la ruta de Firestore).
  final String uid;
  final String correo;

  @override
  bool operator ==(Object other) =>
      other is Usuario && other.uid == uid && other.correo == correo;

  @override
  int get hashCode => Object.hash(uid, correo);
}