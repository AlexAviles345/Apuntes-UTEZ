# Webhook de Jenkins y certificados con Nginx — Unidad 3

Este apunte continúa el despliegue de PMNG en Amazon EC2. En la primera parte se asoció una IP elástica y se configuró un webhook de GitHub para que Jenkins detectara cambios. En la segunda se apuntó un subdominio de DuckDNS a la instancia y se usaron Nginx y Certbot para emitir un certificado de Let's Encrypt.

## Orden de lectura

1. [01 — IP elástica y webhook de GitHub para Jenkins](01%20-%20IP%20el%C3%A1stica%20y%20webhook%20de%20GitHub%20para%20Jenkins.md). Reserva y asociación de la IP, actualización de Jenkins, configuración del webhook y prueba en la rama `test`.
2. [02 — Guía de Nginx y Certbot con DuckDNS](02%20-%20Gu%C3%ADa%20de%20Nginx%20y%20Certbot%20con%20DuckDNS.md). Registro del subdominio, reglas de EC2, arranque de Nginx por HTTP, emisión del certificado e inicio de las comprobaciones de renovación.

## Contexto de las prácticas anteriores

- [Despliegue con Jenkins](../1.%20Despliegue%20con%20Jenkins/README.md). Pipeline de PMNG, credenciales y arranque con Docker Compose.
- [Crear la instancia EC2 y conectarse por SSH](../../../Unidad-2/Apuntes/1.%20ec2-docker-y-nginx-inicial/01%20-%20Crear%20instancia%20EC2%20y%20conectarse%20por%20SSH.md). Instancia Ubuntu y conexión desde AWS.
- [Desplegar sitios web con Docker y Nginx](../../../Unidad-2/Apuntes/2.%20despliegue-de-sitios-web-con-docker-y-nginx/04%20-%20Desplegar%20sitios%20web%20con%20Docker%20y%20Nginx.md). Antecedente del uso de Nginx en Docker.

## Contenido de la carpeta

- [docker-compose.yml](environment/docker-compose.yml) y [default.conf](environment/nginx/default.conf) para reproducir la configuración inicial.
- [imagenes/](imagenes/) contiene las 34 capturas WebP de la práctica.

La última comprobación muestra el certificado emitido y el contenedor Certbot iniciado. La evidencia de acceso desde el navegador corresponde a HTTP.
