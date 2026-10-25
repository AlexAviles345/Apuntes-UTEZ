# Características y Arquitectura de las Aplicaciones Web Progresivas (PWA)

## Guía de la fuente

> Este texto ofrece un análisis integral sobre las Aplicaciones Web Progresivas (PWA), definiéndolas como una evolución tecnológica que fusiona la accesibilidad de la web con la funcionalidad avanzada de los programas nativos. El autor estructura la explicación en torno a tres pilares fundamentales: la capacidad de acceder al hardware, la confiabilidad en entornos sin conexión y la facilidad de instalación directa sin intermediarios. Se detalla además una arquitectura técnica basada en componentes clave como el Service Worker, que gestiona el tráfico de red, y el App Shell, que garantiza una carga visual inmediata. En última instancia, el documento posiciona a las PWA como una alternativa eficiente y de bajo costo de desarrollo, destacando su naturaleza segura bajo el protocolo HTTPS y su diseño adaptable a cualquier dispositivo.

---

## 1. Definición y Origen

Una Aplicación Web Progresiva (PWA) es una aplicación web construida con tecnologías estándar (HTML, CSS, JavaScript) que, mediante el uso de APIs web modernas, proporciona una experiencia de usuario equivalente a la de una aplicación nativa.

El término fue introducido por Alex Russell y Frances Berriman (Google) en 2015 para describir aplicaciones que aprovechan las capacidades de los navegadores modernos para evolucionar de páginas web tradicionales a aplicaciones instalables y funcionales offline.

## 2. Los Tres Pilares Fundamentales

- **Capaces (Capable):** Acceden a hardware nativo del dispositivo a través de APIs Web modernas (Cámara, Geolocalización, Notificaciones Push, Sincronización en segundo plano, Bluetooth).
- **Confiables (Reliable):** Carga instantánea e independiente del estado de la red. Pueden funcionar plenamente sin conexión a internet (Offline-First).
- **Instalables (Installable):** Se integran a la pantalla de inicio del sistema operativo sin necesidad de descarga desde una tienda de aplicaciones.

## 3. Características Clave (Principios de Diseño PWA)

- **Progresiva:** Funciona para cualquier usuario, independientemente del navegador elegido, aplicando la estrategia de mejora progresiva.
- **Responsiva:** Se adapta a cualquier factor de forma (móvil, tableta, escritorio).
- **Independiente de la red:** Capaz de trabajar offline o en redes inestables (2G/Lie-Fi) mediante Service Workers.
- **Aspecto de App Nativa (App-Like):** Navegación fluida, sin recargas de página completas ni barra de direcciones visible.
- **Segura:** Servida exclusivamente a través de HTTPS para prevenir interceptación de tráfico y manipulación de datos.
- **Descubrible e Instalable:** Identificable como "aplicación" gracias al archivo de manifiesto web (manifest.json) y motores de búsqueda.
- **Vinculable (Linkable):** Mantiene la naturaleza de la Web; se puede compartir mediante una simple dirección URL.

## 4. Arquitectura de una PWA

### A. App Shell Model (Modelo de Cascarón)

Separa la interfaz base (HTML, CSS, JS estáticos necesarios para renderizar la estructura gráfica) del contenido dinámico (datos obtenidos de la API REST). El App Shell se almacena localmente en la caché del dispositivo para cargarse de forma instantánea en visitas subsecuentes.

### B. Service Worker

Un script de JavaScript que el navegador ejecuta en segundo plano, separado de la página web principal. Funciona como un proxy de red programable en el lado del cliente, interceptando todas las peticiones HTTP salientes para decidir si se responden desde la red o desde la caché local.

### C. Web App Manifest (manifest.json)

- **Archivo de configuración en formato JSON que especifica los metadatos de la aplicación:** nombre, íconos, color de tema, orientación de pantalla, dirección URL de inicio y modo de visualización (standalone, fullscreen).

### D. Almacenamiento Local Avanzado

- **Cache Storage API:** Para recursos estáticos (HTML, CSS, JS, imágenes).
- **IndexedDB / PouchDB:** Para almacenamiento de datos estructurados complejos en el cliente.

## Tabla Comparativa de Paradigmas de Desarrollo

| Criterio | Web Tradicional / SOA | Nativa Móvil | Multiplataforma | Aplicación Web Progresiva (PWA) |
| --- | --- | --- | --- | --- |
| Lenguaje / Tech | HTML, CSS, JS | Kotlin / Swift | React Native, Flutter | HTML, CSS, JS (Vanilla / Frameworks) |
| Instalación | No requiere | Tiendas de Apps | Tiendas de Apps | Directa desde el navegador |
| Soporte Offline | Nulo | Completo | Completo | Completo (mediante Service Workers) |
| Acceso a Hardware | Limitado | Total | Alto (vía plugins) | Alto y en expansión (Web APIs) |
| Costo de Desarrollo | Bajo | Alto (2 códigos) | Medio (1 código) | Bajo (1 código base universal) |
| Actualizaciones | Inmediatas (Server) | Vía Tienda | Vía Tienda / OTA | Inmediatas (Servidor + SW) |
| Seguridad Requerida | Opcional (HTTP/HTTPS) | Firmado de APK/IPA | Firmado de APK/IPA | HTTPS Obligatorio |
