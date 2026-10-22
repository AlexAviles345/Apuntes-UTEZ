# Práctica — Backends Conectados con Docker en AWS EC2

Esta guía explica cómo se desplegaron dos backends de Spring Boot en una instancia de Amazon EC2. Los proyectos se transfirieron desde AWS CloudShell, se construyeron como imágenes de Docker y se ejecutaron como contenedores conectados mediante la red bridge `test-net`.

La actividad comienza con una instancia EC2 previamente creada y encendida. La creación de la instancia no forma parte de este procedimiento.

---

## Tabla de Contenidos

1. [Objetivo](#1-objetivo)
2. [Arquitectura](#2-arquitectura)
3. [Requisitos Previos](#3-requisitos-previos)
4. [Enviar los Proyectos desde CloudShell](#4-enviar-los-proyectos-desde-cloudshell)
5. [Conectarse y Descomprimir](#5-conectarse-y-descomprimir)
6. [Comprobar o Crear test-net](#6-comprobar-o-crear-test-net)
7. [Construir las Imágenes](#7-construir-las-imágenes)
8. [Levantar los Contenedores](#8-levantar-los-contenedores)
9. [Comprobar el Despliegue](#9-comprobar-el-despliegue)
10. [Probar los Endpoints](#10-probar-los-endpoints)
11. [Reglas de Entrada](#11-reglas-de-entrada)
12. [Errores Frecuentes](#12-errores-frecuentes)
13. [Secuencia Completa](#13-secuencia-completa)
14. [Lista de Comprobación](#14-lista-de-comprobación)

---

## 1. Objetivo

La práctica ejecuta dos aplicaciones independientes y permite que se consulten mutuamente:

- `backend1` se publica en el puerto `8081` de EC2.
- `backend2` se publica en el puerto `8082` de EC2.
- Ambos escuchan en el puerto `8080` dentro de sus contenedores.
- Los contenedores pertenecen a la red bridge `test-net`.
- `backend1` utiliza el alias interno `back1`.
- `backend2` utiliza el alias interno `back2`.

La comunicación interna se realiza mediante:

```text
backend1 → http://back2:8080/test/retrieve
backend2 → http://back1:8080/test/retrieve
```

---

## 2. Arquitectura

```text
Postman / navegador
        │
        ├── http://IP_PUBLICA:8081/test
        │              ↓
        │       backend1 / back1
        │              ↓
        │  http://back2:8080/test/retrieve
        │              ↓
        │       backend2 / back2
        │
        └── http://IP_PUBLICA:8082/test
                       ↓
                backend2 / back2
                       ↓
           http://back1:8080/test/retrieve
                       ↓
                backend1 / back1

          Red bridge compartida: test-net
```

![Diagrama original de la comunicación entre backends](imagenes/arquitectura-backends.webp)

> **Nota:** la red bridge usada en la práctica se llama `test-net`, tal como aparece en el diagrama.

| Puerto | Función |
|---|---|
| `8080` | Puerto interno de cada aplicación Spring Boot |
| `8081` | Acceso externo a `backend1` |
| `8082` | Acceso externo a `backend2` |

Los proyectos tienen estas direcciones en `application.properties`:

```properties
# backend 1
api.base.url=http://back2:8080

# backend 2
api.base.url=http://back1:8080
```

Por eso los alias de Docker deben llamarse exactamente `back1` y `back2`.

---

## 3. Requisitos Previos

Antes de iniciar se necesita:

- Una instancia EC2 previamente creada y encendida.
- Su IP pública o DNS público.
- Una llave privada `.pem` autorizada.
- Docker instalado y activo en EC2.
- `unzip` disponible en EC2.
- Los archivos `backend.zip` y `backend2.zip`.
- Acceso a AWS CloudShell.
- Reglas de entrada para `22`, `8081` y `8082`.
- La red bridge `test-net` creada previamente.

Si `test-net` no existe, se creará durante el procedimiento.

### Organización dentro del repositorio

Los dos proyectos fuente están agrupados en la carpeta [`backends/`](backends/), separados de las imágenes y de los documentos de apoyo:

```text
conexion-de-backends-por-nombre-de-servicio-alias/
├── backends/
│   ├── backend/
│   └── backend2/
├── imagenes/
├── Comandos ocupados.odt
├── Comandos ocupados.pdf
└── Guia de despliegue - Backends conectados.md
```

- [`backends/backend/`](backends/backend/) contiene el proyecto del backend 1.
- [`backends/backend2/`](backends/backend2/) contiene el proyecto del backend 2.

Esta organización solamente afecta al repositorio. Al comprimir y descomprimir los proyectos para la práctica, las carpetas resultantes en EC2 continúan siendo `/home/ubuntu/backend` y `/home/ubuntu/backend2`.

---

## 4. Enviar los Proyectos desde CloudShell

Abra AWS CloudShell y cargue `backend.zip`, `backend2.zip` y la llave privada si todavía no está disponible. Compruebe los archivos:

```bash
ls -lh
ls -lh certs
```

Restrinja los permisos de la llave:

```bash
chmod 400 certs/ajca-server-key.pem
```

Transfiera ambos proyectos a `/home/ubuntu`:

```bash
scp -i certs/ajca-server-key.pem \
  backend.zip backend2.zip \
  ubuntu@DNS_PUBLICO_EC2:/home/ubuntu/
```

Sustituya `ajca-server-key.pem` y `DNS_PUBLICO_EC2` por los datos reales de la instancia.

---

## 5. Conectarse y Descomprimir

Conéctese desde CloudShell:

```bash
ssh -i certs/ajca-server-key.pem ubuntu@DNS_PUBLICO_EC2
```

Compruebe Docker y los ZIP:

```bash
docker --version
docker ps
cd /home/ubuntu
ls -lh
```

Descomprima los proyectos:

```bash
unzip backend.zip
unzip backend2.zip
```

El resultado esperado es:

```text
/home/ubuntu/backend/
/home/ubuntu/backend2/
```

Cada `docker build` debe ejecutarse dentro de la carpeta que contiene su `Dockerfile`.

---

## 6. Comprobar o Crear test-net

La red bridge `test-net` ya debía existir antes de levantar los contenedores. Compruébelo con:

```bash
docker network inspect test-net
```

Si Docker muestra su configuración, no debe volver a crearla.

Si aparece `network test-net not found`, créela con:

```bash
docker network create --driver bridge test-net
```

Compruebe el resultado:

```bash
docker network ls
```

Debe aparecer una entrada similar a:

```text
NETWORK ID     NAME       DRIVER    SCOPE
...            test-net   bridge    local
```

`test-net` debe existir antes de ejecutar cualquier comando que contenga `--network test-net`.

---

## 7. Construir las Imágenes

Construya la primera imagen desde su carpeta:

```bash
cd /home/ubuntu/backend
docker build -t back:v1.1 .
```

Construya la segunda imagen:

```bash
cd /home/ubuntu/backend2
docker build -t back:v1.2 .
```

Compruebe las imágenes:

```bash
docker images
```

Resultado esperado:

```text
REPOSITORY   TAG
back         v1.1
back         v1.2
```

![Imágenes Docker construidas](imagenes/docker-images.webp)

Cada Dockerfile compila el proyecto con Maven y ejecuta el JAR mediante `java -jar app.jar`.

---

## 8. Levantar los Contenedores

### Backend 1

```bash
docker run -d \
  -p 8081:8080 \
  --name backend1 \
  --network test-net \
  --network-alias back1 \
  back:v1.1
```

### Backend 2

```bash
docker run -d \
  -p 8082:8080 \
  --name backend2 \
  --network test-net \
  --network-alias back2 \
  back:v1.2
```

| Parámetro | Función |
|---|---|
| `-d` | Ejecuta el contenedor en segundo plano |
| `-p 8081:8080` | Publica el backend 1 en `8081` |
| `-p 8082:8080` | Publica el backend 2 en `8082` |
| `--name` | Asigna el nombre administrativo |
| `--network test-net` | Conecta el contenedor a la red compartida |
| `--network-alias back1` | Registra el nombre interno del backend 1 |
| `--network-alias back2` | Registra el nombre interno del backend 2 |

```text
Contenedor backend1 → alias back1
Contenedor backend2 → alias back2
```

---

## 9. Comprobar el Despliegue

Revise los contenedores activos:

```bash
docker ps
```

Debe observar:

```text
NAMES       PORTS
backend1    0.0.0.0:8081->8080/tcp
backend2    0.0.0.0:8082->8080/tcp
```

![Contenedores backend1 y backend2 activos](imagenes/docker-ps-backends.webp)

Compruebe que ambos pertenecen a `test-net`:

```bash
docker network inspect test-net
```

En la sección `Containers` deben aparecer `backend1` y `backend2`.

Si alguno no está activo:

```bash
docker ps -a
docker logs backend1
docker logs backend2
```

---

## 10. Probar los Endpoints

Pruebe primero las respuestas directas:

```bash
curl http://localhost:8081/test/retrieve
curl http://localhost:8082/test/retrieve
```

Deben incluir `Hola desde backend 1` y `Hola desde backend 2`.

Después pruebe la comunicación cruzada:

```bash
curl http://localhost:8081/test
```

Entra por `backend1`, pero debe responder `Hola desde backend 2`.

```bash
curl http://localhost:8082/test
```

Entra por `backend2`, pero debe responder `Hola desde backend 1`.

Desde Postman o un navegador use:

```text
http://IP_PUBLICA_EC2:8081/test
http://IP_PUBLICA_EC2:8082/test
```

Debe escribirse `http://` explícitamente. Estos backends no tienen certificado ni configuración HTTPS.

---

## 11. Reglas de Entrada

El grupo de seguridad de EC2 debe permitir:

| Tipo | Puerto | Uso |
|---|---:|---|
| SSH | `22` | Conexión administrativa |
| TCP personalizado | `8081` | Acceso al backend 1 |
| TCP personalizado | `8082` | Acceso al backend 2 |

![Reglas de entrada para los puertos 8081 y 8082](imagenes/reglas-entrada-ec2.webp)

Durante una práctica controlada se puede utilizar `0.0.0.0/0` para `8081` y `8082`, aunque esto permite conexiones desde cualquier IPv4. En un entorno real se debe limitar el origen.

No es necesario abrir públicamente `8080`: es un puerto interno de los contenedores.

---

## 12. Errores Frecuentes

### `network test-net not found`

```bash
docker network create --driver bridge test-net
```

### `Dockerfile: no such file or directory`

Se ejecutó la construcción desde una carpeta incorrecta. Entre a `/home/ubuntu/backend` o `/home/ubuntu/backend2` antes de construir.

### `The container name is already in use`

```bash
docker ps -a
```

Si se repetirá la práctica desde cero y los anteriores ya no se necesitan:

```bash
docker rm -f backend1 backend2
```

### `port is already allocated`

Otro proceso o contenedor utiliza `8081` o `8082`. Revise `docker ps -a`.

### No se puede resolver `back1` o `back2`

```bash
docker ps
docker network inspect test-net
```

Compruebe que ambos contenedores estén activos, conectados a `test-net` y tengan sus alias.

### `ERR_SSL_PROTOCOL_ERROR`

Se intentó utilizar HTTPS. La forma correcta es:

```text
http://IP_PUBLICA_EC2:8081/test
```

---

## 13. Secuencia Completa

### En CloudShell

```bash
chmod 400 certs/ajca-server-key.pem

scp -i certs/ajca-server-key.pem \
  backend.zip backend2.zip \
  ubuntu@DNS_PUBLICO_EC2:/home/ubuntu/

ssh -i certs/ajca-server-key.pem ubuntu@DNS_PUBLICO_EC2
```

### Dentro de EC2

```bash
cd /home/ubuntu

unzip backend.zip
unzip backend2.zip

# test-net debía existir previamente. Si no existe, se crea.
docker network inspect test-net || \
  docker network create --driver bridge test-net

cd /home/ubuntu/backend
docker build -t back:v1.1 .

cd /home/ubuntu/backend2
docker build -t back:v1.2 .

docker images

docker run -d -p 8081:8080 \
  --name backend1 \
  --network test-net \
  --network-alias back1 \
  back:v1.1

docker run -d -p 8082:8080 \
  --name backend2 \
  --network test-net \
  --network-alias back2 \
  back:v1.2

docker ps
docker network inspect test-net

curl http://localhost:8081/test/retrieve
curl http://localhost:8082/test/retrieve
curl http://localhost:8081/test
curl http://localhost:8082/test
```

---

## 14. Lista de Comprobación

- [ ] La instancia EC2 está encendida.
- [ ] La conexión SSH funciona.
- [ ] Los ZIP están en `/home/ubuntu`.
- [ ] `backend` y `backend2` fueron descomprimidos.
- [ ] Docker está activo.
- [ ] La red bridge `test-net` existe.
- [ ] `back:v1.1` se construyó desde `backend`.
- [ ] `back:v1.2` se construyó desde `backend2`.
- [ ] `backend1` pertenece a `test-net` y tiene el alias `back1`.
- [ ] `backend2` pertenece a `test-net` y tiene el alias `back2`.
- [ ] `8081` apunta al `8080` de `backend1`.
- [ ] `8082` apunta al `8080` de `backend2`.
- [ ] `/test/retrieve` responde en ambos backends.
- [ ] `/test` demuestra la comunicación en ambas direcciones.
- [ ] Las pruebas externas utilizan `http://`.

---

## Resultado Esperado

```text
backend1 / back1 ←──── test-net ───→ backend2 / back2
       :8080                              :8080
          │                                  │
        :8081                              :8082
          │                                  │
          └──────── acceso externo ──────────┘
```

`/test/retrieve` identifica directamente a cada backend y `/test` comprueba que un servicio puede consultar al otro.

