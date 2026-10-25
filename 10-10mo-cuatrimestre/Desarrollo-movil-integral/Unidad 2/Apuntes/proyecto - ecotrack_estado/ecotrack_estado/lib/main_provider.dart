//   flutter run -t lib/main_provider.dart

import 'package:ecotrack_estado/datos/consumo_repository.dart';
import 'package:ecotrack_estado/variantes/b_provider.dart';
import 'package:flutter/cupertino.dart';

void main(){
  runApp(AppProvider(repositorio: MemoriaConsumoRepository()));
}