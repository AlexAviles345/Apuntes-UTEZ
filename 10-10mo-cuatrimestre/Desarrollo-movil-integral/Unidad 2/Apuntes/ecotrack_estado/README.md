# ecotrack_estado

La misma aplicación de registro de consumo de agua con tres variantes de gestión de estado: ChangeNotifier, Provider y Riverpod.

## Guías de Estudio

- [ChangeNotifier y patrón Observer](../Ecotrack_estado%20-%20ChangeNotifier%20y%20Observer.md).
- [Provider e inyección de dependencias](../Ecotrack_estado%20-%20Provider%20e%20inyecci%C3%B3n%20de%20dependencias.md).
- [Riverpod y Notifier](../Ecotrack_estado%20-%20Riverpod%20y%20Notifier.md).
- [Pruebas de las tres variantes](../Ecotrack_estado%20-%20Pruebas%20de%20las%20tres%20variantes.md).

## Ejecutar la Aplicación y las Pruebas

Desde esta carpeta, resuelva las dependencias y elija la entrada de la variante que desea ejecutar. `flutter test` ejecuta los nueve casos de widgets de las tres variantes.

```bash
flutter pub get
flutter run
flutter run -t lib/main_provider.dart
flutter run -t lib/main_riverpod.dart
flutter test
```
