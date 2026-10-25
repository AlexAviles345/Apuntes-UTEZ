# 04 — Desplegar Sitios Web con Docker y Nginx

Esta práctica publica dos sitios web en EC2: una biografía y una calculadora. Cada proyecto tiene su propio Dockerfile, utiliza `nginx:alpine` y sirve sus archivos desde el puerto `80` del contenedor.

**Anterior:** [03 — Instalar y configurar Jenkins](../03%20-%20Instalar%20y%20configurar%20Jenkins.md).

Debe tener Docker instalado y estar conectado a EC2 mediante SSH.

---

## 1. Organización de los Proyectos

```text
despliegue-de-sitios-web-con-docker-y-nginx/
├── proyectos/
│   ├── bio/
│   │   ├── Dockerfile
│   │   ├── index.html
│   │   └── src/        # Bootstrap e imagen de la biografía
│   └── calc/
│       ├── Dockerfile
│       ├── index.html
│       └── main.js
└── 04 - Desplegar sitios web con Docker y Nginx.md
```

- [`proyectos/bio/`](proyectos/bio/) contiene la biografía de Naruto, sus estilos y su imagen.
- [`proyectos/calc/`](proyectos/calc/) contiene una calculadora de suma, resta, multiplicación y división. JavaScript realiza las operaciones en el navegador.

Las carpetas de ambos proyectos deben estar disponibles en EC2 antes de construir las imágenes. Si transfiere la biografía como `bio.zip`, descomprímala:

```bash
unzip bio.zip
```

Conserve los archivos de cada sitio junto a su Dockerfile. Los comandos siguientes parten de una carpeta `proyectos` que contiene `bio/` y `calc/`; ajuste la ubicación inicial según dónde los haya colocado en EC2.

---

## 2. Entender el Dockerfile

Ambos proyectos utilizan las mismas instrucciones:

```dockerfile
FROM nginx:alpine

RUN rm -rf /usr/share/nginx/html/*

COPY . /usr/share/nginx/html

EXPOSE 80
```

| Instrucción | Función |
|---|---|
| `FROM nginx:alpine` | Utiliza Nginx sobre Alpine como imagen base |
| `RUN rm -rf ...` | Elimina los archivos web predeterminados dentro de la imagen |
| `COPY . /usr/share/nginx/html` | Copia el proyecto a la carpeta que publica Nginx |
| `EXPOSE 80` | Declara el puerto utilizado dentro del contenedor |

La publicación hacia EC2 se establece después con `docker run -p`. Nginx entrega HTML, CSS, imágenes y JavaScript; las operaciones de la calculadora se ejecutan en el navegador.

---

## 3. Construir y Publicar la Biografía

Desde `proyectos`, entre a la biografía y construya su imagen:

```bash
cd bio
docker build -t biografia:v1.0 .
docker images
```

| Parte | Función |
|---|---|
| `docker build` | Construye una imagen siguiendo el Dockerfile |
| `-t biografia:v1.0` | Asigna el nombre `biografia` y la etiqueta `v1.0` |
| `.` | Utiliza la carpeta actual como contexto de construcción |

Compruebe que aparezca `biografia` con la etiqueta `v1.0`. Después, cree el contenedor:

```bash
docker run -d -p 3000:80 --name biografia biografia:v1.0
```

- `-d` deja el contenedor ejecutándose en segundo plano.
- `-p 3000:80` conecta el puerto `3000` de EC2 con el `80` del contenedor.
- `--name biografia` asigna el nombre del contenedor.
- `biografia:v1.0` selecciona la imagen construida.

---

## 4. Construir y Publicar la Calculadora

Si continúa desde `proyectos/bio`, entre a la carpeta vecina:

```bash
cd ../calc
docker build -t calculadora:v1.0 .
docker images
```

Se aplica el mismo procedimiento, utilizando otro nombre de imagen y de contenedor. Para ejecutar ambos sitios al mismo tiempo, este ejemplo publica la calculadora en `3001`:

```bash
docker run -d -p 3001:80 --name calculadora calculadora:v1.0
```

Ambos contenedores escuchan internamente en `80`. Sus puertos publicados en EC2 son distintos para evitar que compitan por el mismo puerto.

| Sitio | Imagen | Contenedor | Puerto EC2 → contenedor |
|---|---|---|---|
| Biografía | `biografia:v1.0` | `biografia` | `3000:80` |
| Calculadora | `calculadora:v1.0` | `calculadora` | `3001:80` |

---

## 5. Abrir los Sitios

En el grupo de seguridad de EC2, permita tráfico **TCP a los puertos `3000` y `3001`** desde el origen que realizará la prueba. Se agregan desde **Reglas de entrada → Editar reglas de entrada**, como se hizo para Jenkins.

Abra las siguientes direcciones, sustituyendo `IP_PUBLICA_EC2` por la IPv4 pública de su instancia:

```text
Biografía:   http://IP_PUBLICA_EC2:3000/
Calculadora: http://IP_PUBLICA_EC2:3001/
```

En la biografía, compruebe que carguen el texto, los estilos y la imagen. En la calculadora, introduzca dos números y pruebe sus botones de operación.

```text
Navegador → EC2:3000 → biografia:80 → Nginx → Biografía
Navegador → EC2:3001 → calculadora:80 → Nginx → Calculadora
```

## Resultado

Los dos sitios se ejecutan en contenedores independientes, con el mismo tipo de servidor y distintos puertos publicados. Jenkins mantiene su acceso en `8080`.
