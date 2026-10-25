const laboratoriosUtez = ['Lab Química', 'Lab Redes', 'Lab Física'];

/// Datos del consumo, independientes de Flutter y del formato de almacenamiento.
class Consumo {
  final String laboratorio;
  final double litros;
  final DateTime fecha;

  const Consumo({
    required this.laboratorio,
    required this.litros,
    required this.fecha,
  });
}
