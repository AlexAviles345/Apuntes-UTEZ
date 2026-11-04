class Publicacion {
  const Publicacion({
    required this.id,
    required this.autorId,
    required this.titulo,
    required this.cuerpo,
  });

  final int id;
  final int autorId;
  final String titulo;
  final String cuerpo;

  // Convertir JSON en un objeto tipo publicacion
  factory Publicacion.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'id': int id,
        'userId': int autoriId,
        'title': String titulo,
        'body': String cuerpo,
      } =>
        Publicacion(id: id, autorId: autoriId, titulo: titulo, cuerpo: cuerpo),
      _ => throw FormatException('Publicacion con forma inesperada', json),
    };
  }
}
