# Aplicaciones Web Orientadas a Servicios, Móviles Nativas y Multiplataforma

## Guía de la fuente

> Este texto ofrece una visión comparativa de las tres metodologías principales para la creación de software moderno, destacando cómo cada una equilibra el rendimiento técnico frente a la facilidad de despliegue. Mientras que las aplicaciones web se centran en el acceso universal y la actualización inmediata a través de la red, las soluciones nativas priorizan el aprovechamiento total del hardware y una ejecución fluida en sistemas específicos. Por su parte, el enfoque multiplataforma busca un equilibrio estratégico mediante la reutilización de código, permitiendo que un solo desarrollo funcione en diversos ecosistemas móviles. En última instancia, el autor estructura estos modelos para ayudar a comprender las ventajas y limitaciones que los desarrolladores deben considerar según el presupuesto, la conectividad y la experiencia de usuario deseada.

---

## 1. Aplicaciones Web Orientadas a Servicios (SOA / Web RESTful)

Son aplicaciones estructuradas bajo el modelo cliente-servidor donde la lógica de la interfaz (frontend) se encuentra desacoplada de la lógica de negocio y de datos (backend), comunicándose mediante protocolos de red estandarizados.

- **Arquitectura:** El frontend (HTML/CSS/JS) realiza peticiones asíncronas (HTTP/HTTPS) a servicios web mediante representaciones de recursos (generalmente APIs RESTful o GraphQL en formato JSON).

### Ventajas:

- **Acceso universal:** Disponibles desde cualquier navegador web sin requerir instalación previo en el dispositivo.
- **Mantenimiento centralizado:** Las actualizaciones en el servidor están disponibles de forma inmediata para todos los usuarios.
- **Multiplataforma por naturaleza:** Un solo desarrollo funciona en escritorios, móviles y tabletas.

### Desventajas:

- **Dependencia estricta de conectividad:** Si falla la conexión a red, la aplicación deja de ser funcional en su totalidad.
- **Acceso limitado a hardware:** Menor integración con capacidades físicas del dispositivo en comparación con aplicaciones instaladas.
- **Rendimiento condicionado:** Sensible a la latencia de red y limitaciones de renderizado del motor del navegador.

## 2. Aplicaciones Móviles Nativas

Son aplicaciones desarrolladas de manera específica para el sistema operativo subyacente del dispositivo (Android o iOS), utilizando los lenguajes, entornos de desarrollo (IDE) y SDKs oficiales definidos por los fabricantes (Google y Apple).

### Tecnologías:

- **Android:** Kotlin / Java (Android Studio).
- **iOS:** Swift / Objective-C (Xcode).

### Ventajas:

- **Rendimiento máximo:** Compiladas directamente a código máquina, aprovechando la aceleración por hardware y la GPU.
- **Acceso total a APIs nativas:** Integración completa y sin intermediarios a componentes físicos (cámara, sensores, Bluetooth, NFC, biometría).
- **Distribución centralizada:** Presencia en tiendas oficiales (Google Play Store, Apple App Store) con monetización directa.

### Desventajas:

- **Alto costo de desarrollo:** Se requiere mantener dos equipos/código fuente independientes para cubrir Android e iOS.
- **Proceso de actualización lento:** Toda actualización requiere aprobación en la tienda correspondiente antes de llegar al usuario.

## 3. Aplicaciones Multiplataforma (Híbridas / Frameworks Cross-Platform)

Son soluciones desarrolladas con un único código fuente que mediante un motor de compilación o puente de traducción (bridge) genera ejecutable para múltiples sistemas operativos.

### Tecnologías principales:

- **Compiladas a Nativo:** Flutter (Dart), React Native (JavaScript/TypeScript).
- **Basadas en WebView:** Ionic / Capacitor (HTML, CSS, JS envueltos en un contenedor nativo).

### Ventajas:

- **Reutilización de código:** Entre 70% y 95% del código es compartido para iOS y Android.
- Reducción de costos y tiempo de salida al mercado (Time to Market).
- **Acceso a hardware:** Mediante plugins o módulos nativos puente.

### Desventajas:

- **Capa de abstracción extra:** Posible pérdida de rendimiento en procesamiento gráfico complejo o animaciones pesadas.
- **Dependencia de terceros:** Retraso en la disponibilidad de soporte para nuevas características del sistema operativo hasta que el framework se actualice.
