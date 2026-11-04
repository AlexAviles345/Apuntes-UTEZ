# Apuntes — Desarrollo Móvil Integral, Unidad 2

Cada proyecto se organiza en una carpeta contenedora llamada `proyecto - nombre`. Las guías de estudio se guardan directamente dentro de ella y la aplicación conserva su nombre original en una subcarpeta. Los proyectos con muchas guías utilizan un `README.md` como índice; cuando hay pocas guías, el documento principal puede conservar un nombre descriptivo.

```text
Apuntes/
├── README.md
├── proyecto - dependencies/
│   ├── README.md
│   ├── Dependencies - Arquitectura y flujo de EcoTrack.md
│   ├── Dependencies - Pruebas y dependencias de EcoTrack.md
│   └── dependencies/
├── proyecto - ecotrack_estado/
│   ├── README.md
│   ├── 01 - Ecotrack_estado - Comparativa de gestión de estado.md
│   ├── ... guías 02 a 05 ...
│   ├── 06 - Ecotrack_estado - Pruebas de las tres variantes.md
│   └── ecotrack_estado/
├── proyecto - ecotrack_patrones/
│   ├── README.md
│   ├── 01 - Ecotrack_patrones - Arquitectura general y comparativa.md
│   ├── ... guías 02 a 07 ...
│   ├── 08 - Ecotrack_patrones - Pruebas y dependencias.md
│   └── ecotrack_patrones/
└── proyecto - ecotrack_http/
    ├── EcoTrack HTTP - Arquitectura y funcionamiento.md
    ├── EcoTrack HTTP - Clases, objetos y métodos explicados.md
    └── ecotrack_http/
```

| Proyecto | Contenido | Acceso |
|---|---|---|
| Dependencies | Registro de agua y energía; arquitectura por capas, repositorio e inyección por constructor; pruebas unitarias, de interfaz y de integración | [Índice](proyecto%20-%20dependencies/README.md) · [Código](proyecto%20-%20dependencies/dependencies/) · [Guías](proyecto%20-%20dependencies/) |
| Ecotrack_estado | Registro de agua con tres variantes: ChangeNotifier manual, Provider y Riverpod; comparación de estado compartido y pruebas | [Índice](proyecto%20-%20ecotrack_estado/README.md) · [Código](proyecto%20-%20ecotrack_estado/ecotrack_estado/) · [Guías](proyecto%20-%20ecotrack_estado/) |
| Ecotrack_patrones | Seis casos: Factory, inyección de dependencias, Adapter, Repository, Observer y Strategy; comparación y pruebas unitarias y de widgets | [Índice](proyecto%20-%20ecotrack_patrones/README.md) · [Código](proyecto%20-%20ecotrack_patrones/ecotrack_patrones/) · [Guías](proyecto%20-%20ecotrack_patrones/) |
| Ecotrack_http | Consumo de JSONPlaceholder con Dio; organización cercana a MVVM, ChangeNotifier, estados de pantalla, validación de JSON, interceptores y manejo de errores | [Arquitectura](proyecto%20-%20ecotrack_http/EcoTrack%20HTTP%20-%20Arquitectura%20y%20funcionamiento.md) · [Clases y métodos](proyecto%20-%20ecotrack_http/EcoTrack%20HTTP%20-%20Clases%2C%20objetos%20y%20m%C3%A9todos%20explicados.md) · [Código](proyecto%20-%20ecotrack_http/ecotrack_http/) |

Para estudiar las diferencias entre las variantes de estado, consulte la [comparativa general de Ecotrack_estado](proyecto%20-%20ecotrack_estado/01%20-%20Ecotrack_estado%20-%20Comparativa%20de%20gesti%C3%B3n%20de%20estado.md).

Para distinguir los seis casos de diseño, empiece por la [arquitectura general y comparativa de Ecotrack_patrones](proyecto%20-%20ecotrack_patrones/01%20-%20Ecotrack_patrones%20-%20Arquitectura%20general%20y%20comparativa.md).

Para estudiar el consumo de servicios HTTP, el flujo de estados y el uso directo de `ChangeNotifier`, empiece por [EcoTrack HTTP — Arquitectura y funcionamiento](proyecto%20-%20ecotrack_http/EcoTrack%20HTTP%20-%20Arquitectura%20y%20funcionamiento.md).

## Agregar Otro Proyecto

Cree una carpeta llamada `proyecto - nombre-original` y mantenga esta distribución:

- `nombre-original/`: la aplicación completa, con `pubspec.yaml`, código, pruebas y configuración de plataformas.
- Las guías Markdown directamente en el contenedor, con nombres como `01 - Nombre_proyecto - Arquitectura general y comparativa.md`. Empiece por la visión general, continúe con las guías de cada variante o patrón y deje las pruebas al final. Sus imágenes pueden guardarse en una subcarpeta `imagenes/`.
- Un `README.md` como índice cuando existan muchas guías, o una guía principal con nombre descriptivo cuando el proyecto tenga pocos documentos. En ambos casos debe enlazar el código y las demás explicaciones.

Los comandos de Flutter se ejecutan desde la subcarpeta de la aplicación, donde se encuentra su `pubspec.yaml`.

Ecotrack_estado y Ecotrack_patrones siguen el orden numerado. Las dos guías de Dependencies conservan sus nombres y pueden recorrerse desde su índice. Ecotrack_http utiliza dos nombres descriptivos porque su documentación se divide únicamente entre la explicación arquitectónica y la explicación detallada de clases y métodos.
