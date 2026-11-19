# 01 — Explicación de `Jenkinsfile`, Proyecto `pmng` y Flujo CI/CD

Este documento explica cómo evolucionó el proyecto [`pmng/`](pmng/) respecto a las prácticas de la Unidad 2, qué cambios se realizaron en sus archivos para integrarlo con **GitHub** y **Jenkins**, cómo funciona cada bloque del [`Jenkinsfile`](pmng/Jenkinsfile) y por qué es necesario limpiar los contenedores manuales previos antes de ejecutar el pipeline.

Para seguir el procedimiento práctico paso a paso con los comandos y capturas en EC2, GitHub y Jenkins, consulta [02 — Guía de despliegue automatizado — PMNG con Jenkins, GitHub y Docker Compose](02%20-%20Gu%C3%ADa%20de%20despliegue%20automatizado%20-%20PMNG%20con%20Jenkins%2C%20GitHub%20y%20Docker%20Compose.md).

---

## Tabla de Contenidos

1. [Evolución de la Práctica (De Unidad 2 a Unidad 3)](#1-evolución-de-la-práctica-de-unidad-2-a-unidad-3)
2. [Comparativa del Proyecto pmng con la Práctica Anterior](#2-comparativa-del-proyecto-pmng-con-la-práctica-anterior)
3. [El Manejo Seguro de .env entre Git y Jenkins](#3-el-manejo-seguro-de-env-entre-git-y-jenkins)
4. [Explicación Detallada del Jenkinsfile](#4-explicación-detallada-del-jenkinsfile)
5. [Relación entre Jenkins, Docker Compose y la Red pmng-net](#5-relación-entre-jenkins-docker-compose-y-la-red-pmng-net)
6. [Por Qué Deben Eliminarse pmng-cliente y pmng-servicios Previos](#6-por-qué-deben-eliminarse-pmng-cliente-y-pmng-servicios-previos)

---

## 1. Evolución de la Práctica (De Unidad 2 a Unidad 3)

El sistema de gestión de personas (`pmng`) ha pasado por tres etapas a lo largo del curso:

| Etapa | Práctica | Cómo se enviaba el código a EC2 | Cómo se construían y levantaban los contenedores |
|---|---|---|---|
| **1** | [Unidad 2 — Trabajo 2: Gestión de personas](../../Unidad-2/Trabajos/2.%20gestion-personas/Guia%20de%20despliegue%20-%20Gesti%C3%B3n%20de%20personas.md) | Comprimiendo `pmng.zip` y enviándolo manualmente con `scp` desde CloudShell | Con comandos individuales `docker build` y `docker run` para MySQL, backend y cliente |
| **2** | [Unidad 2 — Trabajo 3: PMNG con Docker Compose](../../Unidad-2/Trabajos/3.%20pmng%20compose/Guia%20de%20despliegue%20-%20PMNG%20con%20Docker%20Compose.md) | Comprimiendo `pmng-3.zip` y enviándolo manualmente con `scp` desde CloudShell | Reutilizando `pmng-persistance` y `pmng-net`, y levantando backend y cliente juntos con `docker compose up -d` |
| **3 (Actual)** | **Unidad 3 — Apunte 1: Despliegue con Jenkins** | Subiendo el código con `git push` a un repositorio privado en GitHub (`ajca-pmng`) | **Jenkins** clona el repositorio automáticamente, inyecta el archivo `.env` desde su bóveda de credenciales y ejecuta las 4 etapas de `docker compose` definidas en el `Jenkinsfile` |

```text
[Equipo local]
   │  git push origin main / test
   ▼
[Repositorio privado en GitHub: AlexAviles345/ajca-pmng]
   │  Checkout SCM (usando credencial GITHUB_TOKEN)
   ▼
[Jenkins en EC2 (:8080)]
   ├── Inyecta credencial Secret file 'pmng-env' (.env)
   ├── Stage 1: Parar servicios     (docker compose ... down || true)
   ├── Stage 2: Eliminar imagenes   (docker rmi backend:v1.0 frontend:v1.0 || true)
   ├── Stage 3: Construir imágenes  (docker compose ... build --no-cache)
   └── Stage 4: Levantar servicios  (docker compose ... up -d --force-recreate)
                                           │
                                           ├──► pmng-servicios (:8089 -> :8080)
                                           ├──► pmng-cliente   (:5173 -> :80)
                                           └──► Conectados a pmng-net junto con pmng-persistance (:3306)
```

---

## 2. Comparativa del Proyecto `pmng` con la Práctica Anterior

Al comparar [`Unidad-3/Apuntes/1. Despliegue con Jenkins/pmng/`](pmng/) contra [`Unidad-2/Trabajos/3. pmng compose/pmng/`](../../Unidad-2/Trabajos/3.%20pmng%20compose/pmng/), esta es la estructura y las diferencias exactas:

```text
pmng/
├── .env                    # Variables locales (ignorado por Git gracias a .gitignore)
├── .env.example            # Plantilla de ejemplo de las variables de entorno
├── .gitignore              # NUEVO: excluye .env y .DS_Store del repositorio Git
├── Jenkinsfile             # NUEVO: define el pipeline declarativo de 4 etapas para Jenkins
├── docker-compose.yml      # Orquesta pmng-back y pmng-front sobre la red externa pmng-net
├── client/
│   ├── Dockerfile          # Imagen nginx:alpine que publica el cliente en el puerto 80
│   ├── index.html          # Formulario y tabla HTML de personas
│   └── main.js             # Peticiones fetch GET y POST hacia el puerto 8089
└── service/
    ├── Dockerfile          # Multi-stage build (Maven + JDK 21 -> JRE 21 Alpine)
    ├── pom.xml             # Dependencias Spring Boot, Spring Data JPA, MySQL Connector y Lombok
    └── src/main/...        # API REST en /people y configuración con variables DC_*
```

### Tabla de cambios respecto a `3. pmng compose`

| Archivo | Estado respecto a `3. pmng compose` | Detalle técnico |
|---|---|---|
| [`pmng/Jenkinsfile`](pmng/Jenkinsfile) | **Nuevo** | Automatiza la detención, limpieza de imágenes, reconstrucción sin caché y recreación de contenedores con Docker Compose |
| [`pmng/.gitignore`](pmng/.gitignore) | **Nuevo** | Impide que el archivo `.env` con contraseñas de base de datos se suba a GitHub |
| [`pmng/.env.example`](pmng/.env.example) | **Plantilla versionable** | Documenta la estructura de las 6 variables `ENV_*` sin exponer credenciales reales |
| [`pmng/docker-compose.yml`](pmng/docker-compose.yml) | **Sin cambios** | Construye `backend:v1.0` (`pmng-servicios`) y `frontend:v1.0` (`pmng-cliente`) y los une a la red externa `pmng-net` |
| [`pmng/.env`](pmng/.env) | **Sin cambios en contenido, pero cambia su entrega** | Define `ENV_SERVICE_PORT=8080`, `ENV_DB_HOST=pmng-mysql`, `ENV_DB_PORT=3306`, `ENV_DB_NAME=people-dev`, `ENV_DB_USER=root` y `ENV_DB_PASS=root`. En vez de viajar por Git, se sube a Jenkins como credencial *Secret file* con ID `pmng-env` |
| [`pmng/service/`](pmng/service/) | **Sin cambios** | [`application.properties`](pmng/service/src/main/resources/application.properties) sigue leyendo `DC_SERVICE_PORT`, `DC_DB_HOST`, `DC_DB_PORT`, `DC_DB_NAME`, `DC_DB_USER` y `DC_DB_PASS` |
| [`pmng/client/main.js`](pmng/client/main.js) | **Nota importante sobre la IP** | En este archivo aparece `const URL = "http://18.235.1.133:8089";`. Si la instancia EC2 cambia de IP pública al reiniciarse (o si se desea que sea dinámica como en Compose con ``const URL = `http://${window.location.hostname}:8089`;``), debe actualizarse antes de hacer `git push` para que el navegador apunte a la IP activa |

---

## 3. El Manejo Seguro de `.env` entre Git y Jenkins

En un flujo profesional con Git y CI/CD, **los archivos `.env` nunca deben subirse al repositorio de GitHub**, ya que exponen puertos, hosts y contraseñas de bases de datos.

Esta práctica resuelve ese problema combinando tres piezas:

1. **En [`pmng/.gitignore`](pmng/.gitignore) y [`pmng/.env.example`](pmng/.env.example):**
   ```gitignore
   .env
   .DS_Store
   **/.DS_Store
   ```
   Cuando se ejecuta `git add .`, Git ignora automáticamente `.env`. En el repositorio solo se conserva `.env.example` como referencia de las variables requeridas:
   ```dotenv
   ENV_SERVICE_PORT=8080
   ENV_DB_HOST=pmng-mysql
   ENV_DB_PORT=3306
   ENV_DB_NAME=people-dev
   ENV_DB_USER=root
   ENV_DB_PASS=root
   ```

2. **En el almacén de credenciales de Jenkins (`Administrar Jenkins → Credentials`):**
   Se registra una credencial de tipo **Secret file** subiendo el archivo `.env` desde la computadora local y asignándole el identificador **`pmng-env`**.

3. **En el [`Jenkinsfile`](pmng/Jenkinsfile#L8):**
   ```groovy
   environment {
       COMPOSE_PROJECT_NAME = 'pmng'
       COMPOSE_FILE = 'docker-compose.yml'
       ENV_FILE = credentials('pmng-env')
   }
   ```
   Cuando el pipeline inicia, Jenkins crea un archivo temporal seguro con el contenido del `.env`, guarda la ruta de ese archivo temporal en la variable `ENV_FILE`, se la pasa a Docker Compose mediante `--env-file ${ENV_FILE}` y, al terminar el build, elimina el archivo temporal.

---

## 4. Explicación Detallada del `Jenkinsfile`

El archivo [`pmng/Jenkinsfile`](pmng/Jenkinsfile) utiliza la sintaxis de **Declarative Pipeline** de Jenkins:

```groovy
pipeline {
    agent any

    environment {
        COMPOSE_PROJECT_NAME = 'pmng'
        COMPOSE_FILE = 'docker-compose.yml'
        ENV_FILE = credentials('pmng-env')
    }

    stages {
        stage('Parar servicios') {
            steps {
                echo 'Deteniendo contenedores...'
                sh '''
                    docker compose -p ${COMPOSE_PROJECT_NAME} -f ${COMPOSE_FILE} --env-file ${ENV_FILE} down || true
                '''
            }
        }

        stage('Eliminar imagenes') {
            steps {
                echo 'Eliminando imágenes antiguas'
                sh '''
                    IMAGES=$(docker compose -p ${COMPOSE_PROJECT_NAME} -f ${COMPOSE_FILE} --env-file ${ENV_FILE} config --images | sort -u)

                    for IMAGE in $IMAGES; do
                        echo "Eliminando imagen: $IMAGE"
                        docker rmi "$IMAGE" || true
                    done
                '''
            }
        }

        stage('Construir imágenes') {
            steps {
                echo 'Generando nuevas imágenes...'
                sh '''
                    docker compose -p ${COMPOSE_PROJECT_NAME} -f ${COMPOSE_FILE} --env-file ${ENV_FILE} build --no-cache
                '''
            }
        }

        stage('Levantar servicios') {
            steps {
                echo 'Generando contenedores...'
                sh '''
                    docker compose -p ${COMPOSE_PROJECT_NAME} -f ${COMPOSE_FILE} --env-file ${ENV_FILE} up -d --force-recreate
                '''
            }
        }
    }

    post {
        success {
            echo 'Construcción del proyecto finalizada'
        }

        failure {
            echo 'Ocurrió un error en la construcción del proyecto'
        }
    }
}
```

### Desglose por sección

#### 1. `agent any`
Indica a Jenkins que puede ejecutar este pipeline en cualquier nodo o agente disponible (en nuestro caso, el nodo principal *built-in* de la propia instancia EC2).

#### 2. Bloque `environment`
Define tres variables de entorno disponibles en todas las etapas:
- `COMPOSE_PROJECT_NAME = 'pmng'`: fuerza a que Docker Compose agrupe siempre los recursos bajo el nombre de proyecto `pmng` (con la bandera `-p pmng`), sin importar cómo se llame la carpeta de trabajo interna de Jenkins (`/var/lib/jenkins/workspace/pmng`).
- `COMPOSE_FILE = 'docker-compose.yml'`: archivo de definición de servicios que se pasa con `-f`.
- `ENV_FILE = credentials('pmng-env')`: recupera el archivo `.env` guardado en Jenkins con el ID `pmng-env`.

#### 3. Etapa 1: `stage('Parar servicios')`
```bash
docker compose -p ${COMPOSE_PROJECT_NAME} -f ${COMPOSE_FILE} --env-file ${ENV_FILE} down || true
```
- Detiene y elimina los contenedores del proyecto `pmng` (`pmng-servicios` y `pmng-cliente`) que hayan sido levantados en un despliegue anterior de Compose.
- **No detiene ni elimina `pmng-persistance` ni `pmng-net`**, porque MySQL es externo al `docker-compose.yml` y la red está declarada como `external: true`.
- El operador `|| true` garantiza que si es la primera vez que corre el pipeline y no había nada que detener, el paso no falle y continúe a la siguiente etapa.

#### 4. Etapa 2: `stage('Eliminar imagenes')`
```bash
IMAGES=$(docker compose -p ${COMPOSE_PROJECT_NAME} -f ${COMPOSE_FILE} --env-file ${ENV_FILE} config --images | sort -u)

for IMAGE in $IMAGES; do
    echo "Eliminando imagen: $IMAGE"
    docker rmi "$IMAGE" || true
done
```
- `docker compose ... config --images` consulta dinámicamente los nombres de las imágenes declaradas en `docker-compose.yml` (`backend:v1.0` y `frontend:v1.0`).
- `sort -u` elimina posibles duplicados.
- El ciclo `for` recorre cada imagen y la borra con `docker rmi "$IMAGE" || true` para liberar espacio en disco y asegurar que no se reutilice una imagen vieja.

#### 5. Etapa 3: `stage('Construir imágenes')`
```bash
docker compose -p ${COMPOSE_PROJECT_NAME} -f ${COMPOSE_FILE} --env-file ${ENV_FILE} build --no-cache
```
- Ejecuta el `Dockerfile` de `./service` (compilando el JAR de Spring Boot con Maven y JDK 21) y el `Dockerfile` de `./client` (empaquetando el HTML/JS en Nginx).
- `--no-cache` obliga a Docker a reconstruir todas las capas desde cero con el código recién descargado de GitHub.

#### 6. Etapa 4: `stage('Levantar servicios')`
```bash
docker compose -p ${COMPOSE_PROJECT_NAME} -f ${COMPOSE_FILE} --env-file ${ENV_FILE} up -d --force-recreate
```
- Crea e inicia en segundo plano (`-d`) los contenedores `pmng-servicios` (`8089:8080`) y `pmng-cliente` (`5173:80`), inyectando las variables del `.env` y conectándolos a la red `pmng-net`.
- `--force-recreate` asegura que los contenedores se creen limpios a partir de las imágenes recién construidas.

#### 7. Bloque `post`
- `success`: se ejecuta únicamente si todas las etapas terminaron con código de salida `0`, imprimiendo `Construcción del proyecto finalizada`.
- `failure`: se ejecuta si cualquier etapa falla, imprimiendo `Ocurrió un error en la construcción del proyecto`.

---

## 5. Relación entre Jenkins, Docker Compose y la Red `pmng-net`

Al igual que en la práctica [3. PMNG con Docker Compose](../../Unidad-2/Trabajos/3.%20pmng%20compose/Guia%20de%20despliegue%20-%20PMNG%20con%20Docker%20Compose.md), el despliegue automatizado depende de dos recursos preexistentes creados en la práctica [2. Gestión de personas](../../Unidad-2/Trabajos/2.%20gestion-personas/Guia%20de%20despliegue%20-%20Gesti%C3%B3n%20de%20personas.md):

1. **La red bridge `pmng-net`**: declarada como `external: true` al final de [`docker-compose.yml`](pmng/docker-compose.yml#L29-L31).
2. **El contenedor `pmng-persistance` (MySQL 8.0)**: debe estar **encendido (`Up`)**, unido a `pmng-net` con el alias `pmng-mysql` y con el esquema `people-dev` creado.

Si la instancia EC2 se detuvo y se volvió a encender para esta práctica, todos los contenedores pasan a estado `Exited`. Por ello, **antes de lanzar el build en Jenkins es indispensable iniciar manualmente `pmng-persistance`**:

```bash
docker start pmng-persistance
```

---

## 6. Por Qué Deben Eliminarse `pmng-cliente` y `pmng-servicios` Previos

Un detalle importante de la práctica es qué sucede con los contenedores `pmng-cliente` y `pmng-servicios` que habían quedado creados (aunque estuvieran detenidos en estado `Exited`) de las prácticas anteriores de la Unidad 2:

1. En [`docker-compose.yml`](pmng/docker-compose.yml#L6) los contenedores tienen nombres fijos explícitos:
   - `container_name: pmng-servicios`
   - `container_name: pmng-cliente`
2. Cuando esos contenedores fueron creados manualmente en la práctica de Docker individual (`docker run --name pmng-cliente ...`) o desde otra ruta sin el proyecto `-p pmng`, Docker los tiene registrados en el sistema (incluso si están `Exited`) y/o ocupando los puertos `5173` y `8089`.
3. Al correr el pipeline en Jenkins, `docker compose -p pmng ... down` puede no eliminar contenedores huérfanos creados fuera del proyecto Compose `pmng`, y al llegar a `up -d` o `docker rmi` falla por conflicto de nombre (`Conflict. The container name "/pmng-cliente" is already in use`) o porque una imagen está retenida por un contenedor detenido (`image is being used by stopped container`).
4. **Solución obligatoria antes del primer despliegue en Jenkins:** detener y borrar manualmente esos dos contenedores previos en la terminal SSH de EC2:
   ```bash
   docker stop pmng-cliente pmng-servicios
   docker rm pmng-cliente pmng-servicios
   ```
   *(Dejando únicamente activo a `pmng-persistance`).* A partir de ese momento, Jenkins toma el control total del ciclo de vida de `pmng-servicios` y `pmng-cliente`.
