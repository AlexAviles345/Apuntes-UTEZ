# 01 — EcoTrack Auth — Arquitectura y flujo de sesión

La pregunta que organiza este proyecto es «¿cómo sabe la app si debe mostrar el formulario o el área privada?». El repositorio emite el usuario actual. El ViewModel convierte ese dato en un estado de sesión y el router decide a qué pantalla corresponde.

## 1. Capas y responsabilidades

| Parte | Qué hace | Código |
|---|---|---|
| Dominio | Modela al usuario, define las reglas de acceso y los tipos de error. | [dominio/](ecotrack_auth/lib/dominio/) |
| Datos | Expone un contrato de autenticación que tiene implementaciones en memoria y con Firebase. | [datos/](ecotrack_auth/lib/datos/) |
| Presentación | Guarda el estado compartido, muestra los formularios y elige las pantallas según la sesión. | [presentacion/](ecotrack_auth/lib/presentacion/) |
| Arranque y composición | Selecciona el repositorio y conecta el ViewModel, Provider y el router. | [main.dart](ecotrack_auth/lib/main.dart), [app.dart](ecotrack_auth/lib/app.dart) |

La organización sigue MVVM con repositorio. Las vistas recogen datos y muestran el estado. `SesionViewModel` coordina las operaciones contra el contrato `AuthRepository`. El repositorio concreto se recibe por constructor y puede cambiar sin reescribir los formularios.

En [EcoTrack Estado](../../../Unidad%202/Apuntes/proyecto%20-%20ecotrack_estado/README.md), un ViewModel compartía los datos de consumo entre widgets. Aquí la misma idea se aplica a la sesión y la comparten dos consumidores distintos. Los widgets muestran el correo o los errores y GoRouter vuelve a evaluar las rutas.

## 2. Qué se crea al arrancar

1. `main()` inicializa Flutter, espera a `_crearRepositorio()` y pasa el resultado a `EcoTrackAuthApp`.
2. `app.dart` crea una sola instancia de `SesionViewModel` y otra de `GoRouter`. Al conservar el router entre reconstrucciones, también se conserva su pila de navegación.
3. `ChangeNotifierProvider.value` publica el ViewModel existente en el árbol de widgets. La raíz conserva la responsabilidad de liberar el router y el ViewModel en `dispose()`.
4. El ViewModel se suscribe a `cambiosDeSesion()`. La primera emisión indica si existe una sesión previa y las siguientes reflejan cambios como entrar o salir.

| Opción de arranque | Repositorio | Dónde viven las cuentas |
|---|---|---|
| Sin banderas | `MemoriaAuthRepository` | En memoria durante esa ejecución de la app. |
| `SESION_GUARDADA=true` | `MemoriaAuthRepository` | En memoria. Arranca con una sesión de ejemplo ya seleccionada. |
| `EMULADOR=true` | `FirebaseAuthRepository` | En el emulador de Authentication, en `demo-ecotrack`. |
| `FIREBASE=true` | `FirebaseAuthRepository` | En el proyecto remoto que indican las opciones generadas de Firebase. |

Si se proporcionan `EMULADOR` y `FIREBASE` juntos, el código selecciona el emulador primero. `SESION_GUARDADA` aplica solo a la rama en memoria.

## 3. Flujo de un inicio de sesión

```text
EntrarPage lee los campos
  → SesionViewModel valida y pide iniciar sesión al repositorio
  → El repositorio verifica las credenciales y emite Usuario
  → El ViewModel pasa a ConSesion y avisa con notifyListeners()
  → GoRouter revisa la ruta y lleva de /entrar a /inicio
```

Si hay un error de validación, el ViewModel muestra el mensaje sin hacer la solicitud. Si el repositorio rechaza la operación con `FallaAuth`, el ViewModel expone su mensaje. Durante la solicitud, `procesando` desactiva el botón y deja visible el texto de espera. Registrar una cuenta válida sigue un flujo similar y el repositorio abre la sesión de la cuenta recién creada.

La llamada a `iniciarSesion()` y el flujo `cambiosDeSesion()` cumplen tareas distintas. La primera solicita una operación. El flujo informa si la sesión cambió, incluso al abrir la app o después de salir. Con Firebase, `authStateChanges()` entrega el estado inicial disponible en el SDK. [Estados de autenticación en Firebase para Flutter](https://firebase.google.com/docs/auth/flutter/start).

## 4. Estados de sesión y reglas de navegación

| Estado | Qué sabe la app | Cómo decide `redirigir()` |
|---|---|---|
| `Verificando` | Todavía espera la primera emisión. | Lleva a `/cargando` y se queda ahí mientras espera. |
| `SinSesion` | El repositorio emitió `null`. | Permite `/entrar` y `/registro`. Las demás ubicaciones se redirigen a `/entrar`. |
| `ConSesion(usuario)` | El repositorio emitió un `Usuario`. | Deja entrar a `/inicio` y `/inicio/perfil`. Desde las rutas públicas o de carga redirige a `/inicio`. |

Cuando se abre **Perfil**, la app hace `context.push(Rutas.perfil)` y conserva Inicio en la pila. Al cerrar sesión, el repositorio emite `null` y el router lleva a `/entrar` incluso si la persona estaba en Perfil. Esta regla protege la navegación del cliente. El acceso a cualquier dato remoto que se añada a futuro también dependerá de la autorización del servicio que lo almacene.

[Volver al índice](README.md) · [Clases y métodos](02%20-%20EcoTrack%20Auth%20-%20Clases%2C%20objetos%20y%20m%C3%A9todos%20explicados.md)
