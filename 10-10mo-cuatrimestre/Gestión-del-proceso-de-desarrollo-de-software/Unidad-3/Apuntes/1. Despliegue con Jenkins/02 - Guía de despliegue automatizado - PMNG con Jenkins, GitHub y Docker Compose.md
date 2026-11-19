# 02 — Guía de Despliegue Automatizado: PMNG con Jenkins, GitHub y Docker Compose

Esta guía documenta paso a paso cómo preparar el repositorio Git del proyecto [`pmng/`](pmng/), configurar la instancia de **Amazon EC2** (partición `/tmp`, permisos de Docker para Jenkins y limpieza de contenedores previos), registrar las credenciales en **GitHub** y **Jenkins** (`GITHUB_TOKEN` y el archivo secreto `pmng-env`), y ejecutar el pipeline automatizado de despliegue.

Para revisar primero la explicación teórica del `Jenkinsfile` y los cambios del proyecto, consulta [01 — Explicación de Jenkinsfile, Proyecto PMNG y Flujo CI/CD](01%20-%20Explicaci%C3%B3n%20de%20Jenkinsfile%2C%20Proyecto%20PMNG%20y%20Flujo%20CI-CD.md).

---

## Tabla de Contenidos

1. [Arquitectura General del Despliegue](#1-arquitectura-general-del-despliegue)
2. [Requisitos Previos de Prácticas Anteriores](#2-requisitos-previos-de-prácticas-anteriores)
3. [Fase 1 — Inicializar Git y Subir el Proyecto a GitHub](#3-fase-1--inicializar-git-y-subir-el-proyecto-a-github)
4. [Fase 2 — Preparar la Instancia EC2 por SSH](#4-fase-2--preparar-la-instancia-ec2-por-ssh)
5. [Fase 3 — Generar el Token en GitHub](#5-fase-3--generar-el-token-en-github)
6. [Fase 4 — Crear el Pipeline y Registrar Credenciales en Jenkins](#6-fase-4--crear-el-pipeline-y-registrar-credenciales-en-jenkins)
7. [Fase 5 — Registrar el Archivo .env como Secret File (pmng-env)](#7-fase-5--registrar-el-archivo-env-como-secret-file-pmng-env)
8. [Fase 6 — Limpiar Contenedores Previos y Ejecutar el Pipeline](#8-fase-6--limpiar-contenedores-previos-y-ejecutar-el-pipeline)
9. [Errores Frecuentes y Solución de Problemas](#9-errores-frecuentes-y-solución-de-problemas)
10. [Secuencia Completa de Comandos](#10-secuencia-completa-de-comandos)
11. [Lista de Comprobación](#11-lista-de-comprobación)

---

## 1. Arquitectura General del Despliegue

```text
┌─────────────────────────────────────────────────────────────────────────┐
│ 1. Máquina Local (Git Bash)                                             │
│    Proyecto pmng/ con Jenkinsfile, docker-compose.yml y .gitignore      │
│    (.env queda excluido de Git)                                         │
└───────────────────────────────────┬─────────────────────────────────────┘
                                    │ git push -u origin main (o rama test)
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ 2. GitHub (Repositorio privado: AlexAviles345/ajca-pmng)                │
│    Autenticado mediante Personal Access Token (JENKINS-TOKEN)           │
└───────────────────────────────────┬─────────────────────────────────────┘
                                    │ Checkout SCM (credencial GITHUB_TOKEN)
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ 3. Instancia AWS EC2 (Ubuntu 26.04 LTS)                                 │
│                                                                         │
│   ┌─────────────────────────────────────────────────────────────────┐   │
│   │ Servicio Jenkins (:8080)                                        │   │
│   │ - Usuario 'jenkins' en el grupo 'docker'                        │   │
│   │ - /tmp ampliado a 2 GB (tmp.mount)                              │   │
│   │ - Credencial Secret file 'pmng-env' (.env)                      │   │
│   └───────────────────────────────┬─────────────────────────────────┘   │
│                                   │ Ejecuta Jenkinsfile                 │
│                                   ▼                                     │
│   ┌─────────────────────────────────────────────────────────────────┐   │
│   │ Red Docker externa: pmng-net                                    │   │
│   │                                                                 │   │
│   │  ┌─────────────────────┐  ┌──────────────────┐  ┌────────────┐  │   │
│   │  │ pmng-persistance    │  │ pmng-servicios   │  │pmng-cliente│  │   │
│   │  │ MySQL 8.0 (:3306)   │◄─┤ Spring Boot      │  │Nginx       │  │   │
│   │  │ Alias: pmng-mysql   │  │ (:8089 -> :8080) │  │(:5173->:80)│  │   │
│   │  │ Base: people-dev    │  └──────────────────┘  └────────────┘  │   │
│   │  │ (Creado en Unidad 2)│       (Creados por Jenkins + Compose)  │   │
│   │  └─────────────────────┘                                        │   │
│   └─────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Requisitos Previos de Prácticas Anteriores

Antes de iniciar este despliegue, la instancia EC2 ya cuenta con los elementos configurados en la Unidad 2:

1. **Docker y Git instalados en EC2:** realizados en [02 — Instalar Git y Docker](../../Unidad-2/Apuntes/1.%20ec2-docker-y-nginx-inicial/02%20-%20Instalar%20Git%20y%20Docker.md).
2. **Jenkins instalado y activo en el puerto `8080` con el plugin *GitHub Integration*:** realizado en [03 — Instalar y configurar Jenkins](../../Unidad-2/Apuntes/1.%20ec2-docker-y-nginx-inicial/03%20-%20Instalar%20y%20configurar%20Jenkins.md).
3. **Red `pmng-net`, contenedor `pmng-persistance` y base de datos `people-dev`:** creados en [Guía de despliegue — Gestión de personas](../../Unidad-2/Trabajos/2.%20gestion-personas/Guia%20de%20despliegue%20-%20Gesti%C3%B3n%20de%20personas.md) con los comandos:
   ```bash
   docker network create --driver bridge pmng-net

   docker run -d \
     -p 3306:3306 \
     -e MYSQL_ROOT_PASSWORD=root \
     --name pmng-persistance \
     --network pmng-net \
     --network-alias pmng-mysql \
     mysql:8.0
   ```
   *(Seguido de `CREATE DATABASE \`people-dev\`;`)*.
4. **Reglas de entrada en el Grupo de Seguridad de EC2:**
   - Puerto `22` (SSH)
   - Puerto `8080` (Interfaz web de Jenkins)
   - Puerto `5173` (Cliente web Nginx `pmng-cliente`)
   - Puerto `8089` (API Spring Boot `pmng-servicios`)

---

## 3. Fase 1 — Inicializar Git y Subir el Proyecto a GitHub

Los siguientes comandos se ejecutan en la máquina local usando **Git Bash** dentro de la carpeta [`pmng/`](pmng/).

### 3.1 Inicializar el repositorio y configurar el autor local

```bash
cd pmng/
git init
git config --local user.name "AlexAviles345"
git config --local user.email "correo@ejemplo.com"
```

### 3.2 Vincular el repositorio remoto de GitHub

Previamente se creó en GitHub un repositorio privado vacío llamado **`ajca-pmng`**. Se vincula como `origin` y se verifica la configuración local:

```bash
git remote add origin https://AlexAviles345@github.com/AlexAviles345/ajca-pmng.git
git config --local --list
```

Salida obtenida:

```text
core.repositoryformatversion=0
core.filemode=false
core.bare=false
core.logallrefupdates=true
core.symlinks=false
core.ignorecase=true
user.name=AlexAviles345
user.email=correo@ejemplo.com
remote.origin.url=https://AlexAviles345@github.com/AlexAviles345/ajca-pmng.git
```

### 3.3 Revisar archivos con `git status` y preparar el primer commit

```bash
git status
```

Salida:

```text
On branch master

No commits yet

Untracked files:
  (use "git add <file>..." to include in what will be committed)
        .gitignore
        Jenkinsfile
        client/
        docker-compose.yml
        service/
```

> **Observación clave:** El archivo [`.env`](pmng/.env) existe dentro de `pmng/`, pero **no aparece en `Untracked files`** porque [`.gitignore`](pmng/.gitignore) lo excluye desde el inicio. Para referencia en el repositorio se cuenta con la plantilla [`.env.example`](pmng/.env.example).

Se agregan los archivos al área de preparación (*staging*) y se realiza el primer commit:

```bash
git add .
git status
git commit -m "[FIRST COMMIT] Carga inicial del proyecto"
```

### 3.4 Cambiar de `master` a `main` y subir a GitHub

Si al intentar subir directamente a `main` con `git push -u origin main`, Git devuelve:

```text
error: src refspec main does not match any
error: failed to push some refs to 'https://github.com/AlexAviles345/ajca-pmng.git'
```

**¿Por qué ocurre esto?** Porque `git init` creó por defecto la rama local con el nombre **`master`**, mientras que se está intentando hacer push de una rama llamada **`main`** que aún no existe localmente.

Para resolverlo, se verifica el commit con `git log`, se crea la rama `main` a partir del commit actual y se sube al repositorio remoto:

```bash
git log
git checkout -b main
git push -u origin main
```

Salida exitosa:

```text
Enumerating objects: 46, done.
Counting objects: 100% (46/46), done.
Delta compression using up to 8 threads
Compressing objects: 100% (31/31), done.
Writing objects: 100% (46/46), 14.50 KiB | 1.81 MiB/s, done.
Total 46 (delta 0), reused 0 (delta 0), pack-reused 0 (from 0)
To https://github.com/AlexAviles345/ajca-pmng.git
 * [new branch]      main -> main
branch 'main' set up to track 'origin/main'.
```

> **Nota sobre ramas adicionales (`test`):** Si en la configuración del Pipeline de Jenkins se especifica la rama `*/test`, se puede crear y publicar la rama con:
> ```bash
> git checkout -b test
> git push -u origin test
> ```

---

## 4. Fase 2 — Preparar la Instancia EC2 por SSH

Los siguientes comandos se ejecutan desde **AWS CloudShell** hacia la instancia EC2.

### 4.1 Conectarse por SSH a la instancia EC2

```bash
ssh -i "ajca-server-key.pem" ubuntu@ec2-100-48-195-125.compute-1.amazonaws.com
```

*(Recuerda que cada vez que detienes e inicias la instancia EC2 en AWS, su IP y DNS público cambian; por ejemplo, durante la sesión también se utilizó la IP `98.82.22.53`).*

### 4.2 Revisar los contenedores existentes e iniciar `pmng-persistance`

Al entrar a la instancia recién encendida, todos los contenedores de prácticas anteriores están detenidos (`Exited`):

```bash
docker ps -a
```

Salida en terminal:

```text
CONTAINER ID   IMAGE              COMMAND                  CREATED       STATUS                     PORTS     NAMES
ee95d58c7586   demo:latest        "/docker-entrypoint.…"   2 days ago    Exited (0) 2 days ago                front
9fc3e8acd3e4   frontend:v1.0      "/docker-entrypoint.…"   12 days ago   Exited (137) 12 days ago             pmng-cliente
065da6ce3d17   backend:v1.0       "java -jar app.jar"      12 days ago   Exited (143) 12 days ago             pmng-servicios
7805207ba605   mysql:8.0          "docker-entrypoint.s…"   12 days ago   Exited (0) 12 days ago               pmng-persistance
098937763fc0   back:v1.2          "java -jar app.jar"      2 weeks ago   Exited (143) 2 weeks ago             backend2
a9be2e1e168b   back:v1.1          "java -jar app.jar"      2 weeks ago   Exited (143) 2 weeks ago             backend1
e78f1b920b4a   biografia:v1.0     "/docker-entrypoint.…"   2 weeks ago   Exited (0) 2 weeks ago               biografia
feea70fff6fd   my-services:v1.1   "java -jar app.jar"      3 weeks ago   Exited (143) 3 weeks ago             my-services
f5332fb60e4a   mysql:8.0          "docker-entrypoint.s…"   3 weeks ago   Exited (0) 3 weeks ago               mysql
```

Se inicia el contenedor de base de datos `pmng-persistance` (por su ID `7805207ba605` o por su nombre) y se comprueba con `docker ps`:

```bash
docker start 7805207ba605
docker ps
```

```text
CONTAINER ID   IMAGE       COMMAND                  CREATED       STATUS         PORTS                                                    NAMES
7805207ba605   mysql:8.0   "docker-entrypoint.s…"   12 days ago   Up 5 seconds   0.0.0.0:3306->3306/tcp, [::]:3306->3306/tcp, 33060/tcp   pmng-persistance
```

> **Importante — Eliminar `pmng-cliente` y `pmng-servicios` inactivos:**  
> Como se observa en la salida de `docker ps -a`, habían quedado creados e inactivos (`Exited`) los contenedores `pmng-cliente` (`9fc3e8acd3e4`) y `pmng-servicios` (`065da6ce3d17`) de las prácticas de la Unidad 2. **Esos dos contenedores deben eliminarse** antes de correr el pipeline de Jenkins:
> ```bash
> docker rm -f pmng-cliente pmng-servicios
> ```
> Si no se borran, cuando Jenkins intente borrar las imágenes antiguas (`frontend:v1.0` y `backend:v1.0`) o crear los contenedores nuevos con esos mismos nombres, Docker devolverá error porque los contenedores previos siguen registrados.

---

### 4.3 Ampliar el directorio `/tmp` a 2 GB (`tmpfs`)

Jenkins supervisa continuamente el espacio libre en `/tmp` para ejecutar scripts, descomprimir herramientas y compilar proyectos. En instancias EC2 pequeñas, `/tmp` puede llenarse o provocar que Jenkins marque el nodo *built-in* como desconectado (*Free Temp Space* monitor).

#### 1. Ampliar `/tmp` en caliente (para la sesión actual)

```bash
sudo mount -o remount,size=2G /tmp
```

#### 2. Hacer permanente la configuración de 2 GB con `systemd`

Se crea/edita la unidad `/etc/systemd/system/tmp.mount`:

```bash
sudo nano /etc/systemd/system/tmp.mount
```

Contenido del archivo (verificado con `cat /etc/systemd/system/tmp.mount`):

```ini
[Unit]
Description=Temporary Directory
Before=local-fs.target

[Mount]
What=tmpfs
Where=/tmp
Type=tmpfs
Options=mode=1777,nosuid,nodev,size=2G

[Install]
WantedBy=local-fs.target
```

#### 3. Recargar `systemd`, habilitar la unidad y verificar con `df -h`

```bash
sudo systemctl daemon-reload
sudo systemctl enable tmp.mount
df -h /tmp
```

Salida:

```text
Filesystem      Size  Used Avail Use% Mounted on
tmpfs           2.0G  4.8M  2.0G   1% /tmp
```

---

### 4.4 Dar permisos de Docker al usuario `jenkins`

El servicio de Jenkins corre bajo el usuario del sistema `jenkins`. Para que el `Jenkinsfile` pueda ejecutar comandos `docker` y `docker compose` sin `sudo` (y sin fallar por `permission denied while trying to connect to the Docker daemon socket`), se agrega el usuario `jenkins` al grupo `docker` y se reinicia el servicio:

```bash
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
```

---

## 5. Fase 3 — Generar el Token en GitHub

Como el repositorio `AlexAviles345/ajca-pmng` es **privado**, Jenkins necesita autenticarse con GitHub para poder clonarlo. GitHub ya no acepta la contraseña de la cuenta para operaciones Git por HTTPS; exige un **Personal Access Token (PAT)**.

1. En GitHub, entra a **Settings** (menú de tu perfil) $\rightarrow$ **Developer settings** (al final de la barra lateral izquierda).
2. Despliega **Personal access tokens** $\rightarrow$ **Tokens (classic)**.

![Menú Developer Settings y Tokens (classic) en GitHub](imagenes/03-github-developer-settings.webp)

3. Pulsa **Generate new token (classic)**, asígnale el nombre **`JENKINS-TOKEN`** y marca los permisos de repositorio (`repo`, `workflow`, `admin:repo_hook`).
4. Genera el token y **copia su valor inmediatamente** (lo usarás como contraseña en Jenkins).

![Token clásico JENKINS-TOKEN generado en GitHub](imagenes/04-github-token-classic-generado.webp)

5. Abre la página de tu repositorio privado `ajca-pmng`, despliega el botón verde **`<> Code`** y copia la URL HTTPS:
   ```text
   https://github.com/AlexAviles345/ajca-pmng.git
   ```

![Copia de la URL HTTPS del repositorio privado ajca-pmng](imagenes/05-github-repositorio-ajca-pmng-url.webp)

---

## 6. Fase 4 — Crear el Pipeline y Registrar Credenciales en Jenkins

1. Abre Jenkins en el navegador usando la IP pública actual de EC2 y el puerto `8080`:
   ```text
   http://IP_PUBLICA_EC2:8080/
   ```
2. En la pantalla de bienvenida, pulsa **Create a job** (o **Nueva Tarea** en el menú izquierdo).

![Pantalla de bienvenida de Jenkins con el botón Create a job](imagenes/01-jenkins-bienvenida-create-job.webp)

3. En **Enter an item name**, escribe **`pmng`**, selecciona el tipo **Pipeline** y pulsa **OK**.

![Creación de la tarea pmng de tipo Pipeline](imagenes/02-jenkins-nueva-tarea-pipeline.webp)

4. Dentro de la configuración del Pipeline, baja hasta la sección **Pipeline**:
   - En **Definition**, selecciona **`Pipeline script from SCM`**.
   - En **SCM**, selecciona **`Git`**.
   - En **Repository URL**, pega `https://github.com/AlexAviles345/ajca-pmng.git`.
5. Debajo de **Credentials**, pulsa el botón **Add** $\rightarrow$ **Jenkins** para registrar el token de GitHub.
6. En la ventana **Add Credentials**, selecciona el tipo **`Username with password`** y pulsa **Next**.

![Selección del tipo de credencial Username with password en Jenkins](imagenes/06-jenkins-add-credentials-tipo.webp)

7. Llena el formulario con estos datos y pulsa **Create**:
   - **Scope:** `Global (Jenkins, nodes, items, all child items, etc)`
   - **Username:** `AlexAviles345`
   - **Password:** *(pega aquí el Personal Access Token generado en GitHub)*
   - **ID:** `GITHUB_TOKEN`
   - **Description:** `Llave de github`

![Configuración de la credencial GITHUB_TOKEN con usuario y token de GitHub](imagenes/07-jenkins-credencial-github-token.webp)

8. De vuelta en la sección **Pipeline**:
   - Selecciona en **Credentials** la credencial recién creada: `AlexAviles345/****** (Llave de github)`.
   - En **Branches to build $\rightarrow$ Branch Specifier**, escribe la rama a desplegar (en la captura se configuró `*/test`; si subiste tus cambios a `main`, usa `*/main`).
   - Verifica que **Script Path** diga `Jenkinsfile` y pulsa **Save**.

![Configuración de Repository URL, Credentials y Branch Specifier en el Pipeline](imagenes/08-jenkins-pipeline-scm-git-config.webp)

9. Una vez guardado, verás la página principal del Pipeline `pmng` aún sin ejecuciones (`No builds`). **Todavía no pulses `Construir ahora`**, porque antes debemos registrar la credencial `pmng-env` que pide el `Jenkinsfile`.

![Vista inicial del Pipeline pmng recién creado](imagenes/09-jenkins-pipeline-creado-sin-builds.webp)

---

## 7. Fase 5 — Registrar el Archivo `.env` como Secret File (`pmng-env`)

Observa la línea 8 de nuestro [`Jenkinsfile`](pmng/Jenkinsfile#L8):

```groovy
ENV_FILE = credentials('pmng-env')
```

Si ejecutas el pipeline sin haber creado una credencial con el ID exacto **`pmng-env`**, Jenkins abortará inmediatamente indicando que no encuentra la credencial `pmng-env`.

Para registrarla:

1. Haz clic en el icono de engrane superior (**Administrar Jenkins** / *Manage Jenkins*).

![Panel Administrar Jenkins](imagenes/10-jenkins-administrar-jenkins.webp)

2. Baja a la sección **Security** y entra en **Credentials** (*Configure credentials*).

![Acceso a Credentials dentro de la sección Security](imagenes/11-jenkins-seccion-security-credentials.webp)

3. Haz clic en el dominio **(global)** o en el botón **+ Add Credentials** arriba a la derecha.
4. En el modal **Add Credentials**, selecciona el tipo **`Secret file`** y pulsa **Next**.

![Selección del tipo de credencial Secret file en Jenkins](imagenes/12-jenkins-add-credentials-secret-file.webp)

5. Completa el formulario asegurándote de que el **ID** coincida letra por letra con el `Jenkinsfile`:
   - **Scope:** `Global (Jenkins, nodes, items, all child items, etc)`
   - **File:** pulsa **Seleccionar archivo** y elige tu archivo local [`pmng/.env`](pmng/.env)
   - **ID:** `pmng-env`
   - **Description:** `Variables de entorno`

![Comparación entre credentials('pmng-env') del Jenkinsfile y el registro del Secret file .env en Jenkins](imagenes/13-jenkins-credencial-pmng-env-vs-jenkinsfile.webp)

6. Pulsa **Create**. Ahora la tabla de **Credentials** mostrará registradas tanto `GITHUB_TOKEN` como `pmng-env`:

![Credenciales GITHUB_TOKEN y pmng-env registradas en Jenkins](imagenes/14-jenkins-credenciales-registradas.webp)

---

## 8. Fase 6 — Limpiar Contenedores Previos y Ejecutar el Pipeline

### 8.1 Verificar en EC2 que `pmng-persistance` esté arriba y sin contenedores conflictivos

Antes de lanzar la construcción definitiva:

> **Debe estar levantado el contenedor de Docker de `pmng-persistance` hecho en anteriores actividades, y los contenedores `pmng-cliente` y `pmng-servicios` creados manualmente en prácticas previas deben ser eliminados.**

En la terminal SSH de EC2:

```bash
docker ps
docker start pmng-persistance
docker stop pmng-cliente
docker rm pmng-cliente
```

*(Y si `pmng-servicios` también seguía existiendo de prácticas anteriores: `docker rm -f pmng-servicios`).*

![Inicio de pmng-persistance y eliminación del contenedor previo pmng-cliente en EC2](imagenes/16-docker-iniciar-mysql-y-eliminar-contenedores-previos.webp)

### 8.2 Ejecutar el Pipeline en Jenkins (`Construir ahora`)

1. Regresa al panel del proyecto `pmng` en Jenkins (`Jenkins / pmng`).
2. En el menú lateral izquierdo, haz clic en **Construir ahora** (*Build Now*).

![Botón Construir ahora en el Pipeline pmng](imagenes/15-jenkins-construir-ahora.webp)

3. En el recuadro inferior **Builds**, verás cómo se ejecuta la tarea hasta finalizar con éxito (icono verde ✅ en los builds **`#6`** y **`#7`**):

![Historial de builds mostrando las ejecuciones #6 y #7 exitosas](imagenes/17-jenkins-historial-builds-exito.webp)

### 8.3 Verificar las Etapas (Stages) en Jenkins

Al entrar al build **`#7` $\rightarrow$ Stages**, se visualiza el grafo completo del pipeline con todas las etapas en verde (tomando 55 segundos en total) y la salida `Construcción del proyecto finalizada` en `Post Actions`:

- **Checkout SCM** (`0.4s`): clona el repositorio `ajca-pmng` desde GitHub.
- **Parar servicios** (`0.34s`): ejecuta `docker compose ... down || true`.
- **Eliminar imagenes** (`0.34s`): elimina imágenes antiguas `backend:v1.0` y `frontend:v1.0`.
- **Construir imágenes** (`51s`): compila el backend con Maven y construye las imágenes con `--no-cache`.
- **Levantar servicios** (`1s`): levanta `pmng-servicios` y `pmng-cliente` con `up -d --force-recreate`.
- **Post Actions** (`80ms`): imprime `Construcción del proyecto finalizada`.

![Vista de Stages del build #7 completado con éxito en Jenkins](imagenes/19-jenkins-pipeline-stages-completados.webp)

### 8.4 Comprobar en la terminal SSH de EC2 los tres contenedores activos

Al ejecutar `docker ps` en la terminal de EC2 antes y después de que termine el pipeline de Jenkins, se confirma que a la par de `pmng-persistance` ahora están corriendo `pmng-cliente` (`5173->80/tcp`) y `pmng-servicios` (`8089->8080/tcp`) recién creados hace pocos segundos:

```bash
docker ps
```

![Salida de docker ps mostrando los tres contenedores activos tras el despliegue de Jenkins](imagenes/18-docker-ps-tres-contenedores-activos.webp)

---

## 9. Errores Frecuentes y Solución de Problemas

| Error / Síntoma | Causa | Solución aplicada |
|---|---|---|
| `error: src refspec main does not match any` al hacer `git push -u origin main` | `git init` creó la rama local con el nombre `master`, por lo que no existía una rama local llamada `main` | Ejecutar `git checkout -b main` antes de `git push -u origin main` |
| Fallo en Jenkins por conflicto de contenedores o imágenes en uso (`pmng-cliente` / `pmng-servicios`) | Habían quedado contenedores `pmng-cliente` y `pmng-servicios` creados manualmente en las prácticas de la Unidad 2 | Eliminar los contenedores viejos con `docker stop pmng-cliente pmng-servicios` y `docker rm pmng-cliente pmng-servicios` dejando solo `pmng-persistance` |
| `permission denied while trying to connect to the Docker daemon socket` en Jenkins | El usuario `jenkins` de Linux no pertenecía al grupo `docker` | Ejecutar `sudo usermod -aG docker jenkins` y `sudo systemctl restart jenkins` |
| Espacio insuficiente en `/tmp` durante la compilación o bloqueo del nodo en Jenkins | La partición `/tmp` por defecto era pequeña para las descargas y compilaciones temporales | Ampliar `/tmp` a `2G` con `sudo mount -o remount,size=2G /tmp` y persistirlo en `/etc/systemd/system/tmp.mount` |
| `pmng-servicios` se detiene inmediatamente después de que Jenkins termina en verde | El contenedor `pmng-persistance` (MySQL) estaba detenido (`Exited`) al reiniciar la instancia EC2 | Iniciar siempre MySQL antes con `docker start pmng-persistance` |

---

## 10. Secuencia Completa de Comandos

### A) En tu computadora local (Git Bash)

```bash
cd pmng/
git init
git config --local user.name "AlexAviles345"
git config --local user.email "correo@ejemplo.com"
git remote add origin https://AlexAviles345@github.com/AlexAviles345/ajca-pmng.git
git config --local --list

git status
git add .
git commit -m "[FIRST COMMIT] Carga inicial del proyecto"
git checkout -b main
git push -u origin main
```

### B) En la instancia EC2 (vía SSH desde CloudShell)

```bash
ssh -i "ajca-server-key.pem" ubuntu@DNS_PUBLICO_EC2

# 1. Revisar contenedores, levantar MySQL y borrar cliente/servicios viejos
docker ps -a
docker start pmng-persistance
docker rm -f pmng-cliente pmng-servicios
docker ps

# 2. Ampliar /tmp a 2 GB en caliente y de forma permanente
sudo mount -o remount,size=2G /tmp
sudo nano /etc/systemd/system/tmp.mount
cat /etc/systemd/system/tmp.mount
sudo systemctl daemon-reload
sudo systemctl enable tmp.mount
df -h /tmp

# 3. Agregar el usuario jenkins al grupo docker y reiniciar Jenkins
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
```

---

## 11. Lista de Comprobación

- [ ] El repositorio en GitHub (`ajca-pmng`) contiene `Jenkinsfile`, `docker-compose.yml`, `.gitignore`, `client/` y `service/`, pero **no** contiene `.env`.
- [ ] La red `pmng-net` existe en EC2 (`docker network ls`).
- [ ] El contenedor `pmng-persistance` está en estado `Up` (`docker ps`) y tiene la base `people-dev`.
- [ ] Los contenedores antiguos `pmng-cliente` y `pmng-servicios` de prácticas anteriores fueron eliminados.
- [ ] `df -h /tmp` reporta `2.0G` de tamaño en `tmpfs`.
- [ ] El usuario `jenkins` pertenece al grupo `docker` y el servicio `jenkins` fue reiniciado.
- [ ] La credencial `GITHUB_TOKEN` (`Username with password`) está registrada en Jenkins con el Personal Access Token de GitHub.
- [ ] La credencial `pmng-env` (`Secret file`) está registrada en Jenkins con el archivo `.env`.
- [ ] El Pipeline `pmng` apunta al repositorio `https://github.com/AlexAviles345/ajca-pmng.git` y a la rama correcta (`*/main` o `*/test`).
- [ ] Al pulsar **Construir ahora**, las etapas `Checkout SCM`, `Parar servicios`, `Eliminar imagenes`, `Construir imágenes`, `Levantar servicios` y `Post Actions` finalizan en verde.
- [ ] `docker ps` en EC2 muestra los 3 contenedores activos (`pmng-persistance`, `pmng-servicios` y `pmng-cliente`).
