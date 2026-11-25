# 03 — EcoTrack Auth — Configuración y pruebas con Firebase

Las capturas muestran la creación del proyecto en la consola de Firebase, la activación del método de correo y contraseña y el registro de la aplicación Android desde Windows. Ejecuta los comandos de Flutter y FlutterFire dentro de `ecotrack_auth/`, donde está [pubspec.yaml](ecotrack_auth/pubspec.yaml). El proyecto declara Dart `^3.13.5`.

## 1. Crear el proyecto de Firebase

1. En la [consola de Firebase](https://console.firebase.google.com/), elige **Crear un proyecto** y escribe el nombre.
2. En la pantalla de asistencia con IA, deja Gemini desactivado como en la práctica y pulsa **Continuar**.
3. Deja Google Analytics desactivado y pulsa **Crear proyecto**. El acceso de la app depende de Firebase Authentication.

![Nombre del proyecto en el asistente de Firebase](imagenes/01-nombre-proyecto-firebase.webp)

![Opción de Gemini desactivada al crear el proyecto](imagenes/02-opcion-gemini.webp)

![Google Analytics desactivado antes de crear el proyecto](imagenes/03-opcion-google-analytics.webp)

## 2. Habilitar correo y contraseña

1. En la consola del proyecto, abre **Seguridad → Authentication** y entra en **Método de acceso**.
2. Elige **Correo electrónico/contraseña** en los proveedores nativos.
3. Activa el interruptor del proveedor y pulsa **Guardar**. En la práctica quedó desactivado el acceso sin contraseña mediante vínculo.
4. Comprueba que el proveedor aparezca como **Habilitada**. Es el que usan `createUserWithEmailAndPassword()` y `signInWithEmailAndPassword()`. [Autenticación con correo y contraseña en Flutter](https://firebase.google.com/docs/auth/flutter/password-auth).

![Authentication en el menú Seguridad de Firebase](imagenes/04-menu-firebase-authentication.webp)

![Selección del proveedor de correo y contraseña](imagenes/05-proveedor-correo-contrasena.webp)

![Interruptor de correo y contraseña activado, con acceso por vínculo desactivado](imagenes/06-habilitar-correo-contrasena.webp)

![Correo electrónico y contraseña aparece como proveedor habilitado](imagenes/07-proveedor-habilitado.webp)

En **Authentication → Configuración → Dominios autorizados** se revisó la lista. En la captura aparecen `localhost` y los dominios administrados por Firebase. Este ajuste corresponde a los flujos web que necesitan un dominio autorizado, como las redirecciones de OAuth. La plataforma que se registró para el modo Firebase real en esta práctica fue Android.

![Lista de dominios autorizados para la autenticación web](imagenes/08-dominios-autorizados.webp)

## 3. Instalar Firebase CLI y verificar la cuenta

Con Node.js y npm instalados, ejecuta desde la terminal:

```bash
npm install -g firebase-tools
firebase login
firebase projects:list
```

`firebase login` abre el navegador para autorizar la sesión de la CLI. La sesión de consola sirve para administrar el proyecto desde la terminal. Las cuentas que se crean dentro de EcoTrack pertenecen a Firebase Authentication.

Compara el `Project ID` que devuelve `firebase projects:list` con el que ves en la consola abierta en Chrome. Usa el ID exacto y verifica que la CLI esté conectada con la cuenta que tiene acceso al proyecto. [Referencia de Firebase CLI](https://firebase.google.com/docs/cli).

![Inicio de sesión de Firebase CLI confirmado](imagenes/09-firebase-cli-login.webp)

![Lista de proyectos disponibles desde la terminal](imagenes/10-proyectos-en-firebase-cli.webp)

## 4. Instalar FlutterFire CLI y habilitar sus comandos en Windows

```bash
dart pub global activate flutterfire_cli
```

Si la terminal avisa que el ejecutable instalado está fuera del `PATH`, abre **Editar las variables de entorno de tu cuenta** y agrega `%LOCALAPPDATA%\Pub\Cache\bin` al `Path` del usuario, o usa la ruta indicada por Dart si la caché es distinta. Después, abre una terminal nueva y comprueba `flutterfire --version`.

Para trabajos con plugins de Flutter en Windows, si Flutter pide soporte para enlaces simbólicos, puedes abrir la configuración para desarrolladores con este comando desde **CMD**:

```cmd
start ms-settings:developers
```

El comando abre la pantalla. El interruptor del modo de desarrollador se cambia en Configuración cuando el equipo lo permite. El comando forma parte de la preparación de Windows.

![FlutterFire CLI instalado y directorio de ejecutables de Dart agregado al PATH](imagenes/11-flutterfire-en-path-windows.webp)

## 5. Vincular la app de Android

Durante la preparación de la práctica se agregaron estas dependencias al proyecto. En esta copia ya están declaradas en `pubspec.yaml`, por lo que basta con ejecutar `flutter pub get`.

```bash
flutter pub add provider
flutter pub add go_router
flutter pub add firebase_core firebase_auth
```

Para conectar la app con tu propio proyecto de Firebase, desde la carpeta de la aplicación ejecuta lo siguiente y sustituye `TU_PROJECT_ID` por el ID que comprobaste:

```bash
flutterfire configure --project=TU_PROJECT_ID --platforms=android
```

FlutterFire selecciona el proyecto y registra o reutiliza la aplicación Android con el identificador `com.example.ecotrack_auth`. La salida de la práctica confirma el registro de Android y la generación de `lib/firebase_options.dart`. La configuración del proyecto apunta también al archivo `android/app/google-services.json`. [Guía oficial de configuración de FlutterFire](https://firebase.google.com/docs/flutter/setup).

![FlutterFire configura Android y confirma la generación de firebase_options.dart](imagenes/12-flutterfire-configurar-android.webp)

Con un emulador **Android** o un teléfono Android conectado, corre:

```bash
flutter devices
flutter run --dart-define=FIREBASE=true
```

Si Flutter muestra varios destinos, selecciona Android. `main.dart` inicializa Firebase con `DefaultFirebaseOptions.currentPlatform`. La copia actual tiene opciones generadas para Android. El modo real en Chrome requiere generar también las opciones de Web para ese proyecto. Las capturas muestran el alta del proyecto y de la app Android. Los pasos de acceso y registro se pueden comprobar con los escenarios de la sección 8.

## 6. Ejecutar el modo simulado

```bash
flutter run
flutter run --dart-define=SESION_GUARDADA=true
```

Ejecuta uno de los comandos a la vez. El primero permite entrar con `demo@utez.edu.mx` y `ecotrack2026`. El segundo arranca con ese usuario ya autenticado para estudiar cómo se resuelve la sesión inicial. Las cuentas registradas en este modo viven en memoria durante la ejecución. El botón **Simular sin red** permite provocar un error al enviar el formulario de acceso o registro.

## 7. Ejecutar el emulador local de Authentication

El emulador permite usar el SDK de Firebase contra un servidor local. El código apunta al proyecto local `demo-ecotrack` y al puerto `9099`. [Firebase Authentication Emulator](https://firebase.google.com/docs/emulator-suite/connect_auth).

El `firebase.json` guardado en el proyecto contiene la configuración de FlutterFire. Para probar el emulador, puedes crear una carpeta aparte con un `firebase.json` local que contenga lo siguiente:

```json
{
  "emulators": {
    "auth": { "port": 9099 }
  }
}
```

En una terminal situada en esa carpeta local, inicia el servicio y déjalo ejecutándose:

```bash
firebase emulators:start --only auth --project demo-ecotrack
```

En otra terminal, desde `ecotrack_auth/`, arranca Flutter:

```bash
flutter run -d chrome --dart-define=EMULADOR=true
```

La configuración de [firebase_emulador.dart](ecotrack_auth/lib/firebase_emulador.dart) elige `localhost` para Chrome y `10.0.2.2` para el emulador Android. `HOST_EMULADOR` permite sustituir esa dirección. El emulador tiene sus propias cuentas, así que registra una cuenta de prueba en ese modo para usarla ahí.

## 8. Comprobar el flujo de sesión

Estos escenarios permiten seguir lo explicado en la [guía de arquitectura](01%20-%20EcoTrack%20Auth%20-%20Arquitectura%20y%20flujo%20de%20sesi%C3%B3n.md).

| Acción | Qué revisar |
|---|---|
| Abrir la app sin sesión | Una vez resuelto el estado inicial, aparece **Entrar**. |
| Enviar un correo inválido o una contraseña de menos de ocho caracteres | El formulario muestra el mensaje de validación. |
| Registrar una cuenta con confirmación distinta | Aparece el mensaje de contraseñas que no coinciden. |
| Crear una cuenta válida y abrir Perfil | Tras el registro aparece Inicio. Perfil muestra el correo y el identificador del usuario. En el modo real, la cuenta debe figurar en **Authentication → Usuarios** del proyecto elegido. |
| Cerrar sesión desde Perfil | El router redirige a Entrar. |
| Activar **Simular sin red** y tratar de entrar en memoria | El formulario muestra el mensaje de falta de conexión. |
| Reiniciar la demo con `SESION_GUARDADA=true` | El flujo de sesión inicial lleva a Inicio. |

El [archivo de pruebas incluido](ecotrack_auth/test/widget_test.dart) conserva el ejercicio del contador de Flutter y hace referencia a `MyApp`, una clase del ejemplo inicial. Las comprobaciones de autenticación de esta guía son manuales. En el equipo usado para la revisión, `flutter pub get --offline` se detuvo porque el Dart instalado era `3.13.3` y el proyecto exige `^3.13.5`.

[Volver al índice](README.md)
