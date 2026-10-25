// U1-S03-A02 — La misma app con tres cableados de estado (referencia)
//
//   flutter run                           -> A · ChangeNotifier
//   flutter run -t lib/main_provider.dart -> B · provider
//   flutter run -t lib/main_riverpod.dart -> B · riverpod
//
// dominio/, datos/ y presentacion/vistas.dart son iguales en las tres.
// Lo único que cambia está en lib/variantes/.

import 'datos/consumo_repository.dart';
import 'variantes/a_change_notifier.dart';
import 'package:flutter/cupertino.dart';

void main(){
  runApp(AppChangeNotifier(repositorio: MemoriaConsumoRepository()));
}