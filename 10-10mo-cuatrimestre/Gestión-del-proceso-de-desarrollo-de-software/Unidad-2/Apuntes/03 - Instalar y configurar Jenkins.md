# 03 — Instalar y Configurar Jenkins

Esta práctica instala Java y Jenkins directamente en la instancia Ubuntu, habilita el acceso por el puerto `8080` y completa la configuración inicial desde el navegador.

**Anterior:** [02 — Instalar Git y Docker](02%20-%20Instalar%20Git%20y%20Docker.md).

Los comandos de instalación se ejecutan dentro de EC2, en una sesión SSH como `ubuntu`.

---

## 1. Instalar Java

Jenkins necesita Java para ejecutarse. Prepare los paquetes:

```bash
sudo apt update
sudo apt install -y fontconfig openjdk-21-jre
```

`openjdk-21-jre` proporciona el entorno de ejecución de Java 21. `fontconfig` proporciona soporte para la configuración de fuentes.

Compruebe la versión:

```bash
java --version
```

![Versión de OpenJDK 21 instalada en Ubuntu](imagenes/25-09-2026/java-version-openjdk-21.webp)

---

## 2. Agregar el Repositorio de Jenkins

### Descargar la clave

```bash
sudo wget -O /etc/apt/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key
```

`wget` descarga la clave y `-O` indica dónde guardarla. La carpeta `/etc/apt/keyrings` se creó al preparar Docker.

### Registrar el repositorio

```bash
echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc]" \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null
```

El repositorio `debian-stable` se utiliza para instalar Jenkins LTS. La opción `signed-by` vincula el repositorio con la clave descargada.

---

## 3. Instalar e Iniciar Jenkins

```bash
sudo apt update
sudo apt install -y jenkins
sudo systemctl start jenkins
```

Primero se actualiza la lista de paquetes, después se instala Jenkins y finalmente se solicita el inicio del servicio `jenkins`.

Jenkins se ejecuta como servicio del sistema, no como contenedor Docker.

---

## 4. Identificar el Puerto

```bash
sudo lsof -i -P -n | grep java
```

| Fragmento | Función |
|---|---|
| `lsof -i` | Muestra archivos de red abiertos por los procesos |
| `-P` | Muestra números de puerto en lugar de nombres de servicio |
| `-n` | Muestra direcciones numéricas sin resolver nombres de host |
| `grep java` | Conserva las líneas que contienen `java` |

![Proceso Java de Jenkins escuchando en el puerto 8080](imagenes/25-09-2026/jenkins-puerto-8080.webp)

La salida muestra `TCP *:8080 (LISTEN)`: el proceso está escuchando en el puerto `8080`.

---

## 5. Permitir el Acceso en EC2

En la consola de AWS:

1. Seleccione la instancia.
2. Abra el grupo de seguridad asociado.
3. Entre a **Reglas de entrada → Editar reglas de entrada**.
4. Agregue una regla **TCP personalizado**, con puerto `8080`.
5. Configure el origen que tendrá acceso y guarde los cambios.

![Acceso a las reglas de entrada del grupo de seguridad](imagenes/25-09-2026/ec2-editar-grupo-seguridad.webp)

![Reglas para SSH en 22 y Jenkins en 8080](imagenes/25-09-2026/ec2-reglas-ssh-jenkins.webp)

La captura utiliza `0.0.0.0/0` como origen. Ese valor permite conexiones desde cualquier IPv4. La regla de SSH en `22` se conserva para administrar el servidor.

Abra en el navegador:

```text
http://IP_PUBLICA_EC2:8080/
```

Sustituya `IP_PUBLICA_EC2` por la IPv4 de su instancia. En la práctica se accedió a `http://34.200.229.80:8080/`.

---

## 6. Desbloquear Jenkins

La primera pantalla solicita la contraseña inicial del administrador:

![Pantalla inicial para desbloquear Jenkins](imagenes/25-09-2026/jenkins-desbloqueo.webp)

En la sesión SSH de EC2, consulte la contraseña:

```bash
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

`cat` muestra el contenido del archivo. Copie la contraseña que devuelve su servidor, péguela en **Administrator password** y continúe.

Si cerró la conexión SSH, vuelva a entrar desde CloudShell antes de ejecutar `sudo cat`:

```bash
cd certs/
ssh -i "ajca-server-key.pem" ubuntu@DNS_PUBLICO_EC2
```

El `cd certs/` corresponde a una terminal de CloudShell situada en `/home/cloudshell-user`. Si ya está dentro de `certs`, repita únicamente el comando SSH.

---

## 7. Instalar los Plugins Sugeridos

Seleccione **Install suggested plugins**:

![Selección de los plugins sugeridos de Jenkins](imagenes/25-09-2026/jenkins-plugins-sugeridos.webp)

Espere a que finalice la instalación. Los plugins agregan funciones a Jenkins; esta opción instala el conjunto sugerido por el asistente.

---

## 8. Crear el Usuario Administrador

Complete el formulario **Create First Admin User** con:

- nombre de usuario;
- contraseña y confirmación;
- nombre completo;
- correo electrónico.

Pulse **Save and Continue**.

![Formulario para crear el primer usuario administrador](imagenes/25-09-2026/jenkins-usuario-administrador.webp)

La contraseña elegida para esta cuenta se utilizará en los siguientes inicios de sesión. La contraseña inicial del paso anterior sirve para desbloquear el asistente.

---

## 9. Configurar la URL de Jenkins

Revise que **Jenkins URL** corresponda a la dirección pública con la que está accediendo:

```text
http://IP_PUBLICA_EC2:8080/
```

![Configuración de la URL pública de Jenkins](imagenes/25-09-2026/jenkins-url-instancia.webp)

Guarde la configuración. Cuando aparezca **Jenkins is ready!**, pulse **Start using Jenkins**.

![Configuración inicial de Jenkins completada](imagenes/25-09-2026/jenkins-configuracion-completada.webp)

---

## 10. Agregar GitHub Integration

Dentro de Jenkins:

1. Abra **Administrar Jenkins → Plugins**.
2. Seleccione **Available plugins**.
3. Busque `GitHub Integration`.
4. Marque el plugin y pulse **Install**.

![Selección del plugin GitHub Integration](imagenes/25-09-2026/jenkins-plugin-github-integration.webp)

Este paso agrega el plugin. La conexión a un repositorio, las credenciales y la creación de un trabajo de Jenkins corresponden a una configuración posterior.

## Resultado

Jenkins queda instalado como servicio en Ubuntu, accesible desde el puerto `8080`, con el asistente inicial completado y la selección del plugin de integración con GitHub.

**Siguiente:** [04 — Desplegar sitios web con Docker y Nginx](despliegue-de-sitios-web-con-docker-y-nginx/04%20-%20Desplegar%20sitios%20web%20con%20Docker%20y%20Nginx.md).
