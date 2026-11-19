# Despliegue Automatizado con Jenkins — Proyecto PMNG (Unidad 3)

Esta carpeta documenta la práctica de **Integración y Despliegue Continuo (CI/CD) con Jenkins, GitHub y Docker Compose** sobre una instancia de **Amazon EC2**, automatizando la construcción y puesta en marcha del sistema de gestión de personas (`pmng`).

## Orden de Lectura

1. [01 — Explicación de Jenkinsfile, Proyecto PMNG y Flujo CI/CD](01%20-%20Explicaci%C3%B3n%20de%20Jenkinsfile%2C%20Proyecto%20PMNG%20y%20Flujo%20CI-CD.md): análisis detallado de los cambios en `pmng/` respecto a la Unidad 2, explicación línea por línea del `Jenkinsfile`, manejo seguro del archivo `.env` como *Secret file* en Jenkins y arquitectura de las 4 etapas del pipeline.
2. [02 — Guía de despliegue automatizado — PMNG con Jenkins, GitHub y Docker Compose](02%20-%20Gu%C3%ADa%20de%20despliegue%20automatizado%20-%20PMNG%20con%20Jenkins%2C%20GitHub%20y%20Docker%20Compose.md): procedimiento completo paso a paso con las 19 capturas en formato `.webp` de [`imagenes/`](imagenes/), preparación de `/tmp` a 2 GB, permisos del usuario `jenkins` en Docker, limpieza de contenedores previos (`pmng-cliente` y `pmng-servicios`) y ejecución del Pipeline.

## Prácticas Previas Relacionadas (Unidad 2)

Esta práctica reutiliza infraestructura construida en la Unidad 2:

- [03 — Instalar y configurar Jenkins](../../Unidad-2/Apuntes/1.%20ec2-docker-y-nginx-inicial/03%20-%20Instalar%20y%20configurar%20Jenkins.md): instalación de OpenJDK 21, servicio `jenkins` en el puerto `8080` y plugin *GitHub Integration*.
- [Guía de despliegue — Gestión de personas](../../Unidad-2/Trabajos/2.%20gestion-personas/Guia%20de%20despliegue%20-%20Gesti%C3%B3n%20de%20personas.md): creación de la red bridge `pmng-net`, del contenedor MySQL `pmng-persistance` (alias `pmng-mysql`) y de la base de datos `people-dev`.
- [Guía de despliegue — PMNG con Docker Compose](../../Unidad-2/Trabajos/3.%20pmng%20compose/Guia%20de%20despliegue%20-%20PMNG%20con%20Docker%20Compose.md): adaptación del proyecto `pmng` para orquestar `pmng-servicios` y `pmng-cliente` mediante `docker-compose.yml` y variables de entorno `.env`.

## Contenido de la Carpeta

| Ruta | Descripción |
|---|---|
| [`pmng/`](pmng/) | Proyecto completo con [`Jenkinsfile`](pmng/Jenkinsfile), [`docker-compose.yml`](pmng/docker-compose.yml), [`.gitignore`](pmng/.gitignore), [`.env`](pmng/.env), [`.env.example`](pmng/.env.example), [`client/`](pmng/client/) y [`service/`](pmng/service/) |
| [`imagenes/`](imagenes/) | 19 capturas del proceso en formato `.webp` |
