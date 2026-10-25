# Tema 3.2 - Arquitectura y Naturaleza del Service Worker

## Guía de la fuente

> Un Service Worker opera como un hilo de ejecución secundario y aislado que corre en segundo plano de manera totalmente independiente del ciclo de vida de las pestañas del navegador. Su arquitectura le impide interactuar directamente con elementos visuales o herramientas síncronas como el DOM o el almacenamiento local, evitando así problemas de concurrencia y bloqueos en la interfaz. En su lugar, este script aprovecha un diseño orientado a eventos para funcionar como un proxy de red programable, interceptando y gestionando de forma asíncrona las solicitudes web mediante herramientas como la Cache API o IndexedDB.

---

**Duración estimada:** 25 minutos (Teoría y Diagramación)

**Objetivo de Aprendizaje:** Comprender la naturaleza asíncrona y aislada del Service Worker como un hilo de ejecución secundario (Background Thread), identificar sus restricciones de acceso al DOM y entender su rol estratégico como un proxy de red programable.

## 1. Desarrollos Conceptuales y Guión de Exposición

### A. ¿Qué es un Service Worker y dónde se ejecuta?

Un Service Worker es un tipo especial de Web Worker. Es un script en JavaScript que el navegador ejecuta en segundo plano, en un hilo de ejecución independiente (Worker Thread), separado por completo del hilo principal (Main Thread/UI Thread) donde corre la interfaz gráfica y el DOM.

- **Independencia del ciclo de vida de la pestaña:** A diferencia del código JavaScript convencional de una página web, el Service Worker no está ligado a una pestaña abierta. Puede estar activo ejecutando tareas en segundo plano incluso si el usuario cierra la pestaña o la ventana del navegador.
- **Modelo Orientado a Eventos:** El Service Worker entra en estado de suspensión (idle) cuando no hay tareas pendientes y despierta instantáneamente cuando se dispara un evento para el cual tiene un escuchador registrado (install, activate, fetch, push, sync).

### B. Aislamiento del Entorno: El Objeto self vs. window

El aislamiento de hilos impone restricciones arquitectónicas fundamentales que los estudiantes deben memorizar y comprender:

```text
+-------------------------------------------------------------------+
| HILO PRINCIPAL (Main Thread / UI)                                 |
| Global Scope: window                                              |
| Acceso a: document, DOM, localStorage, sessionStorage, UI Events  |
+-------------------------------------------------------------------+
                                  |
                                  | Peticiones HTTP / postMessage
                                  v
+-------------------------------------------------------------------+
| HILO SECUNDARIO (Service Worker Thread)                           |
| Global Scope: self (ServiceWorkerGlobalScope)                     |
| Acceso a: Cache API, IndexedDB, fetch, Promises, Web Crypto       |
| ❌ SIN ACCESO A: document, DOM, window, localStorage, alert()     |
+-------------------------------------------------------------------+
```

#### ¿Por qué NO tiene acceso al DOM (document)?

Para evitar problemas de concurrencia y condiciones de carrera (Race Conditions). Si dos hilos modificaran el DOM de forma simultánea, el motor de renderizado colapsaría.

#### ¿Por qué NO tiene acceso a localStorage?

localStorage es una API síncrona y bloqueante. Debido a que el Service Worker se rige bajo un paradigma 100% asíncrono no bloqueante, el uso de apis síncronas está estrictamente prohibido en su entorno global (self).

#### ¿Cómo persiste datos un Service Worker?

- **Utiliza exclusivamente APIs asíncronas:** Cache API (para recursos web y archivos) e IndexedDB (para datos estructurados/JSON).
- **Mecanismo de Comunicación:** Si el Service Worker necesita enviar información a la interfaz visual (o viceversa), se utiliza el canal de mensajería asíncrona postMessage().

### C. El Service Worker como Proxy de Red Programable (Programmable Network Proxy)

El Service Worker actúa como un Hombre en el Medio (Man-in-the-Middle) legítimo y controlado por el desarrollador.

```text
[ Aplicación Web / Fetch ]
            |
            v
+------------------------+
| SERVICE WORKER (Proxy) | <--- Intercepta la petición HTTP
+------------------------+
     /              \
    / (Si está en)   \ (Si va a)
   v                  v
[ Cache API ]     [ Servidor / Red ]
```

Toda petición saliente enviada desde la página web (imágenes, hojas de estilo, scripts, llamadas fetch) pasa primero por la aduana del Service Worker a través del evento fetch.

**El Service Worker puede tomar decisiones en tiempo real:**

Servir la respuesta directamente desde la Cache API sin tocar la red.

Redirigir la petición a un recurso sintético fabricado en código.

Permitir que la petición siga su curso normal hacia la red de internet.

Modificar las cabeceras o el cuerpo de la respuesta antes de entregársela al navegador.

## 2. Preguntas de Razonamiento Socrático (Anti-IA)

> **Pregunta:** "Si un desarrollador intenta ejecutar alert('PWA instalada con éxito') dentro del evento install en el archivo sw.js, ¿qué sucede en la aplicación?"

**Respuesta Esperada:** Se genera un error no controlado en el hilo del Service Worker: Uncaught ReferenceError: alert is not defined. La función alert() es un método bloqueante dependiente de la interfaz de usuario del objeto window, el cual no existe en el contexto ServiceWorkerGlobalScope.

> **Pregunta:** "Si un usuario abre 4 pestañas diferentes de la misma PWA en el navegador, ¿cuántas instancias del Service Worker están corriendo en la memoria RAM del dispositivo?"

**Respuesta Esperada:** Una sola instancia. El Service Worker se ejecuta como un singleton asignado a un alcance (scope). Esa única instancia en segundo plano administra, intercepta las peticiones y atiende los eventos de las 4 pestañas (clients) simultáneamente.

## 3. Hoja de Referencia (Cheat Sheet)

| Objeto / API | Contexto window (Main Thread) | Contexto self (Service Worker) |
| --- | --- | --- |
| document / Manipulación DOM | ✅ Disponible | ❌ Bloqueado (ReferenceError) |
| localStorage / sessionStorage | ✅ Disponible | ❌ Bloqueado (API Síncrona) |
| alert(), confirm(), prompt() | ✅ Disponible | ❌ Bloqueado (Bloquea el hilo) |
| fetch() / Promises / async-await | ✅ Disponible | ✅ Disponible |
| Cache API (caches) | ✅ Disponible | ✅ Disponible |
| IndexedDB | ✅ Disponible | ✅ Disponible |
| postMessage() | ✅ Disponible | ✅ Disponible (Canal de comunicación) |
