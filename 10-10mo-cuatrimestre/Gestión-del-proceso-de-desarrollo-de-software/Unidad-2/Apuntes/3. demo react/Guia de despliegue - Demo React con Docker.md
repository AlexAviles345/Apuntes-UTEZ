# Guía de Despliegue — Demo React con Docker en AWS EC2

Esta guía se concentra exclusivamente en preparar, transferir, construir y publicar la aplicación `front` mediante Docker y Nginx.

Para estudiar el código, los componentes, el estado y los eventos, consulta [Demo React — Explicación de React y Vite](Demo%20React%20-%20Explicación%20de%20React%20y%20Vite.md).

Los comandos se basan en [demo-react.docx](demo-react.docx). El documento original no contiene capturas; registra `scp`, descompresión, `docker build` y `docker run`.

---

## Tabla de Contenidos

1. [Objetivo del Despliegue](#1-objetivo-del-despliegue)
2. [Arquitectura de Construcción](#2-arquitectura-de-construcción)
3. [Archivos de Despliegue](#3-archivos-de-despliegue)
4. [Dockerfile Multi-stage](#4-dockerfile-multi-stage)
5. [Excluir node_modules](#5-excluir-node_modules)
6. [Preparar el ZIP](#6-preparar-el-zip)
7. [Preparar EC2 y el Puerto 3001](#7-preparar-ec2-y-el-puerto-3001)
8. [Enviar el ZIP desde CloudShell](#8-enviar-el-zip-desde-cloudshell)
9. [Construir la Imagen](#9-construir-la-imagen)
10. [Levantar y Comprobar el Contenedor](#10-levantar-y-comprobar-el-contenedor)
11. [Actualizar el Despliegue](#11-actualizar-el-despliegue)
12. [Errores Frecuentes](#12-errores-frecuentes)
13. [Secuencia Completa](#13-secuencia-completa)
14. [Lista de Comprobación](#14-lista-de-comprobación)

---

## 1. Objetivo del Despliegue

| Elemento | Valor |
|---|---|
| Carpeta enviada | `front/` |
| Imagen creada | `demo:latest` |
| Contenedor | `front` |
| Servidor final | Nginx |
| Puerto del contenedor | `80` |
| Puerto de EC2 | `3001` |

La página queda disponible en:

```text
http://IP_PUBLICA_EC2:3001/
```

---

## 2. Arquitectura de Construcción

```text
Código fuente y package-lock.json
                 │
                 ▼
         Node.js ejecuta npm ci
         y npm run build
                 │
                 ▼
              dist/
                 │
                 ▼
       Nginx sirve archivos en :80
                 │
                 ▼
       Docker publica 3001:80
                 │
                 ▼
        Navegador externo
```

Node.js solo pertenece a la etapa de compilación. La imagen final ejecuta Nginx y contiene los archivos generados en `dist/`.

---

## 3. Archivos de Despliegue

```text
4. demo react/
├── demo-react.docx
├── Demo React - Explicación de React y Vite.md
├── Guia de despliegue - Demo React con Docker.md
└── front/
    ├── .dockerignore
    ├── .gitignore
    ├── Dockerfile
    ├── package.json
    ├── package-lock.json
    ├── public/
    └── src/
```

`package.json`, `package-lock.json`, `public/` y `src/` son entradas de la construcción. `node_modules/` y `dist/` son resultados locales y deben excluirse.

---

## 4. Dockerfile Multi-stage

[`front/Dockerfile`](front/Dockerfile) utiliza dos etapas.

### Construcción

```dockerfile
FROM node:24.22.1-alpine AS build

WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build
```

`npm ci` instala las versiones del lockfile y `npm run build` genera `/app/dist`.

### Ejecución

```dockerfile
FROM nginx:alpine AS runtime

COPY --from=build /app/dist /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

La imagen final no conserva Node.js, npm, JSX ni `node_modules`; solamente Nginx y los archivos estáticos.

---

## 5. Excluir `node_modules`

El ZIP no debe contener `node_modules/`.

```text
RUN npm ci
    └── instala dependencias Linux en /app/node_modules

COPY . .
    └── podría copiar node_modules del equipo local

RUN npm run build
    └── puede fallar por dependencias o binarios incompatibles
```

También puede fallar antes, mientras Docker empaqueta o envía el contexto, por el tamaño y la cantidad de archivos.

`.gitignore` solamente protege Git. Docker utiliza [`front/.dockerignore`](front/.dockerignore):

```text
node_modules
dist
.git
.gitignore
.vscode
.idea
*.log
npm-debug.log*
```

El ZIP debe excluir esas carpetas aunque exista `.dockerignore`, porque enviarlas a CloudShell y descomprimirlas seguiría siendo innecesario.

---

## 6. Preparar el ZIP

Ejecute el comando desde la carpeta que contiene `front/`.

### PowerShell

```powershell
tar -a -c -f front.zip `
  --exclude=front/node_modules `
  --exclude=front/dist `
  --exclude=front/.git `
  front
```

### Linux, Git Bash o CloudShell

```bash
zip -r front.zip front \
  -x "front/node_modules/*" \
     "front/dist/*" \
     "front/.git/*"
```

Compruebe que no se incluyeron carpetas generadas.

PowerShell:

```powershell
tar -tf front.zip | Select-String "node_modules|dist"
```

Linux o CloudShell:

```bash
unzip -l front.zip | grep -E 'node_modules|/dist/'
```

La búsqueda no debe mostrar archivos. El ZIP sí debe contener:

```text
front/Dockerfile
front/.dockerignore
front/package.json
front/package-lock.json
front/src/
```

---

## 7. Preparar EC2 y el Puerto 3001

Se necesita:

- una instancia EC2 encendida;
- su IP o DNS público actual;
- una llave `.pem` autorizada;
- Docker instalado y activo;
- `unzip` disponible;
- el ZIP sin `node_modules`;
- el puerto `3001` abierto en el grupo de seguridad.

### Regla obligatoria

| Tipo | Protocolo | Puerto | Origen |
|---|---|---:|---|
| TCP personalizado | TCP | `3001` | `0.0.0.0/0` |

`0.0.0.0/0` corresponde a **Anywhere-IPv4** y habilita el puerto para todas las conexiones IPv4, como requiere la actividad. Si se necesita IPv6, agregue otra regla con `::/0`.

En producción se recomienda limitar el origen o utilizar un proxy con HTTPS. La regla SSH del puerto `22` también debe limitarse cuando sea posible.

No se abre directamente el puerto `80`; Docker lo expone mediante `3001`.

### Node.js en EC2

El DOCX registra un comando parecido a:

```bash
sudo apt install -y nodejs npm
```

No es necesario instalar Node.js en EC2 para este Dockerfile: la imagen `node:24.22.1-alpine` ya contiene Node y npm. Solo Docker debe estar instalado en el host.

---

## 8. Enviar el ZIP desde CloudShell

Suba `front.zip` a CloudShell y compruébelo:

```bash
ls -lh front.zip
unzip -l front.zip | grep -E 'node_modules|/dist/'
chmod 400 certs/ajca-server-key.pem
```

El comando del DOCX debe contener un espacio entre la llave y el ZIP:

```bash
scp -i certs/ajca-server-key.pem \
  front.zip \
  ubuntu@DNS_PUBLICO_EC2:/home/ubuntu/
```

El documento utilizó temporalmente `ec2-34-238-248-21.compute-1.amazonaws.com`. Consulte EC2 y utilice el DNS actual.

Conéctese:

```bash
ssh -i certs/ajca-server-key.pem ubuntu@DNS_PUBLICO_EC2
```

---

## 9. Construir la Imagen

Dentro de EC2:

```bash
cd /home/ubuntu
unzip front.zip
cd front

ls -la
ls -lh Dockerfile package.json package-lock.json
```

No debe aparecer `node_modules/`.

Construya:

```bash
docker build -t demo:latest .
```

El punto final selecciona `front/` como contexto. Durante el build deben completarse `npm ci`, `npm run build` y la copia de `dist` a Nginx.

Compruebe la imagen:

```bash
docker images demo
```

---

## 10. Levantar y Comprobar el Contenedor

Ejecute el comando del DOCX:

```bash
docker run -d \
  -p 3001:80 \
  --name front \
  demo:latest
```

| Parte | Función |
|---|---|
| `-d` | Ejecuta el contenedor en segundo plano |
| `-p 3001:80` | Publica Nginx en el puerto `3001` de EC2 |
| `--name front` | Asigna el nombre del contenedor |
| `demo:latest` | Usa la imagen construida |

Compruebe:

```bash
docker ps
docker logs front
curl -I http://localhost:3001/
```

Debe aparecer:

```text
front   0.0.0.0:3001->80/tcp
```

Nginx debe responder HTTP `200`. Después abra:

```text
http://IP_PUBLICA_EC2:3001/
```

Si `curl` funciona dentro de EC2 pero el navegador externo no conecta, revise la regla TCP `3001` con origen `0.0.0.0/0`.

---

## 11. Actualizar el Despliegue

Después de modificar el código se necesita construir una imagen nueva y reemplazar el contenedor:

```bash
cd /home/ubuntu/front
docker build -t demo:latest .
docker rm -f front
docker run -d -p 3001:80 --name front demo:latest
```

Compruebe nuevamente:

```bash
docker ps
curl -I http://localhost:3001/
```

---

## 12. Errores Frecuentes

### El build tarda demasiado o falla después de `COPY . .`

Busque una copia accidental de las dependencias:

```bash
find . -maxdepth 2 -type d -name node_modules
```

Prepare nuevamente el ZIP sin `node_modules`. El fallo puede ocurrir al enviar el contexto o durante `RUN npm run build`.

### `npm ci` indica que el lockfile no coincide

Actualice `package-lock.json` en el entorno de desarrollo mediante `npm install`, compruebe el proyecto y genere un ZIP nuevo.

### No existe `/app/dist`

Revise la salida anterior de `npm run build`. La etapa de Nginx solo puede copiar `dist` cuando Vite termina correctamente.

### `Dockerfile: no such file or directory`

```bash
cd /home/ubuntu/front
docker build -t demo:latest .
```

### El nombre `front` ya está en uso

```bash
docker ps -a --filter name=front
docker rm -f front
```

Elimine el contenedor solamente cuando deba reemplazarse.

### `port is already allocated`

Otro contenedor utiliza `3001`. Revise `docker ps -a` y libere el puerto correspondiente.

### Funciona con `curl`, pero no desde Internet

Agregue o corrija la regla de entrada TCP `3001` con origen `0.0.0.0/0`.

### `ERR_SSL_PROTOCOL_ERROR`

Utilice HTTP:

```text
http://IP_PUBLICA_EC2:3001/
```

### `scp` busca un archivo llamado `pemfront.zip`

Falta un espacio en el comando. La forma correcta es:

```bash
scp -i certs/ajca-server-key.pem front.zip ubuntu@DNS_PUBLICO_EC2:/home/ubuntu/
```

---

## 13. Secuencia Completa

### Preparar el ZIP

```bash
zip -r front.zip front \
  -x "front/node_modules/*" \
     "front/dist/*" \
     "front/.git/*"

unzip -l front.zip | grep -E 'node_modules|/dist/'
```

La búsqueda no debe producir resultados.

### CloudShell

```bash
chmod 400 certs/ajca-server-key.pem

scp -i certs/ajca-server-key.pem \
  front.zip \
  ubuntu@DNS_PUBLICO_EC2:/home/ubuntu/

ssh -i certs/ajca-server-key.pem ubuntu@DNS_PUBLICO_EC2
```

### EC2

```bash
cd /home/ubuntu
unzip front.zip
cd front

docker build -t demo:latest .
docker images demo

docker run -d \
  -p 3001:80 \
  --name front \
  demo:latest

docker ps
docker logs front
curl -I http://localhost:3001/
```

Abra:

```text
http://IP_PUBLICA_EC2:3001/
```

---

## 14. Lista de Comprobación

- [ ] La instancia EC2 está encendida.
- [ ] Docker está instalado y activo.
- [ ] TCP `3001` permite conexiones desde `0.0.0.0/0`.
- [ ] `front.zip` contiene la carpeta `front/`.
- [ ] El ZIP no contiene `node_modules/`.
- [ ] El ZIP no contiene `dist/` local.
- [ ] `.dockerignore` está incluido.
- [ ] `package.json` y `package-lock.json` están incluidos.
- [ ] La llave `.pem` tiene permisos restringidos.
- [ ] `scp` copió el ZIP a `/home/ubuntu`.
- [ ] La construcción se ejecutó dentro de `/home/ubuntu/front`.
- [ ] `npm ci` terminó correctamente.
- [ ] `npm run build` generó `dist`.
- [ ] La imagen se llama `demo:latest`.
- [ ] El contenedor se llama `front`.
- [ ] El mapeo es `3001:80`.
- [ ] `docker ps` muestra el contenedor activo.
- [ ] `curl http://localhost:3001/` responde desde EC2.
- [ ] La página abre desde `http://IP_PUBLICA_EC2:3001/`.

---

## Resultado Esperado

```text
front.zip sin node_modules
          │
          ▼
docker build -t demo:latest .
          │
          ├── Node compila el proyecto
          └── Nginx recibe dist/
          │
          ▼
docker run -p 3001:80 --name front demo:latest
          │
          ▼
http://IP_PUBLICA_EC2:3001/
```

La aplicación queda publicada mediante Nginx y accesible desde todas las conexiones IPv4 permitidas por la regla de entrada del puerto `3001`.
