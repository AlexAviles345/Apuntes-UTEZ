# 02 — Instalar Git y Docker en Ubuntu

Esta práctica instala Git y Docker en la instancia Ubuntu. Antes de comenzar, debe estar conectado a EC2 mediante SSH.

**Anterior:** [01 — Crear instancia EC2 y conectarse por SSH](01%20-%20Crear%20instancia%20EC2%20y%20conectarse%20por%20SSH.md).

---

## 1. Actualizar la Lista de Paquetes

Dentro de EC2, ejecute:

```bash
sudo apt update
```

Este comando descarga la información de los paquetes disponibles en los repositorios configurados. No actualiza por sí mismo todos los programas instalados.

`sudo` ejecuta la instrucción con privilegios administrativos.

---

## 2. Instalar Git

```bash
sudo apt install -y git
git --version
```

- `apt install` instala el paquete indicado.
- `-y` acepta automáticamente las confirmaciones de instalación.
- `git --version` comprueba que el comando esté disponible y muestra su versión.

![Instalación de Git y consulta de su versión](imagenes/25-09-2026/git-instalacion-y-version.webp)

La captura muestra que Git ya estaba instalado y que se pudo consultar su versión. Git permitirá trabajar con repositorios; en este paso todavía no se clona ningún proyecto.

---

## 3. Preparar el Repositorio de Docker

### Instalar las dependencias

```bash
sudo apt install -y ca-certificates curl gnupg lsb-release
```

Estos paquetes proporcionan certificados, herramientas de descarga y utilidades relacionadas con claves e información de la distribución.

### Crear la carpeta de claves

```bash
sudo install -m 0755 -d /etc/apt/keyrings
```

Aquí `install` se utiliza para crear el directorio con los permisos indicados; no descarga Docker.

| Parte | Función |
|---|---|
| `-d` | Crea el directorio |
| `-m 0755` | Establece sus permisos |
| `/etc/apt/keyrings` | Carpeta donde se guardarán las claves de los repositorios |

### Descargar la clave de Docker

```bash
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  -o /etc/apt/keyrings/docker.asc
```

`curl` descarga la clave y `-o` indica el archivo donde se guardará. La barra invertida `\` permite continuar el mismo comando en la línea siguiente.

Permita que la clave pueda leerse:

```bash
sudo chmod a+r /etc/apt/keyrings/docker.asc
```

### Agregar el repositorio

```bash
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

Este comando construye la entrada del repositorio y la guarda en `docker.list`.

| Fragmento | Función |
|---|---|
| `dpkg --print-architecture` | Obtiene la arquitectura del sistema |
| `signed-by=.../docker.asc` | Indica la clave usada para verificar el repositorio |
| `/etc/os-release` | Proporciona información de Ubuntu |
| `${UBUNTU_CODENAME:-$VERSION_CODENAME}` | Obtiene el nombre de la versión de Ubuntu |
| `stable` | Selecciona el canal estable |
| `tee` | Escribe la entrada en el archivo con permisos administrativos |
| `> /dev/null` | Evita imprimir en pantalla la copia que produce `tee` |

---

## 4. Instalar Docker

Actualice de nuevo la lista de paquetes, ahora con el repositorio de Docker agregado:

```bash
sudo apt update
```

Instale los componentes:

```bash
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

| Paquete | Función |
|---|---|
| `docker-ce` | Motor de Docker |
| `docker-ce-cli` | Comando `docker` utilizado desde la terminal |
| `containerd.io` | Componente de ejecución de contenedores |
| `docker-buildx-plugin` | Complemento para construir imágenes |
| `docker-compose-plugin` | Complemento de Compose para aplicaciones con varios servicios |

Instalar Compose no significa que se utilice en la práctica: el despliegue posterior se realiza con `docker build` y `docker run`.

---

## 5. Agregar el Usuario al Grupo docker

```bash
sudo usermod -aG docker $USER
```

- `usermod` modifica los grupos del usuario.
- `-aG docker` lo agrega al grupo `docker` conservando sus otros grupos.
- `$USER` representa al usuario de la sesión, en este caso `ubuntu`.

Para que la sesión tome la nueva pertenencia al grupo, salga de SSH y vuelva a entrar:

```bash
exit
```

Ya en CloudShell, desde la carpeta que contiene la llave:

```bash
ssh -i "ajca-server-key.pem" ubuntu@DNS_PUBLICO_EC2
```

Use el DNS de su instancia. Esta reconexión permite continuar con los comandos de Docker sin anteponer `sudo`.

---

## 6. Consultar la Versión

Dentro de EC2:

```bash
docker --version
```

El comando debe mostrar la versión instalada. Esta comprobación confirma que el cliente de Docker está disponible; la ejecución de un contenedor se realizará en la guía 04.

## Resultado

Git y Docker quedan instalados en la instancia, y el usuario `ubuntu` pertenece al grupo `docker`.

**Siguiente:** [03 — Instalar y configurar Jenkins](03%20-%20Instalar%20y%20configurar%20Jenkins.md).
