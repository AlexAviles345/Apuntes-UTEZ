# EcoTrack Auth — Apuntes de Desarrollo Móvil Integral

EcoTrack Auth es una aplicación Flutter de registro e inicio de sesión con correo y contraseña. Sirve para estudiar cómo el mismo formulario trabaja con una cuenta simulada, el emulador local de Firebase o un proyecto real y cómo la sesión determina qué pantallas aparecen.

## Orden de lectura

1. [Arquitectura y flujo de sesión](01%20-%20EcoTrack%20Auth%20-%20Arquitectura%20y%20flujo%20de%20sesi%C3%B3n.md). Recorrido desde el formulario hasta el repositorio y las rutas protegidas.
2. [Clases, objetos y métodos explicados](02%20-%20EcoTrack%20Auth%20-%20Clases%2C%20objetos%20y%20m%C3%A9todos%20explicados.md). Referencia del código con ejemplos para repasar `Stream`, `ChangeNotifier`, Provider y GoRouter.
3. [Configuración y pruebas con Firebase](03%20-%20EcoTrack%20Auth%20-%20Configuraci%C3%B3n%20y%20pruebas%20con%20Firebase.md). Procedimiento ilustrado para habilitar correo y contraseña, configurar FlutterFire en Windows y ejecutar cada modo.

## Código y apuntes relacionados

- [Proyecto Flutter `ecotrack_auth/`](ecotrack_auth/) y [capturas WebP](imagenes/).
- [EcoTrack Estado](../../../Unidad%202/Apuntes/proyecto%20-%20ecotrack_estado/README.md). Antecedente del uso de Provider y `ChangeNotifier`.
- [EcoTrack Patrones](../../../Unidad%202/Apuntes/proyecto%20-%20ecotrack_patrones/README.md). Antecedente del contrato Repository y la inyección de dependencias.
- [EcoTrack HTTP](../../../Unidad%202/Apuntes/proyecto%20-%20ecotrack_http/EcoTrack%20HTTP%20-%20Arquitectura%20y%20funcionamiento.md). Antecedente del ViewModel y la traducción de errores técnicos a mensajes de la aplicación.

## Empezar con el modo simulado

Desde esta carpeta, entra al proyecto con un Flutter cuyo Dart cumpla `^3.13.5`:

```bash
cd ecotrack_auth
flutter pub get
flutter run
```

El modo predeterminado usa la cuenta ficticia `demo@utez.edu.mx` con contraseña `ecotrack2026`. Para ejecutar el emulador o acceder a un proyecto Firebase real, sigue la [guía de configuración](03%20-%20EcoTrack%20Auth%20-%20Configuraci%C3%B3n%20y%20pruebas%20con%20Firebase.md).
