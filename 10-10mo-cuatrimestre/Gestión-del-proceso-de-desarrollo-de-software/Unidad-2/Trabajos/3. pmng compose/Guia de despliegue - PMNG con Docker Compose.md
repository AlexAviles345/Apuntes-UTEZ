# Práctica — PMNG con Docker Compose y MySQL Externo

Esta guía explica cómo se adaptó la aplicación de gestión de personas para levantar el backend y el frontend con Docker Compose, reutilizando el contenedor MySQL y la red bridge creados en la práctica anterior.

En este contexto, «externo» no significa que MySQL esté fuera de EC2. Significa que ese contenedor no pertenece al proyecto de Compose actual: ya existe y se administra por separado.

La instancia EC2 debe estar previamente creada y encendida.

---

## Tabla de Contenidos

1. [Objetivo](#1-objetivo)
2. [Qué Administra Compose](#2-qué-administra-compose)
3. [Arquitectura](#3-arquitectura)
4. [Recursos que Deben Existir](#4-recursos-que-deben-existir)
5. [Organización del Proyecto](#5-organización-del-proyecto)
6. [Flujo de las Variables](#6-flujo-de-las-variables)
7. [Explicación de docker-compose.yml](#7-explicación-de-docker-composeyml)
8. [Backend, Dockerfiles y Frontend](#8-backend-dockerfiles-y-frontend)
9. [Comprobar la Infraestructura Anterior](#9-comprobar-la-infraestructura-anterior)
10. [Enviar el Proyecto desde CloudShell](#10-enviar-el-proyecto-desde-cloudshell)
11. [Desplegar con Docker Compose](#11-desplegar-con-docker-compose)
12. [Comprobar y Probar la Aplicación](#12-comprobar-y-probar-la-aplicación)
13. [Reglas de Entrada](#13-reglas-de-entrada)
14. [Administrar el Despliegue](#14-administrar-el-despliegue)
15. [Errores Frecuentes](#15-errores-frecuentes)
16. [Secuencia Completa](#16-secuencia-completa)
17. [Lista de Comprobación](#17-lista-de-comprobación)

---

## 1. Objetivo

La actividad utiliza tres contenedores en total, pero Docker Compose solo crea dos:

| Componente | Contenedor | Imagen | Quién lo administra | Puerto EC2 → contenedor |
|---|---|---|---|---|
| MySQL | `pmng-persistance` | `mysql:8.0` | Práctica anterior / Docker manual | `3306:3306` |
| Backend | `pmng-servicios` | `backend:v1.0` | Docker Compose | `8089:8080` |
| Frontend | `pmng-cliente` | `frontend:v1.0` | Docker Compose | `5173:80` |

El propósito de `docker-compose.yml` es construir, conectar y levantar juntos el backend y el frontend, sin volver a crear la base de datos.

---

## 2. Qué Administra Compose

Compose administra:

- la construcción de `backend:v1.0` desde `service/`;
- la construcción de `frontend:v1.0` desde `client/`;
- los contenedores `pmng-servicios` y `pmng-cliente`;
- la conexión de ambos a la red externa `pmng-net`.

Compose no administra:

- el contenedor `pmng-persistance`;
- la imagen `mysql:8.0` usada para crearlo;
- la creación de `pmng-net`;
- la creación inicial de `people-dev`;
- el almacenamiento utilizado por el MySQL anterior.

Una imagen de MySQL por sí sola no ofrece una base de datos. Debe existir un contenedor en ejecución, conectado a `pmng-net` y accesible como `pmng-mysql`.

---

## 3. Arquitectura

```text
Navegador
    │
    ├── http://IP_PUBLICA_EC2:5173/
    │               ↓
    │       pmng-cliente / Nginx :80
    │
    └── main.js ejecutado en el navegador
              │
              └── GET / POST http://IP_PUBLICA_EC2:8089/people
                                      ↓
                         pmng-servicios :8080
                                      ↓
                     jdbc:mysql://pmng-mysql:3306/people-dev
                                      ↓
                    pmng-persistance / MySQL :3306

               Red bridge preexistente: pmng-net
```

El nombre `pmng-mysql` se resuelve solamente dentro de `pmng-net`. El backend lo utiliza para llegar a la base de datos.

El JavaScript se ejecuta en el navegador de la persona usuaria. Por eso utiliza la IP o DNS con que se abrió la página, no el nombre interno `pmng-back`.

---

## 4. Recursos que Deben Existir

La práctica anterior debió dejar preparada esta infraestructura:

```text
Red:         pmng-net
Contenedor:  pmng-persistance
Imagen:      mysql:8.0
Nombre DNS:  pmng-mysql
Puerto:      3306
Base:        people-dev
Usuario:     root
Contraseña:  root
```

El contenedor debió crearse con una configuración equivalente a:

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

Después se creó `people-dev`. Estos comandos se muestran para comprender la dependencia, no para repetirlos si el contenedor ya existe.

---

## 5. Organización del Proyecto

```text
3. pmng compose/
├── Guia de despliegue - PMNG con Docker Compose.md
└── pmng/
    ├── .env                     # configuración local ignorada por Git
    ├── .env.example             # plantilla versionable
    ├── docker-compose.yml       # backend, frontend y red externa
    ├── service/                 # Spring Boot y Dockerfile
    └── client/                  # HTML, JavaScript y Dockerfile de Nginx
```

Los comandos de Compose se ejecutan desde `pmng/`.

Para preparar una copia nueva sin publicar credenciales reales:

```bash
cp .env.example .env
```

---

## 6. Flujo de las Variables

```text
.env
  │ Compose sustituye ${ENV_*}
  ▼
docker-compose.yml
  │ entrega DC_* a pmng-servicios
  ▼
application.properties
  │ expone server.port y db.*
  ▼
DBConnection.java
  └── construye la URL JDBC
```

La plantilla [`.env.example`](pmng/.env.example) contiene:

```dotenv
ENV_SERVICE_PORT=8080
ENV_DB_HOST=pmng-mysql
ENV_DB_PORT=3306
ENV_DB_NAME=people-dev
ENV_DB_USER=root
ENV_DB_PASS=root
```

Compose traduce esas variables para el backend:

| `.env` | Variable dentro de `pmng-servicios` |
|---|---|
| `ENV_SERVICE_PORT` | `DC_SERVICE_PORT` |
| `ENV_DB_HOST` | `DC_DB_HOST` |
| `ENV_DB_PORT` | `DC_DB_PORT` |
| `ENV_DB_NAME` | `DC_DB_NAME` |
| `ENV_DB_USER` | `DC_DB_USER` |
| `ENV_DB_PASS` | `DC_DB_PASS` |

[`application.properties`](pmng/service/src/main/resources/application.properties) utiliza valores predeterminados:

```properties
server.port=${DC_SERVICE_PORT:8080}
db.host=${DC_DB_HOST:pmng-mysql}
db.port=${DC_DB_PORT:3306}
db.name=${DC_DB_NAME:people-dev}
db.user=${DC_DB_USER:root}
db.pass=${DC_DB_PASS:root}
```

`DBConnection.java` termina construyendo:

```text
jdbc:mysql://pmng-mysql:3306/people-dev
```

---

## 7. Explicación de `docker-compose.yml`

### `pmng-back`

- construye `backend:v1.0` desde `./service`;
- crea `pmng-servicios`;
- entrega las variables `DC_*`;
- publica `8089` hacia el puerto `8080` del backend;
- conecta el contenedor a `pmng-net`.

No utiliza `depends_on`, porque el MySQL externo no es un servicio definido en este Compose. La disponibilidad de la base se comprueba antes de ejecutar `up`.

### `pmng-front`

- construye `frontend:v1.0` desde `./client`;
- crea `pmng-cliente`;
- publica `5173` hacia el puerto `80` de Nginx;
- lo conecta a `pmng-net`.

La carpeta correcta es `client`, no `cliente`.

### `pmng-net`

```yaml
networks:
  pmng-net:
    external: true
```

`external: true` indica que Compose no debe crear ni eliminar la red. Si `pmng-net` no existe, `docker compose up` falla deliberadamente.

---

## 8. Backend, Dockerfiles y Frontend

El backend publica:

| Método | Ruta | Función |
|---|---|---|
| `GET` | `/people` | Lista las personas |
| `POST` | `/people` | Guarda una persona |

[`service/Dockerfile`](pmng/service/Dockerfile) utiliza dos etapas: Maven con Java 21 compila el JAR y una imagen JRE ejecuta el resultado.

[`client/Dockerfile`](pmng/client/Dockerfile) utiliza `nginx:alpine` y copia los archivos estáticos a `/usr/share/nginx/html`.

[`client/main.js`](pmng/client/main.js) obtiene el host actual:

```javascript
const URL = `http://${window.location.hostname}:8089`;
```

Por eso funciona con `localhost`, con la IP pública o con el DNS actual de EC2, sin dejar una IP antigua escrita en la imagen.

`spring.jpa.hibernate.ddl-auto=create` permanece en el backend. Puede recrear la tabla al reiniciar Spring Boot aunque el contenedor MySQL continúe existiendo.

---

## 9. Comprobar la Infraestructura Anterior

Antes de ejecutar Compose dentro de EC2, compruebe la red:

```bash
docker network inspect pmng-net
```

Compruebe el contenedor MySQL:

```bash
docker ps -a --filter name=pmng-persistance
```

Si existe pero está detenido:

```bash
docker start pmng-persistance
```

Verifique que MySQL responda:

```bash
docker exec pmng-persistance \
  mysqladmin ping -h localhost -u root -proot
```

La respuesta esperada es:

```text
mysqld is alive
```

Compruebe que MySQL está conectado a la red y tiene el alias `pmng-mysql`:

```bash
docker network inspect pmng-net
```

En la información de `pmng-persistance` debe aparecer `pmng-mysql` dentro de `Aliases`.

Si el contenedor existe pero no pertenece a la red, puede conectarse sin recrearlo:

```bash
docker network connect \
  --alias pmng-mysql \
  pmng-net pmng-persistance
```

También debe existir la base `people-dev`. Puede comprobarse con:

```bash
docker exec pmng-persistance \
  mysql -u root -proot \
  -e "SHOW DATABASES LIKE 'people-dev';"
```

---

## 10. Enviar el Proyecto desde CloudShell

Durante la actividad se utilizó `pmng-3.zip`. Compruebe el ZIP y proteja la llave:

```bash
ls -lh pmng-3.zip
chmod 400 certs/ajca-server-key.pem
```

Transfiera el proyecto:

```bash
scp -i certs/ajca-server-key.pem \
  pmng-3.zip \
  ubuntu@DNS_PUBLICO_EC2:/home/ubuntu/
```

Conéctese:

```bash
ssh -i certs/ajca-server-key.pem ubuntu@DNS_PUBLICO_EC2
```

El despliegue registrado utilizó temporalmente `ec2-18-232-88-20.compute-1.amazonaws.com`, pero el DNS debe comprobarse cada vez que se reinicia la instancia.

---

## 11. Desplegar con Docker Compose

Dentro de EC2:

```bash
cd /home/ubuntu
unzip pmng-3.zip
cd /home/ubuntu/pmng
ls -la
```

La carpeta debe contener `.env`, `docker-compose.yml`, `service/` y `client/`.

Si todavía existen versiones anteriores del backend y el frontend creadas con `docker run`, retírelas para liberar nombres y puertos:

```bash
docker rm -f pmng-servicios pmng-cliente
```

No elimine `pmng-persistance` ni `pmng-net`, porque son las dependencias externas que esta práctica reutiliza.

Valide y construya:

```bash
docker compose config
docker compose build
```

Levante los dos servicios:

```bash
docker compose up -d
```

Si la instalación de Docker requiere privilegios, anteponga `sudo` a los comandos.

---

## 12. Comprobar y Probar la Aplicación

`docker compose ps` muestra solamente los dos servicios que pertenecen a este proyecto:

```bash
docker compose ps
```

Resultado esperado:

```text
pmng-servicios   Up   0.0.0.0:8089->8080/tcp
pmng-cliente     Up   0.0.0.0:5173->80/tcp
```

`docker ps` permite comprobar los tres contenedores, incluido el MySQL externo:

```bash
docker ps
```

```text
pmng-persistance   Up   0.0.0.0:3306->3306/tcp
pmng-servicios     Up   0.0.0.0:8089->8080/tcp
pmng-cliente       Up   0.0.0.0:5173->80/tcp
```

Revise los logs administrados por Compose:

```bash
docker compose logs pmng-back
docker compose logs pmng-front
```

Los logs de MySQL se consultan directamente porque no pertenece al Compose:

```bash
docker logs pmng-persistance
```

Pruebe desde EC2:

```bash
curl -I http://localhost:5173/
curl -i http://localhost:8089/people
```

La API debe responder HTTP `200` con una estructura como:

```json
{
  "data": [],
  "error": false,
  "message": "Operación exitosa",
  "status": "200 OK"
}
```

Para guardar una persona:

```bash
curl -i -X POST http://localhost:8089/people \
  -H 'Content-Type: application/json' \
  -d '{"name":"Alexandro"}'
```

Desde el navegador abra:

```text
http://IP_PUBLICA_EC2:5173/
```

El JavaScript consultará automáticamente:

```text
http://IP_PUBLICA_EC2:8089/people
```

---

## 13. Reglas de Entrada

| Puerto | Uso | Cuándo abrirlo |
|---:|---|---|
| `22` | SSH | Desde el origen administrativo |
| `5173` | Página web | Para acceder al frontend |
| `8089` | API | Para las peticiones del navegador |
| `3306` | MySQL | Solo si se utilizará un cliente externo |

La comunicación entre Spring Boot y MySQL ocurre dentro de `pmng-net`; no necesita una regla pública para `3306`.

La aplicación utiliza HTTP:

```text
http://IP_PUBLICA_EC2:5173/
http://IP_PUBLICA_EC2:8089/people
```

---

## 14. Administrar el Despliegue

Desde `/home/ubuntu/pmng`:

```bash
docker compose ps
docker compose restart
docker compose up -d --build
docker compose down
```

`docker compose down` elimina `pmng-servicios` y `pmng-cliente`, pero conserva `pmng-net` y `pmng-persistance` porque son externos al proyecto.

Para detener o iniciar MySQL se utilizan comandos de Docker independientes:

```bash
docker stop pmng-persistance
docker start pmng-persistance
```

No debe retirarse el contenedor MySQL si sus datos todavía se necesitan.

---

## 15. Errores Frecuentes

### `network pmng-net declared as external, but could not be found`

La red de la práctica anterior no existe:

```bash
docker network ls
docker network inspect pmng-net
```

Recupere o cree la red y asegúrese de conectar MySQL con el alias `pmng-mysql` antes de ejecutar Compose.

### `UnknownHostException: pmng-mysql`

El backend no puede resolver MySQL. Compruebe que ambos contenedores pertenecen a `pmng-net` y que `pmng-persistance` tenga el alias `pmng-mysql`.

### `Connection refused` hacia MySQL

El contenedor existe, pero puede estar detenido o todavía inicializándose:

```bash
docker start pmng-persistance
docker logs pmng-persistance
docker exec pmng-persistance mysqladmin ping -h localhost -u root -proot
```

Después reinicie el backend:

```bash
docker compose restart pmng-back
```

### `unable to prepare context` o no existe `./cliente`

El directorio se llama `client`. El contexto correcto es `./client`.

### Variables vacías

```bash
ls -la .env
docker compose config
```

El `.env` define `ENV_*`; Compose las convierte en `DC_*` para Spring Boot.

### La página abre, pero no consulta la API

Compruebe el puerto `8089`, el backend y las solicitudes de la pestaña **Network** del navegador. `main.js` debe utilizar `window.location.hostname`.

### `port is already allocated`

Una versión anterior utiliza `5173` o `8089`:

```bash
docker ps -a
```

Retire únicamente los contenedores antiguos del frontend o backend. No elimine MySQL para resolver un conflicto de esos puertos.

### Los datos desaparecen al reiniciar el backend

MySQL puede seguir intacto, pero `spring.jpa.hibernate.ddl-auto=create` recrea la tabla cuando inicia Spring Boot. Esta es una característica de la configuración actual, no de Compose.

---

## 16. Secuencia Completa

### En CloudShell

```bash
chmod 400 certs/ajca-server-key.pem

scp -i certs/ajca-server-key.pem \
  pmng-3.zip \
  ubuntu@DNS_PUBLICO_EC2:/home/ubuntu/

ssh -i certs/ajca-server-key.pem ubuntu@DNS_PUBLICO_EC2
```

### Dentro de EC2

Compruebe primero las dependencias externas:

```bash
docker network inspect pmng-net
docker start pmng-persistance

docker exec pmng-persistance \
  mysqladmin ping -h localhost -u root -proot

docker network inspect pmng-net
```

Prepare el proyecto:

```bash
cd /home/ubuntu
unzip pmng-3.zip
cd /home/ubuntu/pmng

ls -la
docker compose config
```

Si quedaron contenedores anteriores del backend y frontend:

```bash
docker rm -f pmng-servicios pmng-cliente
```

Construya y levante:

```bash
docker compose build
docker compose up -d
```

Compruebe los dos servicios de Compose y los tres contenedores totales:

```bash
docker compose ps
docker ps
docker network inspect pmng-net

curl -I http://localhost:5173/
curl -i http://localhost:8089/people
```

Finalmente, abra `http://IP_PUBLICA_EC2:5173/`.

---

## 17. Lista de Comprobación

- [ ] La instancia EC2 está encendida y se conoce su DNS o IP actual.
- [ ] La red externa `pmng-net` ya existe.
- [ ] `pmng-persistance` ya existe y está activo.
- [ ] MySQL responde a `mysqladmin ping`.
- [ ] MySQL está conectado a `pmng-net` con el alias `pmng-mysql`.
- [ ] La base `people-dev` existe.
- [ ] La carpeta `pmng/` contiene `.env`, `docker-compose.yml`, `service/` y `client/`.
- [ ] `.env` define las seis variables `ENV_*`.
- [ ] `docker compose config` no muestra variables vacías.
- [ ] El contexto del backend es `./service`.
- [ ] El contexto del frontend es `./client`.
- [ ] La red se declara con `external: true`.
- [ ] Compose no intenta crear ni borrar MySQL.
- [ ] `application.properties` lee las variables `DC_*`.
- [ ] El backend utiliza `pmng-mysql:3306/people-dev`.
- [ ] `main.js` utiliza `window.location.hostname`.
- [ ] `pmng-servicios` publica `8089:8080`.
- [ ] `pmng-cliente` publica `5173:80`.
- [ ] `docker compose ps` muestra backend y frontend.
- [ ] `docker ps` muestra también `pmng-persistance`.
- [ ] El frontend y `GET /people` responden HTTP `200`.
- [ ] Se tuvo en cuenta el comportamiento de `ddl-auto=create`.

---

## Resultado Esperado

```text
Recurso preexistente
pmng-persistance / pmng-mysql
               ▲
               │ pmng-net externa
               │
docker compose up -d
        ├── pmng-servicios
        └── pmng-cliente

Navegador :5173 → Nginx → JavaScript :8089 → Spring Boot → MySQL
```

Compose simplifica la administración del backend y del frontend, mientras la base de datos continúa siendo el contenedor persistente preparado en la práctica anterior.
