# Tema 2.1 - El Ecosistema del Desarrollador PWA

## Guía de la fuente

> Para construir y probar Progressive Web Apps de manera exitosa, es fundamental configurar un entorno de desarrollo con Node.js y un servidor HTTP local, superando el mito de que JavaScript puro prescinde de estas herramientas. El texto explica que las tecnologías avanzadas como los Service Workers requieren obligatoriamente un Contexto Seguro, el cual solo se garantiza mediante conexiones cifradas o direcciones locales como localhost, bloqueando su funcionamiento al abrir archivos directamente desde el disco. Asimismo, se detallan el uso de editores como VS Code junto a la terminal de Git para optimizar el flujo de trabajo, y se fomenta el pensamiento crítico frente a problemas comunes de conectividad móvil y compatibilidad defensiva mediante código. De este modo, la guía proporciona tanto la base teórica como las herramientas prácticas indispensables para que los desarrolladores inicien correctamente en el ecosistema PWA.

---

**Duración estimada:** 20 a 25 minutos (Teoría y Demostración Guiada)

**Objetivo de Aprendizaje:** Comprender la necesidad de un entorno de ejecución HTTP local, configurar el herramental técnico básico en JavaScript Vanilla y dominar el concepto de Contextos Seguros (Secure Contexts) para el funcionamiento de las Web APIs modernas.

## 1. Desarrollos Conceptuales y Guión de Exposición

### A. El Rol de Node.js y NPM en un Entorno Vanilla JS

- **Existe un mito común entre los estudiantes:** "Si programamos en JavaScript Vanilla sin React, Angular o Vue, no necesitamos Node.js ni la terminal". Esta suposición cae al construir la primera PWA.

#### ¿Por qué Node.js si no usamos frameworks?

- **Servidor HTTP Local:** Los Service Workers, la Cache API y las PWA en general **no funcionan bajo el protocolo file://** (abrir un HTML dándole doble clic desde el explorador de archivos). Se requiere un servidor web real operando sobre el protocolo HTTP/HTTPS.
- **Herramental de Línea de Comandos (CLI):** Usamos Node.js como plataforma para ejecutar servidores estáticos ligeros (http-server, serve), herramientas de empaquetado o análisis (lighthouse-cli), y más adelante, bases de datos como pouchdb-server.
- **Gestión de Dependencias (NPM):** Aunque la lógica cliente se escriba en JS nativo, librerías cliente (como PouchDB o Crypto-JS) se gestionan e instalan eficientemente mediante NPM o se sirven vía CDN controlado.

### B. Contextos Seguros (Secure Contexts) y el Protocolo HTTPS

Las PWAs manejan capacidades avanzadas de hardware y almacenamiento que, de caer en manos maliciosas mediante un ataque Man-in-the-Middle (MitM), comprometerían la seguridad del usuario. Por ello, los navegadores imponen la regla de Contextos Seguros.

```text
       [ Petición Insegura: HTTP ]
Cliente ----------------------------> Servidor
   |                                     |
   +-----> [ Ataque MitM (Intercepta) ] -+
           (Puede inyectar código malicioso en el Service Worker)

       [ Petición Segura: HTTPS / Localhost ]
Cliente <======== Encriptado ========> Servidor
   |
   +-----> [ Service Worker Habilitado ]
```

- **Definición de Contexto Seguro:** Entorno donde la comunicación está cifrada de extremo a extremo o proviene de un origen local estrictamente controlado.

#### Orígenes Considerados Seguros por el Navegador:

- [https://domain.com](https://domain.com) (Cualquier dominio con certificado TLS/SSL válido).
- http://localhost y [http://127.0.0.1](http://127.0.0.1) (Inyectados como excepciones explícitas para desarrollo).
- [http://[::1]](http://[::1]) (Dirección de bucle de retorno en IPv6).

#### APIs Bloqueadas fuera de un Contexto Seguro:

- Registro de Service Workers (navigator.serviceWorker).
- Almacenamiento y Persistencia Extendida (Cache API, cuotas de IndexedDB).
- Geolocalización, Cámara, Micrófono, Web Bluetooth y Web NFC.
- Notificaciones Push y Sincronización en Segundo Plano.

### C. Herramientas del Desarrollador (VS Code + Git CLI)

#### Visual Studio Code (VS Code):

Configuración de espacio de trabajo limpio sin autocompletados agresivos de frameworks.

##### Extensiones Obligatorias:

- **Live Server / Live Preview:** Servidor HTTP instantáneo para desarrollo rápido.
- **ESLint:** Validación en tiempo real de sintaxis ES6+ sin necesidad de compilar.
- **PWA Tools / Web App Manifest:** Autocompletado y validación de esquemas JSON para el manifiesto.

#### Git desde Línea de Comandos (CLI):

Control de versiones sin interfaces gráficas pesadas para garantizar trazabilidad.

**Archivo .gitignore esencial para proyectos PWA:**

```gitignore
node_modules/
.DS_Store
.env
dist/
```

## 2. Demostración Práctica en Vivo (Live Coding)

**Sigue estos pasos en la pantalla principal para que los estudiantes observen la falla y la solución en directo:**

### Paso 1: Demostrar la falla del protocolo file://

- Crea una carpeta prueba-pwa con un archivo index.html simple y un archivo app.js.
- **En app.js agrega la verificación de Service Worker:**

```javascript
if ('serviceWorker' in navigator) {
  console.log('Service Worker es soportado en este navegador');
} else {
  console.warn('Service Worker NO es soportado');
}
```

- Abre el archivo index.html dándole doble clic (la barra de direcciones mostrará file:///C:/.../index.html).
- Abre Chrome DevTools (F12) y muestra la consola. Aunque el navegador soporte Service Workers, al intentar registrar uno más adelante arrojará el error: Uncaught (in promise) TypeError: Failed to register a ServiceWorker: The URL protocol of the current origin ('file://') is not supported.

### Paso 2: Elevar el proyecto a un Contexto Seguro con HTTP

- Abre la terminal integrada de VS Code en la carpeta del proyecto.
- **Levanta el servidor local usando Node/NPM:**

```bash
npx http-server -p 8080
```

- Navega en Chrome a http://localhost:8080.
- **Muestra la consola de DevTools:** El origen ahora es seguro y la comprobación pasa limpiamente.

## 3. Preguntas de Razonamiento Socrático (Anti-IA)

**Usa estas preguntas durante la exposición para mantener el pensamiento crítico en el aula:**

> **Pregunta:** "Si estoy desarrollando una PWA y quiero probarla desde el navegador de mi teléfono celular conectado a la misma red Wi-Fi de mi casa ingresando a [http://192.168.1.15:8080](http://192.168.1.15:8080), ¿funcionará el Service Worker?"

**Respuesta Esperada:** No. La IP 192.168.1.15 no es localhost ni usa https://. El navegador del móvil la clasificará como un origen inseguro y bloqueará el Service Worker.

**Solución Técnica:** Usar herramientas de túnel seguro como ngrok (ngrok http 8080), la función Remote Debugging / Port Forwarding de Chrome DevTools mediante USB, o configurar banderas de desarrollo en el navegador móvil (chrome://flags/#unsafely-treat-insecure-origin-as-secure).

> **Pregunta:** "Si JavaScript Vanilla se ejecuta directamente en el motor V8 del navegador, ¿por qué necesitamos comprobar si una API existe mediante if ('serviceWorker' in navigator) antes de invocarla?"

**Respuesta Esperada:** Por compatibilidad defensiva (Progressive Enhancement). Si el usuario abre la web desde un navegador antiguo o restringido que no soporta la API, el script no romperá la ejecución completa con un error no controlado (Uncaught TypeError).

## 4. Hoja de Referencia (Cheat Sheet) para el Estudiante

**Proporciona o proyecta este resumen de comandos clave:**

| Comando / Operación | Utilidad en el Entorno PWA |
| --- | --- |
| `node -v` | Verifica que Node.js esté instalado y reconoce la terminal. |
| `npm install -g http-server` | Instala un servidor web estático global ligero. |
| `npx http-server -p 8080 -c-1` | Levanta un servidor en el puerto 8080 desactivando la caché (-c-1) para desarrollo. |
| `http://localhost:8080` | Contexto seguro predeterminado en entornos locales. |
| `chrome://flags` | Menú interno de Chrome para habilitar funciones experimentales o probar orígenes inseguros en móviles. |
