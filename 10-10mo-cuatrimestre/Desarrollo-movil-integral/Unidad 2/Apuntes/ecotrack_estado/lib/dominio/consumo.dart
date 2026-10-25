// DOMINIO — igual en las tres variantes.

// Constante con los laboratorios que se pueden elegir en el formulario.
// No es estado: nunca cambia mientras la app corre.
const laboratoriosUtez = ['Lab Química', 'Lab Redes', 'Lab Física'];

// Entidad del dominio: un registro de consumo de agua.
class Consumo {
  // Constructor const con parámetros nombrados y obligatorios.
  const Consumo({required this.laboratorio, required this.litros});

  // Laboratorio donde se registró el consumo.
  final String laboratorio;
  // Cantidad de litros consumidos.
  final double litros;
}

// Regla del dominio: devuelve un mensaje de error o null si los litros son válidos.
String? validarLitros(double? litros) {
  // Si no se pudo convertir el texto a número, llega null.
  if (litros == null) return 'Escribe los litros con número';
  // No se aceptan cero ni negativos.
  if (litros <= 0) return 'Los litros deben ser mayores que cero';
  // Tope máximo permitido.
  if (litros > 10000) return 'Los litros superan el tope de 10000';
  // null significa "sin error".
  return null;
}
