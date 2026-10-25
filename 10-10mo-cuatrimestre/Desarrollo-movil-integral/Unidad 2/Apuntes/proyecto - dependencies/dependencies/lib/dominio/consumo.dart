const laboratrio = ['lab Quimica', 'Lab fisica', 'Lab Redes'];

class Consumo {
  const Consumo ({
    required this.laboratorio,
    required this.litros,
    required this.kwh,
});

  final String laboratorio;
  final double litros;
  final double kwh;
}

class ReglaConsumo {
  static const topeLitros = 10000.0;

  static const topeKwh = 500;

  static String? validarLitros(double? litros){
    if (litros == null) return 'Escribe litros';
    if (litros <= 0) return 'los litros deben ser mayores que cero';
    if (litros >= topeLitros) return 'los litros superan el tope';
    return null;
  }


  static String? validarKwh(double? kwh){
    if (kwh == null) return 'Escribe kwh';
    if (kwh <= 0) return 'los kwh deben ser mayores que cero';
    if (kwh >= topeLitros) return 'los kwh superan el tope';
    return null;
  }
}

class ReglaCorreo{
  static bool esInstitucional(String correo){
    final limpio = correo.trim().toLowerCase();
    return limpio.endsWith('@utez.edu.mx') && limpio.length > 12;
  }
}

class MetaSemenal{
  const MetaSemenal (this.litrosMeta);

  final double litrosMeta;

  bool seAcerca(double litrosConsumidos) => litrosConsumidos >= litrosMeta * 0.8;

}