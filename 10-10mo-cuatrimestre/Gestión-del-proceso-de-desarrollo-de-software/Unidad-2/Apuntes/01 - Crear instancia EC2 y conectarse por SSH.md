# 01 — Crear una Instancia EC2 y Conectarse por SSH

Esta práctica prepara un servidor Ubuntu en Amazon EC2 y permite administrarlo desde AWS CloudShell mediante una conexión SSH con llave privada.

## Orden de Estudio

1. **Crear instancia EC2 y conectarse por SSH** — esta guía.
2. [Instalar Git y Docker](02%20-%20Instalar%20Git%20y%20Docker.md).
3. [Instalar y configurar Jenkins](03%20-%20Instalar%20y%20configurar%20Jenkins.md).
4. [Desplegar sitios web con Docker y Nginx](despliegue-de-sitios-web-con-docker-y-nginx/04%20-%20Desplegar%20sitios%20web%20con%20Docker%20y%20Nginx.md).

---

## 1. Crear la Instancia

En la consola de AWS, entre a **EC2 → Instancias → Lanzar instancia**.

### Nombre e imagen del sistema operativo

Asigne el nombre `ajca-server` y seleccione **Ubuntu**. En la práctica se utilizó **Ubuntu Server 26.04 LTS**, con arquitectura de 64 bits x86.

La AMI es la imagen con la que se crea el sistema operativo del servidor.

![Nombre de la instancia y selección de Ubuntu](imagenes/25-09-2026/ec2-nombre-y-ubuntu.webp)

### Tipo de instancia

Seleccione `t3.small`, el tipo utilizado en la práctica. La captura muestra **2 vCPU** y **2 GiB de memoria**.

El tipo de instancia determina los recursos de cómputo disponibles; no es lo mismo que la AMI, que define el sistema operativo.

![Selección del tipo t3.small](imagenes/25-09-2026/ec2-tipo-instancia.webp)

### Par de claves

Cree un par de claves con estas opciones:

| Campo | Selección |
|---|---|
| Nombre | `ajca-server-key` |
| Tipo | `RSA` |
| Formato de la clave privada | `.pem` |

Descargue y conserve `ajca-server-key.pem`: se utilizará para autenticarse como `ubuntu` desde CloudShell.

![Creación del par de claves RSA en formato PEM](imagenes/25-09-2026/ec2-par-claves-pem.webp)

### Red y grupo de seguridad

Habilite la **asignación automática de IP pública** y cree un grupo de seguridad. En esta etapa se permite **SSH**, que utiliza el puerto `22`.

La captura muestra el origen `0.0.0.0/0`, que permite conexiones desde cualquier IPv4. El origen de la regla debe permitir el equipo o entorno desde el que se realizará la conexión.

![Configuración de IP pública y acceso SSH](imagenes/25-09-2026/ec2-configuracion-red.webp)

Las opciones HTTP y HTTPS aparecen desmarcadas. El acceso a Jenkins y a la biografía se habilita posteriormente mediante sus puertos correspondientes.

### Almacenamiento

Configure un volumen raíz de **30 GiB**, de tipo **gp3**, como se muestra en la práctica.

![Configuración del volumen raíz de 30 GiB](imagenes/25-09-2026/ec2-almacenamiento.webp)

Revise las selecciones y pulse **Lanzar instancia**. Espere a que su estado sea **En ejecución** y a que finalicen las comprobaciones de estado.

---

## 2. Identificar los Datos de Conexión

Seleccione la instancia y localice:

- **IPv4 pública:** se utilizará para abrir las aplicaciones en el navegador.
- **DNS público:** se utilizará en el comando SSH.
- **Nombre de usuario:** `ubuntu`, para la imagen utilizada.
- **Par de claves:** `ajca-server-key`.

En **Conectar → En el cliente SSH**, AWS muestra los comandos de permisos y conexión.

![Datos y comandos de conexión SSH de la instancia](imagenes/25-09-2026/ec2-instrucciones-ssh.webp)

La dirección utilizada durante la práctica fue `34.200.229.80`, con DNS `ec2-34-200-229-80.compute-1.amazonaws.com`. Al repetirla, use los valores que muestre su instancia.

---

## 3. Abrir CloudShell y Subir la Llave

Abra **AWS CloudShell** desde la consola. CloudShell proporciona una terminal; todavía no es una sesión dentro de EC2.

![CloudShell abierto junto a la instancia en ejecución](imagenes/25-09-2026/cloudshell-instancia-en-ejecucion.webp)

En **Acciones → Cargar archivo**, seleccione `ajca-server-key.pem`. La carga deja el archivo en `/home/cloudshell-user`.

Compruebe la ubicación y organice la llave en una carpeta llamada `certs`:

```bash
pwd
ls
mkdir certs
mv ajca-server-key.pem certs/
cd certs/
ls
```

| Comando | Qué hace |
|---|---|
| `pwd` | Muestra la carpeta actual |
| `ls` | Lista su contenido |
| `mkdir certs` | Crea una carpeta para la llave |
| `mv ajca-server-key.pem certs/` | Mueve la llave a esa carpeta |
| `cd certs/` | Entra a la carpeta |

![Llave cargada y organizada en la carpeta certs de CloudShell](imagenes/25-09-2026/cloudshell-organizar-clave.webp)

Estos comandos corresponden a la primera preparación. Si `certs` ya existe y la llave ya está dentro, entre directamente a esa carpeta; no repita la creación ni el movimiento.

---

## 4. Conectarse por SSH

Desde la carpeta `certs`, limite los permisos de la llave:

```bash
chmod 400 "ajca-server-key.pem"
```

`400` deja la llave con permiso de lectura para su propietario y sin permisos para los demás usuarios.

Después, conéctese usando el DNS público de EC2:

```bash
ssh -i "ajca-server-key.pem" ubuntu@DNS_PUBLICO_EC2
```

Sustituya `DNS_PUBLICO_EC2` por el que aparece en **Conectar**. La opción `-i` indica qué llave privada se utilizará.

En la primera conexión aparece una pregunta sobre la autenticidad del servidor. Compruebe que la dirección corresponda a su instancia y escriba `yes` para continuar.

![Conexión SSH y mensaje de bienvenida de Ubuntu](imagenes/25-09-2026/ssh-conexion-ubuntu.webp)

La conexión está establecida cuando aparece el mensaje de bienvenida de Ubuntu y el prompt cambia a uno parecido a:

```text
ubuntu@ip-172-31-0-55:~$
```

La dirección privada y el texto exacto pueden variar. A partir de aquí, los comandos se ejecutan en **EC2**, aunque la terminal siga mostrándose dentro de CloudShell.

---

## 5. Salir y Volver a Entrar

Para cerrar la sesión SSH:

```bash
exit
```

Esto devuelve el control a CloudShell. Un segundo `exit`, ejecutado ya en CloudShell, cierra esa sesión de terminal.

Para volver a conectarse, sitúese en `certs` y repita el comando SSH. Si CloudShell se abrió nuevamente en `/home/cloudshell-user`, primero ejecute:

```bash
cd certs/
ssh -i "ajca-server-key.pem" ubuntu@DNS_PUBLICO_EC2
```

## Resultado

La instancia Ubuntu está en ejecución y puede administrarse mediante SSH. La carpeta `certs` y la llave permanecen en CloudShell; el software del servidor se instalará dentro de EC2.

**Siguiente:** [02 — Instalar Git y Docker](02%20-%20Instalar%20Git%20y%20Docker.md).
