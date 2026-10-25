# Tema 3.3 - El Ciclo de Vida del Service Worker

## Guía de la fuente

> El texto explica de manera detallada el ciclo de vida de un Service Worker, un componente fundamental para garantizar la consistencia offline en aplicaciones web mediante la gestión de estados y eventos. Describe cómo el navegador compara los archivos byte por byte para detectar actualizaciones y detalla las fases críticas de registro, instalación, espera, activación y control. Asimismo, profundiza en el uso estratégico de métodos como skipWaiting() y clients.claim() para forzar la actualización y tomar el control inmediato de las pestañas abiertas, evitando así conflictos con versiones anteriores.

---

**Duración estimada:** 25 minutos (Teoría y Demostración Práctica)

**Objetivo de Aprendizaje:** Rastrear y manipular las fases del ciclo de vida de un Service Worker (install, waiting, activate, fetch), comprender el algoritmo de actualización byte por byte y aplicar las directivas de control skipWaiting() y clients.claim().

## 1. Desarrollos Conceptuales y Guión de Exposición

### A. Diagrama de Estados del Ciclo de Vida

El ciclo de vida del Service Worker está diseñado para garantizar que nunca se rompa la consistencia de una aplicación offline mientras se actualizan versiones en segundo plano.

```text
[ Página Web ] ---> navigator.serviceWorker.register('./sw.js')
                           |
                           v
                     ( INSTALANDO )  <--- Evento 'install' (Precache App Shell)
                           |
            +--------------+--------------+
            | (Si falla)                  | (Si es exitoso)
            v                             v
       [ ABORTADO ]                ( EN ESPERA ) <--- State: 'waiting'
                                          |           (Espera a que se cierren las pestañas viejas)
                                          | O llamada a self.skipWaiting()
                                          v
                                    ( ACTIVADO )  <--- Evento 'activate' (Limpieza de cachés)
                                          |
                                          | O llamada a self.clients.claim()
                                          v
                                   ( CONTROLANDO ) <--- Escucha eventos 'fetch', 'push', 'sync'
```

### B. Desglose Fase por Fase

#### Fase de Registro (Registration):

El código en app.js solicita al navegador descargar y procesar el archivo sw.js. El navegador evalúa el archivo y verifica que provenga de un contexto seguro (HTTPS/localhost).

#### Fase de Instalación (Install):

Se dispara el evento 'install'. Ocurre una sola vez cuando el Service Worker es detectado por primera vez o cuando cambia su código respecto al anterior.

- **Uso Principal:** Descargar y guardar en la Cache API los recursos estáticos críticos de la aplicación (App Shell).
- **Si la promesa dentro de event.waitUntil() falla o se rechaza (ejemplo:** un archivo del precache devolvió error 404), la instalación se aborta por completo y el Service Worker se descarta.

#### Fase de Espera (Waiting / Staging):

Si ya existe un Service Worker v1 activo y se instala exitosamente un nuevo Service Worker v2, la v2 no toma el control inmediatamente. Entra en estado "En Espera" (waiting) para evitar que la nueva versión rompa la ejecución de las pestañas que actualmente están corriendo con la v1.

#### Fase de Activación (Activate):

Se dispara cuando la versión anterior del Service Worker es descartada (todas las pestañas asociadas fueron cerradas) o mediante forzado explícito.

- **Uso Principal:** Tareas de mantenimiento, migración de bases de datos en IndexedDB y eliminación de cachés obsoletas de versiones anteriores.

#### Fase de Control / Ejecución (Idle / Active):

El Service Worker está listo para interceptar el tráfico mediante 'fetch', recibir mensajes o procesar notificaciones.

### C. Las Banderas de Control Directo: skipWaiting() y clients.claim()

Por defecto, un Service Worker recién instalado espera a que el usuario cierre todas las pestañas abiertas para activarse. Para tomar el control de forma inmediata, se utilizan dos métodos:

- **self.skipWaiting():** Se ejecuta dentro del Service Worker (generalmente en la fase install). Le indica al navegador que no ponga al nuevo Service Worker en la cola de espera, obligándolo a saltar directamente al estado de activación.
- **self.clients.claim():** Se ejecuta dentro del evento activate. Le permite al nuevo Service Worker tomar el control de todas las pestañas abiertas de inmediato sin necesidad de que el usuario recargue manualmente la página.

### D. Algoritmo de Actualización de un Service Worker

**El navegador busca actualizaciones del archivo sw.js en los siguientes escenarios:**

Cuando el usuario navega o recarga una página dentro del alcance (scope).

Cuando se ejecuta explícitamente navigator.serviceWorker.register().

Automáticamente si han pasado más de 24 horas desde la última revisión de red.

- **Regla Crítica de Actualización:** El navegador compara el archivo sw.js entrante contra el existente byte por byte. Con que cambie un solo carácter (por ejemplo, cambiar const CACHE = 'v1' a const CACHE = 'v2'), el navegador considerará que existe una nueva versión e iniciará el ciclo de instalación.

## 2. Implementación de Código del Ciclo de Vida (sw.js)

**Proyecta y analiza con los alumnos el flujo impreso en consola durante la ejecución:**

```javascript
// Nombre de la versión actual de la caché
const CACHE_NAME = 'app-v2';

// 1. EVENTO INSTALL
self.addEventListener('install', (event) => {
  console.log('[SW Log] Estado: Instalando Service Worker v2...');

  // Forzar a la nueva versión a tomar el control sin esperar
  self.skipWaiting();

  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      console.log('[SW Log] Precachando archivos del App Shell...');
      return cache.addAll([
        './',
        './index.html',
        './styles.css',
        './app.js'
      ]);
    })
  );
});

// 2. EVENTO ACTIVATE
self.addEventListener('activate', (event) => {
  console.log('[SW Log] Estado: Activando nueva versión...');

  // Reclamar el control inmediato de todos los clientes/pestañas
  event.waitUntil(self.clients.claim());

  // Purgar cachés antiguas
  event.waitUntil(
    caches.keys().then((keys) => {
      return Promise.all(
        keys.map((key) => {
          if (key !== CACHE_NAME) {
            console.log('[SW Log] Borrando caché obsoleta:', key);
            return caches.delete(key);
          }
        })
      );
    })
  );
});

// 3. EVENTO FETCH
self.addEventListener('fetch', (event) => {
  console.log('[SW Log] Interceptando petición a:', event.request.url);
  event.respondWith(
    caches.match(event.request).then((response) => {
      return response || fetch(event.request);
    })
  );
});
```

**Notas**

## 3. Preguntas de Razonamiento Socrático (Anti-IA)

> **Pregunta:** "Si un usuario entra a nuestra PWA por primera vez en su vida, se registra e instala el Service Worker con éxito sin usar clients.claim(). Si en ese preciso instante pierde la conexión a internet y da un clic en un enlace interno de la página, ¿la PWA funcionará offline?"

**Respuesta Esperada:** No. Aunque el Service Worker se instaló, en la primera visita a la página la PWA no está bajo el control del Service Worker a menos que se invoque clients.claim(). Sin ese método, las peticiones de esa primera sesión no son interceptadas y la navegación fallará por falta de red.

> **Pregunta:** "Un desarrollador modifica el código dentro de app.js pero olvida modificar el archivo sw.js. Al recargar la página en el navegador, ¿se activará el evento install del Service Worker?"

**Respuesta Esperada:** No. El navegador verifica el archivo sw.js byte por byte. Dado que sw.js no sufrió ningún cambio, el navegador asume que la infraestructura offline no ha cambiado y omite las fases de instalación y activación.

## 4. Hoja de Referencia (Cheat Sheet)

| Estado / Evento | Método Clave | Acción Principal Recomendada |
| --- | --- | --- |
| install | `event.waitUntil()` | Descargar y guardar en caché el App Shell inicial. |
| Salto de Espera | `self.skipWaiting()` | Obligar al nuevo SW a pasar de Waiting a Active. |
| activate | `caches.delete()` | Iterar y eliminar cachés de versiones obsoletas. |
| Toma de Control | `self.clients.claim()` | Controlar las pestañas abiertas desde la primera carga. |
| fetch | `event.respondWith()` | Interceptar el tráfico de red y servir estrategias de caché. |
