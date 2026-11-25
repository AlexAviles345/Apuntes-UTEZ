# 02 — Guía de Nginx y Certbot con DuckDNS

Esta parte reutiliza la IP elástica del [paso anterior](01%20-%20IP%20el%C3%A1stica%20y%20webhook%20de%20GitHub%20para%20Jenkins.md) y el servidor Ubuntu con Docker y Docker Compose. Primero se hizo accesible el dominio por HTTP. Después Let's Encrypt validó el dominio y Certbot guardó el certificado en una carpeta compartida con Nginx.

## 1. Apuntar el subdominio de DuckDNS a EC2

1. Abre [DuckDNS](https://www.duckdns.org/), selecciona **Sign in with GitHub** y autoriza el acceso.
2. En **domains**, escribe el nombre del subdominio y pulsa **add domain**. En la sesión se usó `alex-aws.duckdns.org`.
3. En **current ip**, escribe la IPv4 elástica de la instancia y pulsa **update ip**. La confirmación debe mostrar que el subdominio quedó actualizado a la IP de EC2.
4. Desde otra máquina, comprueba que el nombre resuelva a esa IPv4. En los comandos, sustituye `mi-subdominio.duckdns.org` por el dominio que registraste.

```bash
nslookup mi-subdominio.duckdns.org
```

![Página principal de DuckDNS con acceso mediante GitHub](imagenes/20-duckdns-inicio.webp)
![Autorización de DuckDNS en GitHub](imagenes/21-duckdns-autorizar-github.webp)
![Subdominio creado antes de actualizar su IPv4](imagenes/22-duckdns-subdominio-creado.webp)
![DuckDNS confirma que el dominio apunta a la IP elástica de EC2](imagenes/23-duckdns-ip-actualizada.webp)

## 2. Preparar la configuración en la instancia

Conéctate por SSH a la instancia desde CloudShell. En la sesión se creó `~/environment` con el Compose, un archivo de configuración de Nginx y las carpetas que se comparten con Certbot.

```bash
mkdir -p ~/environment
cd ~/environment
mkdir -p nginx certbot/conf certbot/www
nano docker-compose.yml
nano nginx/default.conf
```

Copia el contenido de [docker-compose.yml](environment/docker-compose.yml) y de [nginx/default.conf](environment/nginx/default.conf) en sus archivos correspondientes. Sustituye `mi-subdominio.duckdns.org` en `server_name` por el nombre registrado en DuckDNS.

| Elemento | Función |
|---|---|
| `nginx` | Publica `80:80` y `443:443`. La configuración inicial escucha por HTTP en el puerto `80`. |
| `certbot` | Ejecuta `certbot renew` y espera 12 horas antes de volver a comprobar las renovaciones. Usa `/bin/sh` como punto de entrada del bucle. |
| `./certbot/www` | Certbot escribe aquí el desafío y Nginx sirve el archivo bajo `/.well-known/acme-challenge/`. |
| `./certbot/conf` | Certbot guarda los certificados, su configuración y sus claves. Nginx monta la misma carpeta en modo de solo lectura. |
| `host.docker.internal:host-gateway` | Permite que Nginx alcance servicios publicados en el host si más adelante se configura como proxy inverso. |

El Compose de `environment` crea su propia red. PMNG conserva la red `pmng-net` del [despliegue anterior](../1.%20Despliegue%20con%20Jenkins/README.md). En la configuración inicial, `location /` devuelve el texto `Servidor HTTP funcionando` y la ruta del desafío lee de `/var/www/certbot`. [Redes y host-gateway en Docker Compose](https://docs.docker.com/compose/how-tos/networking/).

![Estructura de trabajo creada en la terminal de la instancia](imagenes/24-estructura-environment.webp)
![Edición del archivo docker-compose.yml](imagenes/25-editar-docker-compose.webp)
![Configuración inicial de Nginx para HTTP y el desafío de Let's Encrypt](imagenes/26-configuracion-http-nginx.webp)

## 3. Configurar el grupo de seguridad

En **EC2 → Instancias → Seguridad**, abre el grupo asociado a la instancia y entra en **Editar reglas de entrada**. En la sesión se pasó de tener solo la regla de SSH a agregar estas reglas TCP:

| Puerto | Origen que muestran las capturas | Uso |
|---|---|---|
| `80` | Anywhere-IPv4 (`0.0.0.0/0`) | Respuesta HTTP de Nginx y validación HTTP-01 de Let's Encrypt. |
| `443` | Anywhere-IPv4 (`0.0.0.0/0`) | Entrada preparada para HTTPS. |
| `8080` | Anywhere-IPv4 (`0.0.0.0/0`) | Acceso directo a Jenkins y recepción del webhook durante el laboratorio. |

Guarda las reglas. Conserva acceso SSH en `22` desde tu origen autorizado. El desafío HTTP-01 requiere que el dominio sea alcanzable públicamente por el puerto `80`. [Reglas de grupos de seguridad de EC2](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/security-group-rules-reference.html) · [HTTP-01 en Let's Encrypt](https://letsencrypt.org/docs/challenge-types/#http-01-challenge).

![Grupo de seguridad antes de agregar las reglas web](imagenes/27-grupo-seguridad-inicial.webp)
![Reglas de entrada para HTTP, HTTPS y Jenkins en el laboratorio](imagenes/28-grupo-seguridad-puertos.webp)

## 4. Iniciar Nginx y comprobar HTTP

Desde `~/environment` se consultaron los contenedores activos y se inició únicamente Nginx.

```bash
docker ps
docker compose config --quiet
docker compose up -d nginx
docker ps
```

Antes del arranque se veía `pmng-cliente` en el puerto `5173`. Al iniciar Nginx apareció un segundo contenedor con los puertos `80` y `443` publicados y Compose creó la red `environment_default`. Abre `http://mi-subdominio.duckdns.org` desde el navegador o usa `curl` desde fuera de la instancia:

```bash
curl -fsS http://mi-subdominio.duckdns.org/
```

En la sesión se obtuvo `Servidor HTTP funcionando`. Con esto se confirmó que el dominio llegaba a Nginx por HTTP. La publicación del `443` prepara el paso posterior de configurar TLS en Nginx.

![PMNG cliente ya aparece activo antes de levantar Nginx](imagenes/29-pmng-cliente-en-ec2.webp)
![Arranque de Nginx y creación de la red environment_default](imagenes/30-arranque-nginx.webp)
![Nginx y pmng-cliente aparecen juntos en docker ps](imagenes/31-nginx-puertos-publicados.webp)
![El navegador muestra la respuesta de prueba por HTTP](imagenes/32-respuesta-http.webp)

## 5. Emitir el certificado de Let's Encrypt

Con Nginx sirviendo HTTP, ejecuta Certbot una sola vez para obtener el certificado. Cambia el dominio y el correo por los que vas a registrar.

```bash
docker compose run --rm --entrypoint certbot certbot certonly \
  --webroot --webroot-path /var/www/certbot \
  --email tu-correo@example.com --agree-tos --no-eff-email \
  -d mi-subdominio.duckdns.org
```

`--entrypoint certbot` reemplaza el bucle del servicio para esta ejecución. `certonly --webroot` escribe el archivo de validación en el directorio compartido. Let's Encrypt solicita ese archivo a Nginx por HTTP y, si la validación funciona, emite el certificado. `--rm` elimina el contenedor temporal al finalizar. Los archivos quedan en el volumen enlazado a `./certbot/conf`. [Modo webroot de Certbot](https://eff-certbot.readthedocs.io/en/stable/using.html#webroot).

Certbot muestra `Successfully received certificate` y las rutas del certificado y su clave dentro de `/etc/letsencrypt/live/<dominio>/`. Los archivos son `fullchain.pem` y `privkey.pem`. En EC2, sus rutas se conservan bajo `~/environment/certbot/conf/`.

![Certbot confirma que obtuvo el certificado y muestra la ubicación de los archivos](imagenes/33-certificado-emitido.webp)

## 6. Iniciar las comprobaciones de renovación

```bash
docker compose up -d certbot
docker ps
```

El contenedor queda ejecutando el bucle que revisa renovaciones cada 12 horas. El intervalo es de comprobación. Certbot decide cuándo corresponde renovar. El puerto `80` y la ruta del desafío deben seguir disponibles. [Renovaciones de Certbot](https://eff-certbot.readthedocs.io/en/stable/using.html#automated-renewals).

![Certbot, Nginx y pmng-cliente aparecen activos al finalizar](imagenes/34-certbot-en-ejecucion.webp)

## 7. Hasta dónde llegó la práctica

Se obtuvo el certificado y se inició el contenedor de renovación. La prueba del navegador mostró HTTP y `default.conf` contiene únicamente el bloque del puerto `80`. Para servir HTTPS queda configurar en Nginx un bloque `listen 443 ssl` con `ssl_certificate` y `ssl_certificate_key`, validar y recargar la configuración, y probar el dominio con `https://`. Una renovación futura también necesita que Nginx recargue el certificado para empezar a usarlo. [Configuración HTTPS en Nginx](https://nginx.org/en/docs/http/configuring_https_servers.html) · [Recarga de Nginx](https://nginx.org/en/docs/control.html).

La respuesta documentada del dominio es la página de prueba de Nginx. Publicar PMNG por ese dominio requeriría configurar el proxy hacia sus servicios y ajustar las peticiones del cliente para que usen HTTPS.

[Volver al índice](README.md)
