# 02 — EcoTrack Auth — Clases, objetos y métodos explicados

Esta guía acompaña la lectura del código. Si aún no ubicas quién recibe una acción y quién muestra el resultado, empieza por el [flujo de sesión](01%20-%20EcoTrack%20Auth%20-%20Arquitectura%20y%20flujo%20de%20sesi%C3%B3n.md).

## Dominio: usuario, validación y fallas

- `Usuario` guarda `uid`, el identificador que asigna el proveedor de identidad, y `correo`, el dato que aparece en Inicio y Perfil. [usuario.dart](ecotrack_auth/lib/dominio/usuario.dart).
- `validarCorreo()` revisa que haya texto y que tenga forma de correo. `validarContrasena()` exige al menos ocho caracteres. `validarConfirmacion()` compara ambos campos del registro. Cada función devuelve un mensaje o `null` cuando la entrada pasa la validación. Estas comprobaciones de formulario ocurren antes de consultar al repositorio. [reglas_acceso.dart](ecotrack_auth/lib/dominio/reglas_acceso.dart).
- `FallaAuth` representa una excepción con un mensaje para la interfaz. `CredencialesInvalidas` muestra el mismo mensaje si la cuenta no existe o si la contraseña es incorrecta. También existen fallas para correo en uso, contraseña débil, correo inválido, demasiados intentos, falta de conexión y errores desconocidos. [falla_auth.dart](ecotrack_auth/lib/dominio/falla_auth.dart).

## Datos: qué hace cada repositorio

`AuthRepository` declara cuatro operaciones. `Future` sirve para un resultado que llegará después de una operación. `Stream` sirve para recibir sucesivos valores. [auth_repository.dart](ecotrack_auth/lib/datos/auth_repository.dart).

| Método | En memoria | Con Firebase |
|---|---|---|
| `cambiosDeSesion()` | Emite `_actual` al suscribirse y después reenvía los cambios de un `StreamController`. | Escucha `authStateChanges()` y convierte cada `User?` en `Usuario?`. |
| `registrar()` | Crea una cuenta en el mapa interno y abre su sesión. | Usa `createUserWithEmailAndPassword()`. |
| `iniciarSesion()` | Compara los datos introducidos con el mapa y abre la sesión si coinciden. | Usa `signInWithEmailAndPassword()`. |
| `cerrarSesion()` | Limpia `_actual` y emite `null`. | Llama a `signOut()`. |

`_esperarRed()` usa el retardo de la demo y lanza `SinConexion` si se activó **Simular sin red**. Esto permite observar la espera y el error en el formulario de registro o de acceso. `_abrirSesion()` guarda y emite el usuario. [memoria_auth_repository.dart](ecotrack_auth/lib/datos/memoria_auth_repository.dart).

`_aUsuario()` conserva solo el identificador y correo de Firebase. `_intentar()` ejecuta el acceso o registro y entrega a `traducirErrorAuth()` cualquier `FirebaseAuthException`. Por ejemplo, `invalid-credential` se convierte en `CredencialesInvalidas` y `network-request-failed` en `SinConexion`. [firebase_auth_repository.dart](ecotrack_auth/lib/datos/firebase_auth_repository.dart).

## Presentación: quién cambia y escucha la sesión

| Elemento del ViewModel | Función |
|---|---|
| `estado` | Empieza en `Verificando` y cambia a `SinSesion` o `ConSesion` cuando llega un evento del repositorio. |
| `usuario` | Es un getter que devuelve el usuario si hay sesión o `null` en los demás estados. |
| `procesando` | Indica que está en curso un inicio de sesión o registro y bloquea el envío repetido. |
| `error` | Guarda el mensaje de validación o de autenticación que se muestra en pantalla. |
| `_ejecutar()` | Aplica la validación, habilita la espera, llama al repositorio y publica el resultado. `finally` desactiva la espera al terminar. |
| `limpiarError()` | Borra el mensaje al cambiar entre Entrar y Registro. |
| `dispose()` | Cancela la escucha del repositorio al liberar el ViewModel. |

El constructor de `SesionViewModel` conecta la suscripción a `_alCambiarSesion()`. Ese método toma la última emisión, actualiza `estado` y llama a `notifyListeners()`. `ChangeNotifier` avisa del cambio. Provider hace que ese mismo objeto esté disponible en las pantallas. [sesion_view_model.dart](ecotrack_auth/lib/presentacion/sesion_view_model.dart).

- `context.watch<SesionViewModel>()` se usa al construir un widget que necesita redibujarse si cambian el usuario, el error o el indicador de espera.
- `context.read<SesionViewModel>()` obtiene el objeto al pulsar un botón para ejecutar una acción.
- `refreshListenable: sesion` suscribe el router a las notificaciones. `crearRouter()` registra las páginas y `redirigir()` devuelve la ruta de destino o `null` para seguir en la actual. [rutas.dart](ecotrack_auth/lib/presentacion/rutas.dart).

## Las cinco pantallas

| Pantalla | Qué conviene observar |
|---|---|
| [CargandoPage](ecotrack_auth/lib/presentacion/paginas/cargando_page.dart) | Presenta un indicador mientras se identifica la sesión inicial. |
| [EntrarPage](ecotrack_auth/lib/presentacion/paginas/entrar_page.dart) | Usa dos `TextEditingController`, permite alternar la visibilidad de la contraseña y entrega los valores al ViewModel. |
| [RegistroPage](ecotrack_auth/lib/presentacion/paginas/registro_page.dart) | Añade un controlador para confirmar la contraseña. Ambos formularios liberan sus controladores en `dispose()`. |
| [InicioPage](ecotrack_auth/lib/presentacion/paginas/inicio_page.dart) | Muestra el saludo con el correo y permite abrir Perfil o cerrar sesión. |
| [PerfilPage](ecotrack_auth/lib/presentacion/paginas/perfil_page.dart) | Muestra correo y UID. El botón de salida usa el mismo ViewModel que Inicio. |

Para repasar, sigue una operación de salida desde Perfil. El botón llama a `cerrarSesion()`, el repositorio anuncia `null`, el ViewModel pasa a `SinSesion` y el router elige `/entrar`.

[Volver al índice](README.md) · [Configuración y pruebas](03%20-%20EcoTrack%20Auth%20-%20Configuraci%C3%B3n%20y%20pruebas%20con%20Firebase.md)
