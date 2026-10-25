// Tipo Unitarios, Se aprueba una regla sin pantalla y sin necesidad de red

import 'package:dpendencies/dominio/consumo.dart';
import 'package:flutter_test/flutter_test.dart';

void main(){
  group('Historia: Registrar consumo', (){

    test('Validar litros: rechazar no positivos y valores desde el tope', (){

      // Rechazar cantidades menores o iguales a cero.
      expect(ReglaConsumo.validarLitros(0), isNotNull);
      expect(ReglaConsumo.validarLitros(-3), isNotNull);
      expect(ReglaConsumo.validarLitros(-1), isNotNull);

      // Aceptar cantidades mayores que cero y menores que 10000.
      expect(ReglaConsumo.validarLitros(1000), isNull);
      expect(ReglaConsumo.validarLitros(1001), isNull);
      expect(ReglaConsumo.validarLitros(9999), isNull);

      // El tope es exclusivo: rechazar 10000 y cantidades superiores.
      expect(ReglaConsumo.validarLitros(10000), isNotNull);
      expect(ReglaConsumo.validarLitros(10001), isNotNull);

    });

    test('Rechazar Kwh <= 0: la regla devuelve error', (){

      // Rechazar kwh menor o igual a 0
      expect(ReglaConsumo.validarKwh(-1), isNotNull);
      expect(ReglaConsumo.validarKwh(0), isNotNull);

    });

  });


  group('Historia: Registrar correo', (){

    test('Verificar que sea institional: la regla devuelve error', (){

      //Otro grupo para otra historia
      // De correo
      // Test para verificar que solo acepte correo institucional
      expect(ReglaCorreo.esInstitucional('alex@utez.edu.mx'), isTrue);

      // Rechazar un dominio diferente al institucional
      expect(ReglaCorreo.esInstitucional('alex@gmail.com'), isFalse);

      // Rechazar dominio sin usuario
      expect(ReglaCorreo.esInstitucional('@utez.edu.mx'), isFalse);


    });


  });
}
