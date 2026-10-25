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
└── proyecto - ecotrack_estado/
    ├── README.md
    ├── Ecotrack_estado - Comparativa de gestión de estado.md
    ├── ... otras guías de Ecotrack_estado ...
    └── ecotrack_estado/
```

| Proyecto | Contenido | Acceso |
|---|---|---|
| Dependencies | Registro de agua y energía; arquitectura por capas, repositorio e inyección por constructor; pruebas unitarias, de interfaz y de integración | [Índice](proyecto%20-%20dependencies/README.md) · [Código](proyecto%20-%20dependencies/dependencies/) · [Guías](proyecto%20-%20dependencies/) |
| Ecotrack_estado | Registro de agua con tres variantes: ChangeNotifier manual, Provider y Riverpod; comparación de estado compartido y pruebas | [Índice](proyecto%20-%20ecotrack_estado/README.md) · [Código](proyecto%20-%20ecotrack_estado/ecotrack_estado/) · [Guías](proyecto%20-%20ecotrack_estado/) |

Para estudiar las diferencias entre las variantes de estado, consulte la [comparativa general de Ecotrack_estado](proyecto%20-%20ecotrack_estado/Ecotrack_estado%20-%20Comparativa%20de%20gesti%C3%B3n%20de%20estado.md).

## Agregar Otro Proyecto

Cree una carpeta llamada `proyecto - nombre-original` y mantenga esta distribución:

- `nombre-original/`: la aplicación completa, con `pubspec.yaml`, código, pruebas y configuración de plataformas.
- Las guías Markdown directamente en el contenedor, con el nombre del proyecto como prefijo y sin numeración. Sus imágenes pueden guardarse en una subcarpeta `imagenes/`.
- `README.md`: descripción breve y enlaces al código y a las guías.

Los comandos de Flutter se ejecutan desde la subcarpeta de la aplicación, donde se encuentra su `pubspec.yaml`.
