# ecotrack_reto

Punto de partida del reto "El Impostor": EcoTrack completo, pero mezclado en un solo archivo.

Instrucciones del reto: [`../RETO_IMPOSTOR_ALUMNOS.md`](../RETO_IMPOSTOR_ALUMNOS.md).

```bash
flutter pub get
flutter run -t lib/main_mezclado.dart   # la app de hoy, mezclada
bash verificar_capas.sh                 # ¿está bien separada?
flutter test -r expanded                # ¿funciona igual?
```
