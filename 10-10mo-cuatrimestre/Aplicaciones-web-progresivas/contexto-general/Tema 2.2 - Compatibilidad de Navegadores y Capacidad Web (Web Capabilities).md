# Tema 2.2 - Compatibilidad de Navegadores y Capacidad Web (Web Capabilities)

## Guía de la fuente

> El texto aborda la importancia de garantizar la compatibilidad multiplataforma en el desarrollo web mediante el uso de estrategias defensivas y modernas. Su propósito principal es enseñar a los desarrolladores a evitar prácticas obsoletas como la lectura del navegador, recomendando en su lugar la detección directa de características para comprobar la disponibilidad real de las funciones. Asimismo, explica el principio de mejora progresiva, el cual permite que cualquier sitio funcione con una base accesible mientras habilita herramientas avanzadas solo cuando el entorno lo permite. Finalmente, expone las diferencias de soporte entre los distintos motores web, como Chromium y WebKit, ofreciendo soluciones prácticas para superar restricciones de privacidad y asegurar una experiencia de usuario óptima en diversos dispositivos.

---

**Duración estimada:** 20 a 25 minutos (Teoría y Demostración Guiada)

**Objetivo de Aprendizaje:** Comprender la estrategia de Mejora Progresiva (Progressive Enhancement), implementar Detección de Características (Feature Detection) en lugar de rastreo de User-Agent, y dominar las herramientas de evaluación de capacidades del motor web para prevenir fallos en entornos multiplataforma.

## 1. Desarrollos Conceptuales y Guión de Exposición

### A. Detección de Características (Feature Detection) vs. User-Agent Sniffing

Un error histórico en el desarrollo web es intentar adivinar qué puede hacer un navegador leyendo la cadena navigator.userAgent. En el ecosistema PWA, esta práctica está totalmente desaconsejada.

#### ¿Por qué NO usar User-Agent Sniffing?

- **Cadenas falsificables e imprecisas:** Los navegadores modifican sus cadenas de User-Agent por compatibilidad histórica (ej. Chrome incluye las palabras "Safari", "Mozilla" y "AppleWebKit" en su cadena).
- **No garantiza la habilitación de la API:** El usuario o el administrador del sistema pueden haber desactivado una función específica (como la geolocalización o las notificaciones) mediante flags o políticas de privacidad, aunque el navegador en teoría la soporte.
- **La Regla de Oro:** Detección de Características (Feature Detection) Antes de ejecutar cualquier API moderna, se debe verificar mediante código la existencia del objeto, método o propiedad dentro de los objetos globales window o navigator.

```javascript
// ❌ MALO: User-Agent Sniffing (Inestable e impreciso)
if (navigator.userAgent.includes("iPhone")) {
  // Asumir que no soporta Web Bluetooth...
}

// ✅ BUENO: Feature Detection (Robusto y defensivo)
if ('bluetooth' in navigator) {
  // Ejecutar lógica de Web Bluetooth
} else {
  // Desplegar interfaz alternativa (Fallback)
}
```

### B. El Principio de Mejora Progresiva (Progressive Enhancement)

**Las PWA no deben diseñarse como aplicaciones de "todo o nada". Deben seguir el paradigma de Mejora Progresiva:**

- **Núcleo Funcional:** La aplicación debe cargar la estructura básica de datos e interfaz en cualquier navegador web, incluso en versiones antiguas.
- **Capa de Capacidades (PWA):** Si el navegador soporta Service Workers, Cache API o almacenamiento offline, se habilitan esas capacidades para enriquecer la experiencia del usuario.

### C. Panorama de Soporte Actual por Motor Web (Browser Engines)

| Motor Web | Navegadores | Estado del Soporte PWA / Web Capabilities |
| --- | --- | --- |
| Chromium | Chrome, Edge, Brave, Opera | Líder (Proyecto Fugu): Soporte total para Service Workers, Web App Manifest, Notificaciones Push, Web Bluetooth, Web NFC, File System Access API y Background Sync. |
| WebKit | Safari (iOS, iPadOS, macOS) | Soporte Parcial / Restringido: Soporta Service Workers, Web App Manifest (parcial) y Push Notifications (desde iOS 16.4+). Bloquea Web Bluetooth, Web NFC y la gestión avanzada de archivos por políticas de privacidad. Atención: Purga IndexedDB y datos locales si la app no se agrega al inicio y pasa 7 días sin uso. |
| Gecko | Firefox (Desktop y Android) | Soporte Estándar: Excelente soporte para Service Workers, Cache API e IndexedDB. En escritorio no permite la instalación de PWAs como aplicaciones independientes de ventana completa (Standalone), pero en Android sí. |

## 2. Demostración Práctica en Vivo (Live Coding y Auditoría Web)

### Paso 1: Auditoría de Capacidades en Tiempo Real

- Abre el navegador Chrome en la pantalla del aula e ingresa a whatwebcando.today.
- Proyecta las secciones de Offline / Storage, Device Features (Bluetooth, NFC, USB) y Notifications.
- Abre el mismo enlace desde un dispositivo iOS (iPhone/iPad) o simula Safari y compara cómo la columna de capacidades cambia drásticamente.

### Paso 2: Construcción de un Módulo de Diagnóstico en JS Vanilla

- Escribe en vivo el siguiente script de diagnóstico en app.js para mostrarle a los alumnos cómo validar las capacidades de su entorno local:

```javascript
// Módulo de Diagnóstico de Capacidades PWA
const capacidadesPWA = {
  serviceWorker: 'serviceWorker' in navigator,
  cacheAPI: 'caches' in window,
  indexedDB: 'indexedDB' in window,
  pushNotifications: 'PushManager' in window,
  webBluetooth: 'bluetooth' in navigator,
  storagePersist: navigator.storage && 'persist' in navigator.storage
};

console.table(capacidadesPWA);

// Ejemplo de tratamiento defensivo (Fallback)
if (capacidadesPWA.serviceWorker) {
  console.log('✅ Entorno listo para registrar Service Worker.');
} else {
  console.warn('⚠️ Service Worker no soportado. Modo web convencional activo.');
}
```

Al ejecutar console.table(capacidadesPWA) en DevTools, verán una matriz estructurada con valores booleanos (true/false) que representa el perfil técnico del navegador cliente.

## 3. Preguntas de Razonamiento Socrático (Anti-IA)

**Utiliza estas preguntas para incentivar el debate en clase y evaluar la comprensión real del tema:**

> **Pregunta:** "Un cliente nos pide una PWA para auditar maquinaria en planta usando sensores Web Bluetooth. Sabemos que el 40% de los supervisores usa iPhone con Safari. ¿Es técnicamente viable implementar esta PWA sin ajustar la arquitectura?"

**Respuesta Esperada:** No. Apple/WebKit bloquea deliberadamente la Web Bluetooth API en iOS por razones de seguridad y privacidad.

**Solución de Arquitectura:** Se debe cambiar de arquitectura a una aplicación Móvil Nativa/Multiplataforma para los usuarios de iOS, o reemplazar el sensor Bluetooth por una solución basada en lectura de códigos QR / etiquetas NFC (si la versión de iOS lo soporta) o peticiones vía red Wi-Fi local.

> **Pregunta:** "Si Safari en iOS elimina los datos de IndexedDB y el LocalStorage de una web después de 7 días de inactividad, ¿cómo afecta esto a nuestra estrategia offline y qué debemos instruir al usuario?"

**Respuesta Esperada:** Si el usuario accede a la PWA solo como pestaña del navegador, corre el riesgo de perder los datos guardados en local si no entra en una semana.

**Mitigación:** La regla de depuración de 7 días de Safari no aplica si la PWA ha sido agregada formalmente a la Pantalla de Inicio (Add to Home Screen - A2HS). Por lo tanto, es requisito obligatorio guiarlos a instalar la PWA en su dispositivo.

## 4. Hoja de Referencia (Cheat Sheet) para el Estudiante

**Proporciona o proyecta esta guía sintáctica para la detección de capacidades en JavaScript Vanilla:**

| Capacidad PWA / Web API | Código de Detección de Característica (Feature Detection) |
| --- | --- |
| Service Worker | `'serviceWorker' in navigator` |
| Cache Storage API | `'caches' in window` |
| IndexedDB | `'indexedDB' in window` |
| Notificaciones Push | `'Notification' in window && 'PushManager' in window` |
| Sincronización en Segundo Plano | `'SyncManager' in window` |
| Geolocalización | `'geolocation' in navigator` |
| Web Bluetooth | `'bluetooth' in navigator` |
| Almacenamiento Persistente | `navigator.storage && 'persist' in navigator.storage` |
