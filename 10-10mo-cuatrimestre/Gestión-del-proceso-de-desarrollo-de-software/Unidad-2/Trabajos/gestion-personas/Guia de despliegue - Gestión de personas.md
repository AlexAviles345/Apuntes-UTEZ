# Práctica — Gestión de Personas con Docker en AWS EC2

Esta guía explica cómo desplegar la aplicación `pmng` en una instancia de Amazon EC2. La práctica utiliza tres contenedores: MySQL para almacenar personas, un backend de Spring Boot para consultar y registrar sus nombres, y un cliente HTML con JavaScript servido por Nginx.

El procedimiento toma como base [Comandos pmng.docx](Comandos%20pmng.docx), sus capturas y el código de [`pmng/`](pmng/). La instancia EC2 debe estar creada y encendida; su creación no forma parte de esta actividad.

---

## Tabla de Contenidos

1. [Objetivo](#1-objetivo)
2. [Arquitectura](#2-arquitectura)
3. [Requisitos Previos](#3-requisitos-previos)
4. [Enviar el Proyecto desde CloudShell](#4-enviar-el-proyecto-desde-cloudshell)
5. [Conectarse y Descomprimir](#5-conectarse-y-descomprimir)
6. [Comprobar o Crear pmng-net](#6-comprobar-o-crear-pmng-net)
7. [Levantar MySQL y Crear la Base de Datos](#7-levantar-mysql-y-crear-la-base-de-datos)
8. [Construir y Levantar el Backend](#8-construir-y-levantar-el-backend)
9. [Construir y Levantar el Cliente](#9-construir-y-levantar-el-cliente)
10. [Comprobar el Despliegue](#10-comprobar-el-despliegue)
11. [Probar la Aplicación y los Endpoints](#11-probar-la-aplicación-y-los-endpoints)
12. [Reglas de Entrada](#12-reglas-de-entrada)
13. [Errores Frecuentes](#13-errores-frecuentes)
14. [Secuencia Completa](#14-secuencia-completa)
15. [Lista de Comprobación](#15-lista-de-comprobación)

---

## 1. Objetivo

La aplicación permite escribir un nombre, guardarlo en MySQL y consultar la lista de personas registradas desde una página web.

- `pmng-persistance` ejecuta MySQL 8.0 y utiliza el alias interno `pmng-mysql`.
- `pmng-servicios` ejecuta el backend y utiliza el alias interno `pmng-back`.
- `pmng-cliente` sirve la página y el archivo `main.js` mediante Nginx.
- Los tres contenedores se conectan a la red bridge `pmng-net`.

Se conservan los nombres del documento, incluyendo `pmng-persistance`, para que los comandos coincidan con las capturas.

---

## 2. Arquitectura

![Arquitectura de la aplicación de gestión de personas](arquitectura-gestion-personas.webp)

El flujo de una operación es:

```text
Navegador
    │
    ├── GET http://IP_PUBLICA_EC2:5173/
    │                 ↓
    │         pmng-cliente / Nginx :80
    │         entrega index.html y main.js
    │
    └── main.js ejecutado en el navegador
              │
              └── GET / POST http://IP_PUBLICA_EC2:8089/people
                                      ↓
                             pmng-servicios :8080
                                      ↓
                  jdbc:mysql://pmng-mysql:3306/people-dev
                                      ↓
                           pmng-persistance :3306
```

Aunque los tres contenedores pertenecen a `pmng-net`, las peticiones de JavaScript al backend salen del **navegador del usuario**. Por eso `main.js` utiliza la IP pública y el puerto `8089`. El alias `pmng-back` solo se resuelve dentro de la red Docker; no se utiliza como dirección de la API en el navegador.

El backend sí accede a MySQL mediante su alias interno `pmng-mysql` y el puerto `3306`.

| Componente | Imagen | Contenedor | Alias interno | Puerto EC2 → contenedor |
|---|---|---|---|---|
| Base de datos | `mysql:8.0` | `pmng-persistance` | `pmng-mysql` | `3306:3306` |
| Backend | `backend:v1.0` | `pmng-servicios` | `pmng-back` | `8089:8080` |
| Cliente | `frontend:v1.0` | `pmng-cliente` | No se asigna uno adicional | `5173:80` |

El puerto `5173` se eligió para publicar Nginx; el cliente no utiliza un servidor de desarrollo de Vite.

---

## 3. Requisitos Previos

Antes de iniciar se necesita:

- Una instancia EC2 encendida, con su IP pública o DNS público.
- Una llave privada `.pem` autorizada y acceso a AWS CloudShell.
- Docker instalado y activo en EC2.
- `unzip` disponible en EC2.
- El archivo `pmng.zip`, que debe contener la carpeta `pmng/` con `service/` y `client/`.
- Reglas de entrada para SSH, la página y la API. El acceso externo a MySQL se explica en la sección 12.

La IP `18.235.1.133` aparece en el documento y en `main.js` como dirección utilizada durante la práctica. Para repetirla, sustituya esa IP por la de su instancia. Las capturas son evidencia del despliegue original y no garantizan que esa dirección siga disponible.

### Organización dentro del repositorio

```text
gestion-personas/
├── pmng/
│   ├── service/                 # API Spring Boot y Dockerfile
│   └── client/                  # HTML, JavaScript y Dockerfile de Nginx
├── imagenes/                   # Capturas del documento convertidas a WebP
├── Comandos pmng.docx
├── arquitectura-gestion-personas.webp # Diagrama de la aplicación
└── Guia de despliegue - Gestión de personas.md
```

Las nueve capturas del DOCX se encuentran en `imagenes/` en formato WebP. El diagrama se convirtió de PNG a WebP sin pérdida y se guardó en la carpeta principal de la práctica como `arquitectura-gestion-personas.webp`.

---

## 4. Enviar el Proyecto desde CloudShell

Cargue `pmng.zip` y la llave privada en CloudShell. En los comandos originales la llave está en `certs/ajca-server-key.pem`.

```bash
ls -lh pmng.zip
ls -lh certs
chmod 400 certs/ajca-server-key.pem
```

Transfiera el proyecto a EC2:

```bash
scp -i certs/ajca-server-key.pem \
  pmng.zip \
  ubuntu@DNS_PUBLICO_EC2:/home/ubuntu/
```

Sustituya `DNS_PUBLICO_EC2` y el nombre de la llave según su instancia. En el documento se utilizó `ec2-18-235-1-133.compute-1.amazonaws.com`.

---

## 5. Conectarse y Descomprimir

Desde CloudShell, abra una sesión SSH:

```bash
ssh -i certs/ajca-server-key.pem ubuntu@DNS_PUBLICO_EC2
```

A partir de este punto, los comandos se ejecutan **dentro de EC2**:

```bash
docker --version
docker ps
cd /home/ubuntu
unzip pmng.zip
ls -lh pmng/service/Dockerfile pmng/client/Dockerfile
```

La estructura esperada es:

```text
/home/ubuntu/pmng/
├── service/
└── client/
```

Si el ZIP se preparó con otra estructura, ajuste las rutas antes de ejecutar `docker build`.

---

## 6. Comprobar o Crear pmng-net

Compruebe si existe la red:

```bash
docker network inspect pmng-net
```

Si aparece `network pmng-net not found`, créela con el comando del documento:

```bash
docker network create --driver bridge pmng-net
```

Liste las redes para confirmar:

```bash
docker network ls
```

![Red bridge pmng-net creada](imagenes/red-pmng-net.webp)

Los comandos con `--network pmng-net` requieren que la red exista previamente.

---

## 7. Levantar MySQL y Crear la Base de Datos

### Crear el contenedor

Ejecute el comando utilizado en la práctica:

```bash
docker run -d \
  -p 3306:3306 \
  -e MYSQL_ROOT_PASSWORD=root \
  --name pmng-persistance \
  --network pmng-net \
  --network-alias pmng-mysql \
  mysql:8.0
```

| Parámetro | Función |
|---|---|
| `-d` | Ejecuta el contenedor en segundo plano |
| `-p 3306:3306` | Permite conectar un cliente MySQL mediante el puerto de EC2 |
| `-e MYSQL_ROOT_PASSWORD=root` | Define la contraseña inicial de `root` para esta práctica |
| `--name pmng-persistance` | Asigna el nombre administrativo del contenedor |
| `--network pmng-net` | Lo conecta a la red compartida |
| `--network-alias pmng-mysql` | Define el nombre que utilizará el backend |

Espere a que termine la inicialización y compruebe los logs:

```bash
docker logs pmng-persistance
```

El servidor debe indicar que está listo para aceptar conexiones. No basta con que `docker run` haya devuelto el identificador del contenedor.

### Conexión usada desde el IDE

La captura del documento muestra una conexión externa con estos datos:

| Campo | Valor de la práctica |
|---|---|
| Host | IP pública de EC2 |
| Puerto | `3306` |
| Usuario | `root` |
| Contraseña | `root` |

![Prueba de conexión a MySQL desde el IDE](imagenes/conexion-mysql.webp)

### Crear people-dev

El comando `docker run` original configura la contraseña, pero **no crea la base `people-dev`**. El documento muestra su creación manual en esta captura:

![Creación de la base people-dev desde una consola SQL](imagenes/crear-base-people-dev.webp)

La instrucción mostrada es:

```sql
CREATE DATABASE `people-dev`;
```

Los acentos graves delimitan el nombre porque contiene un guion. Para repetir el paso desde EC2 sin depender del IDE, abra el cliente del contenedor:

```bash
docker exec -it pmng-persistance mysql -u root -p
```

Introduzca la contraseña `root` y ejecute:

```sql
CREATE DATABASE IF NOT EXISTS `people-dev`;
SHOW DATABASES;
EXIT;
```

La creación de la base debe terminar **antes de iniciar el backend**.

### Configuración que utiliza el backend

El archivo [`application.properties`](pmng/service/src/main/resources/application.properties) contiene:

```properties
spring.application.name=service
spring.jpa.show-sql=true
spring.jpa.hibernate.ddl-auto=create

db.host=pmng-mysql
db.port=3306
db.name=people-dev
db.user=root
db.pass=root
```

`DBConnection` construye esta URL JDBC:

```text
jdbc:mysql://pmng-mysql:3306/people-dev
```

Hibernate crea la tabla `people`, con las columnas `id` y `name`, dentro de la base ya existente.

> **Datos de la práctica:** `ddl-auto=create` recrea las tablas al iniciar el backend, por lo que puede borrar personas registradas previamente. Los comandos originales tampoco asignan un volumen con nombre para reutilizar explícitamente los datos de MySQL al reemplazar su contenedor. Esta guía conserva la configuración original y no modifica el proyecto.

---

## 8. Construir y Levantar el Backend

Entre a la carpeta del servicio y construya la imagen:

```bash
cd /home/ubuntu/pmng/service
docker build -t backend:v1.0 .
docker images
```

![Imagen backend:v1.0 construida](imagenes/imagenes-docker.webp)

El Dockerfile compila el código de `src/` con Maven y Java 21, genera el JAR y lo ejecuta con `java -jar app.jar`. La configuración que se empaqueta procede de `src/main/resources/application.properties`.

Levante el backend con el comando del documento:

```bash
docker run -d \
  -p 8089:8080 \
  --name pmng-servicios \
  --network pmng-net \
  --network-alias pmng-back \
  backend:v1.0
```

Compruebe su estado y los logs:

```bash
docker ps
docker logs pmng-servicios
```

![Backend y MySQL ejecutándose en Docker](imagenes/contenedor-backend.webp)

El backend escucha en `8080` dentro del contenedor y se publica en `8089` en EC2. Sus operaciones están en `/people`:

| Método | Ruta | Función |
|---|---|---|
| `GET` | `/people` | Consulta las personas registradas |
| `POST` | `/people` | Guarda una persona a partir de un JSON con `name` |

---

## 9. Construir y Levantar el Cliente

### Revisar la dirección de la API

Antes de construir la imagen, revise [`pmng/client/main.js`](pmng/client/main.js). Durante la práctica se utilizó:

```javascript
const URL = "http://18.235.1.133:8089";
```

Si utiliza otra instancia, cambie esa línea para que apunte a su IP pública:

```javascript
const URL = "http://IP_PUBLICA_EC2:8089";
```

Sustituya el marcador por la IP real en el archivo que se copiará a la imagen. No use `localhost`, porque desde el navegador del usuario apuntaría a su propio equipo.

### Construir y publicar

Si continúa desde `/home/ubuntu/pmng/service`, el comando original `cd ../client/` lleva a la carpeta correcta. También puede utilizar la ruta absoluta:

```bash
cd /home/ubuntu/pmng/client
docker build -t frontend:v1.0 .
```

El Dockerfile utiliza `nginx:alpine` y copia los archivos del cliente a `/usr/share/nginx/html`.

Levante el contenedor:

```bash
docker run -d \
  -p 5173:80 \
  --name pmng-cliente \
  --network pmng-net \
  frontend:v1.0
```

![Los tres contenedores de la aplicación activos](imagenes/contenedores-pmng.webp)

Nginx escucha en `80` dentro del contenedor; la página se consulta mediante `5173` en EC2.

Si cambia `main.js` después de construir la imagen, debe reconstruirla y reemplazar el contenedor del cliente para servir la versión nueva.

---

## 10. Comprobar el Despliegue

```bash
docker ps
docker network inspect pmng-net
```

El resultado debe incluir los tres contenedores y sus puertos:

```text
NAMES              PORTS
pmng-persistance   0.0.0.0:3306->3306/tcp
pmng-servicios     0.0.0.0:8089->8080/tcp
pmng-cliente       0.0.0.0:5173->80/tcp
```

En la sección `Containers` de la red deben aparecer los tres. Si alguno no está activo:

```bash
docker ps -a
docker logs pmng-persistance
docker logs pmng-servicios
docker logs pmng-cliente
```

---

## 11. Probar la Aplicación y los Endpoints

### Comprobar desde EC2

Verifique primero la página y la consulta de personas:

```bash
curl -I http://localhost:5173/
curl -i http://localhost:8089/people
```

La página debe responder con HTTP `200`. La API debe responder con HTTP `200` y un objeto que incluya `data`, un arreglo de personas; inicialmente puede estar vacío.

Para registrar una persona de prueba:

```bash
curl -i -X POST http://localhost:8089/people \
  -H 'Content-Type: application/json' \
  -d '{"name":"Alexandro"}'
```

Si se guarda correctamente, el servicio devuelve HTTP `201`. Consulte de nuevo para verificar el registro:

```bash
curl -i http://localhost:8089/people
```

### Comprobar desde el navegador

Abra:

```text
http://IP_PUBLICA_EC2:5173/
```

1. Escriba un nombre en el campo de texto.
2. Pulse **Enviar**.
3. Compruebe que aparezca en la tabla.
4. Recargue la página y confirme que siga apareciendo, sin reiniciar el backend.

En las herramientas del navegador, la pestaña **Network** permite comprobar las solicitudes a `/people`. La carga inicial ejecuta un `GET`; el botón ejecuta un `POST` y después otro `GET` para actualizar la lista.

![Cliente mostrando personas y una consulta a people con respuesta 200](imagenes/cliente-listado-personas.webp)

El controlador permite peticiones de otros orígenes mediante `@CrossOrigin(origins = "*")`, lo que permite que la página en `5173` consulte la API en `8089`.

---

## 12. Reglas de Entrada

El grupo de seguridad de EC2 debe permitir los accesos utilizados:

| Puerto de EC2 | Uso | Cuándo se necesita |
|---|---|---|
| `22` | SSH | Para administrar la instancia desde el origen autorizado |
| `5173` | Cliente web | Para abrir la página desde el navegador |
| `8089` | API Spring Boot | Para que el JavaScript del navegador consulte y registre personas |
| `3306` | MySQL | Solo para reproducir la conexión externa desde el IDE |

![Regla de entrada del backend en el puerto 8089](imagenes/regla-entrada-backend-8089.webp)

![Regla de entrada del cliente en el puerto 5173](imagenes/regla-entrada-cliente-5173.webp)

Las capturas muestran `0.0.0.0/0` para los puertos de la aplicación. Esto permite conexiones desde cualquier IPv4. Para SSH y el acceso externo a MySQL, limite el origen al que realizará la conexión.

La comunicación del backend con MySQL ocurre dentro de `pmng-net`; no requiere abrir `3306` en el grupo de seguridad. Si crea la base mediante `docker exec`, tampoco necesita acceder a MySQL desde el IDE.

No es necesario abrir `8080` ni `80` públicamente: en esta práctica se accede a ellos mediante los puertos publicados `8089` y `5173`. Utilice `http://`; los contenedores no incluyen configuración HTTPS.

---

## 13. Errores Frecuentes

### `Unknown database 'people-dev'`

La base todavía no existe o se creó con otro nombre. Ejecute el SQL de la sección 7 y confirme que el nombre sea `people-dev`, con guion, como indica `db.name`.

### MySQL todavía no acepta conexiones

Revise `docker logs pmng-persistance` y espere a que el servidor termine de inicializarse. Si el backend salió por este motivo, inícielo de nuevo cuando MySQL esté listo:

```bash
docker start pmng-servicios
docker logs pmng-servicios
```

### No se resuelve `pmng-mysql`

```bash
docker network inspect pmng-net
```

Compruebe que MySQL y el backend pertenecen a esa red y que MySQL tiene el alias `pmng-mysql`.

### La página abre, pero no muestra ni guarda personas

Revise la dirección `URL` de `main.js`, el puerto público `8089`, el estado del backend y las solicitudes de la pestaña **Network**. Que Nginx entregue el HTML no demuestra que la API sea accesible.

### `port is already allocated`

Otro contenedor o proceso utiliza `3306`, `8089` o `5173`. Revise `docker ps -a` antes de repetir los comandos. Si cambia un puerto publicado, ajuste también la dirección del cliente o del IDE que lo utiliza.

### `The container name is already in use`

Los comandos `docker run` crean contenedores nuevos. Consulte `docker ps -a`: si el contenedor existente es el que necesita, utilice `docker start NOMBRE`. Si está activo, no necesita volver a crearlo. Para actualizar su imagen, debe reemplazarlo de forma deliberada.

### `Dockerfile: no such file or directory`

Ejecute cada construcción desde su carpeta: `pmng/service` para el backend y `pmng/client` para el cliente.

### Los nombres desaparecen al reiniciar el backend

Revise `spring.jpa.hibernate.ddl-auto=create`. La configuración fuente recrea las tablas al iniciar la aplicación; no es una prueba de persistencia entre reinicios.

### `ERR_SSL_PROTOCOL_ERROR`

Utilice `http://IP_PUBLICA_EC2:5173/` y `http://IP_PUBLICA_EC2:8089/people`, sin HTTPS.

---

## 14. Secuencia Completa

Esta secuencia supone un despliegue inicial, sin contenedores previos con los mismos nombres y con los puertos disponibles. Antes de construir el cliente, su `main.js` debe apuntar a la IP pública correcta.

### En CloudShell

```bash
chmod 400 certs/ajca-server-key.pem

scp -i certs/ajca-server-key.pem \
  pmng.zip \
  ubuntu@DNS_PUBLICO_EC2:/home/ubuntu/

ssh -i certs/ajca-server-key.pem ubuntu@DNS_PUBLICO_EC2
```

### Dentro de EC2

```bash
cd /home/ubuntu
unzip pmng.zip

docker network inspect pmng-net || \
  docker network create --driver bridge pmng-net

docker network ls

docker run -d -p 3306:3306 \
  -e MYSQL_ROOT_PASSWORD=root \
  --name pmng-persistance \
  --network pmng-net \
  --network-alias pmng-mysql \
  mysql:8.0

docker logs pmng-persistance
```

Espere a que MySQL acepte conexiones y cree la base:

```bash
docker exec -it pmng-persistance mysql -u root -p
```

Dentro del cliente MySQL:

```sql
CREATE DATABASE IF NOT EXISTS `people-dev`;
EXIT;
```

De vuelta en la terminal de EC2:

```bash
cd /home/ubuntu/pmng/service
docker build -t backend:v1.0 .
docker images

docker run -d -p 8089:8080 \
  --name pmng-servicios \
  --network pmng-net \
  --network-alias pmng-back \
  backend:v1.0

docker logs pmng-servicios
```

Confirme que el servicio haya iniciado y que `main.js` tenga la IP correcta. Después ejecute:

```bash
cd /home/ubuntu/pmng/client
docker build -t frontend:v1.0 .

docker run -d -p 5173:80 \
  --name pmng-cliente \
  --network pmng-net \
  frontend:v1.0

docker ps
docker network inspect pmng-net

curl -I http://localhost:5173/
curl -i http://localhost:8089/people
```

Finalmente, abra `http://IP_PUBLICA_EC2:5173/` y registre una persona desde la página.

---

## 15. Lista de Comprobación

- [ ] La instancia EC2 está encendida y la conexión SSH funciona.
- [ ] `pmng.zip` se descomprimió con las carpetas `service/` y `client/`.
- [ ] La red bridge `pmng-net` existe.
- [ ] MySQL está listo y tiene el alias `pmng-mysql`.
- [ ] La base `people-dev` se creó antes de iniciar el backend.
- [ ] La configuración fuente del backend coincide con el contenedor MySQL.
- [ ] La imagen `backend:v1.0` se construyó desde `pmng/service`.
- [ ] `pmng-servicios` publica `8089:8080` y tiene el alias `pmng-back`.
- [ ] `main.js` apunta a la IP pública correcta y al puerto `8089`.
- [ ] La imagen `frontend:v1.0` se construyó desde `pmng/client`.
- [ ] `pmng-cliente` publica `5173:80`.
- [ ] Los tres contenedores aparecen dentro de `pmng-net`.
- [ ] Los puertos `5173` y `8089` son accesibles desde el navegador.
- [ ] `GET /people` devuelve HTTP `200` y `POST /people` devuelve `201` al guardar.
- [ ] El nombre registrado aparece al actualizar la tabla.
- [ ] Se tuvo en cuenta que `ddl-auto=create` puede borrar datos al reiniciar el backend.

---

## Resultado Esperado

```text
Navegador → EC2:5173 → Nginx entrega la página
    │
    └── JavaScript → EC2:8089/people → Spring Boot
                                           │
                                           └── pmng-mysql:3306/people-dev
```

La página permite registrar nombres y listar los registros almacenados en MySQL mediante la API del backend.
