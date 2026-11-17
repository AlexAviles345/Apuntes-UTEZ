# EcoTrack Meta — `ChangeNotifier` y Provider desde cero

Esta carpeta contiene la práctica y su guía de estudio. El proyecto compara dos formas de compartir el mismo `ConsumosViewModel` entre Registro, Historial y Meta.

## Orden recomendado de lectura

1. [Práctica — EcoTrack Meta: `ChangeNotifier` y provider desde cero](01%20-%20EcoTrack%20Meta%20-%20Práctica%20ChangeNotifier%20y%20provider%20desde%20cero.md)
2. [Explicación de componentes, arquitectura y flujos](02%20-%20EcoTrack%20Meta%20-%20Explicación%20de%20componentes,%20arquitectura%20y%20flujos.md)
3. [Proyecto Flutter `ecotrack_meta`](ecotrack_meta/)

## Ejecución

Desde `ecotrack_meta/`:

```bash
flutter pub get
flutter run
```

`flutter run` inicia la variante con Provider. Para ejecutar el cableado manual:

```bash
flutter run -t lib/main_change_notifier.dart
```

## Comprobaciones

```bash
flutter analyze
flutter test
bash verificar_estado.sh
```

[Volver al índice de trabajos](../README.md)

