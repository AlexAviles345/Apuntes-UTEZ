# Apuntes — Desarrollo Móvil Integral, Unidad 2

Cada proyecto se organiza en una carpeta contenedora llamada `proyecto - nombre`. Las guías de estudio se guardan directamente dentro de ella y la aplicación conserva su nombre original en una subcarpeta. El `README.md` de cada contenedor sirve como índice.

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
└── proyecto - ecotrack_patrones/
    ├── README.md
    ├── 01 - Ecotrack_patrones - Arquitectura general y comparativa.md
    ├── ... guías 02 a 07 ...
    ├── 08 - Ecotrack_patrones - Pruebas y dependencias.md
    └── ecotrack_patrones/
```

| Proyecto | Contenido | Acceso |
|---|---|---|
| Dependencies | Registro de agua y energía; arquitectura por capas, repositorio e inyección por constructor; pruebas unitarias, de interfaz y de integración | [Índice](proyecto%20-%20dependencies/README.md) · [Código](proyecto%20-%20dependencies/dependencies/) · [Guías](proyecto%20-%20dependencies/) |
| Ecotrack_estado | Registro de agua con tres variantes: ChangeNotifier manual, Provider y Riverpod; comparación de estado compartido y pruebas | [Índice](proyecto%20-%20ecotrack_estado/README.md) · [Código](proyecto%20-%20ecotrack_estado/ecotrack_estado/) · [Guías](proyecto%20-%20ecotrack_estado/) |
| Ecotrack_patrones | Seis casos: Factory, inyección de dependencias, Adapter, Repository, Observer y Strategy; comparación y pruebas unitarias y de widgets | [Índice](proyecto%20-%20ecotrack_patrones/README.md) · [Código](proyecto%20-%20ecotrack_patrones/ecotrack_patrones/) · [Guías](proyecto%20-%20ecotrack_patrones/) |

Para estudiar las diferencias entre las variantes de estado, consulte la [comparativa general de Ecotrack_estado](proyecto%20-%20ecotrack_estado/01%20-%20Ecotrack_estado%20-%20Comparativa%20de%20gesti%C3%B3n%20de%20estado.md).

Para distinguir los seis casos de diseño, empiece por la [arquitectura general y comparativa de Ecotrack_patrones](proyecto%20-%20ecotrack_patrones/01%20-%20Ecotrack_patrones%20-%20Arquitectura%20general%20y%20comparativa.md).

## Agregar Otro Proyecto

Cree una carpeta llamada `proyecto - nombre-original` y mantenga esta distribución:

- `nombre-original/`: la aplicación completa, con `pubspec.yaml`, código, pruebas y configuración de plataformas.
- Las guías Markdown directamente en el contenedor, con nombres como `01 - Nombre_proyecto - Arquitectura general y comparativa.md`. Empiece por la visión general, continúe con las guías de cada variante o patrón y deje las pruebas al final. Sus imágenes pueden guardarse en una subcarpeta `imagenes/`.
- `README.md`: descripción breve y enlaces al código y a las guías.

Los comandos de Flutter se ejecutan desde la subcarpeta de la aplicación, donde se encuentra su `pubspec.yaml`.

Ecotrack_estado y Ecotrack_patrones ya siguen el orden numerado. Las dos guías existentes de Dependencies conservan sus nombres y pueden recorrerse desde su índice.
