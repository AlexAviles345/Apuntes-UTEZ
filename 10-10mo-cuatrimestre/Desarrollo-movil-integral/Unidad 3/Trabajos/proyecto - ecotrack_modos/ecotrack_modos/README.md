# ecotrack_modos

Demo de **modos de compilación** (debug / profile / release), configuración por ambiente y logs seguros.

```bash
flutter pub get
flutter run                                          # debug + AMBIENTE=dev
flutter run --dart-define=AMBIENTE=qa
flutter run --profile
flutter run --release --dart-define=AMBIENTE=prod
```

En Android release firmado con la clave de debug (solo para demo local):

```bash
flutter build apk --release --dart-define=AMBIENTE=prod
```
