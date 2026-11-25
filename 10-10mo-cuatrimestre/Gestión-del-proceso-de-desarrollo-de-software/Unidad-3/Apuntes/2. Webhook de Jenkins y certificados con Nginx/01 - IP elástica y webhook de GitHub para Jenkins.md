# 01 — IP elástica y webhook de GitHub para Jenkins

Se usaron la instancia EC2 y el job `pmng` configurados en el [apunte de despliegue con Jenkins](../1.%20Despliegue%20con%20Jenkins/README.md). En esa práctica el primer despliegue se lanzó con **Construir ahora**. Aquí se añadió una notificación automática de GitHub para que Jenkins comprobara si había cambios en la rama configurada.

## 1. Reservar una IP elástica en EC2

1. En la región de la instancia (Norte de Virginia, `us-east-1` en la práctica), abre **EC2 → Red y seguridad → Direcciones IP elásticas**.
2. Selecciona **Asignar dirección IP elástica**.
3. En el formulario, deja seleccionado el grupo de direcciones IPv4 públicas de Amazon y conserva el grupo fronterizo de red de la región. Pulsa **Asignar**.
4. Comprueba que aparezca la confirmación y que en la lista se muestre la IPv4 reservada. En ese momento, la columna de instancia asociada todavía está vacía.

![Menú Direcciones IP elásticas en EC2](imagenes/01-menu-ip-elasticas.webp)
![Botón para asignar una dirección IP elástica](imagenes/02-asignar-ip-elastica.webp)
![Formulario de asignación con direcciones públicas de Amazon](imagenes/03-configurar-asignacion.webp)
![Confirmación de que se reservó una IP elástica](imagenes/04-ip-reservada.webp)

## 2. Asociar la IP a la instancia

1. Selecciona la IP y abre **Acciones → Asociar dirección IP elástica**. La consola también muestra ese acceso en la notificación de asignación.
2. Elige **Instancia**, selecciona la EC2 de la práctica y pulsa **Asociar**. Al dejar vacía la dirección privada, la consola usa la IPv4 privada principal.
3. Confirma el aviso de asociación. En **Instancias**, comprueba que la misma dirección aparezca como IPv4 pública e IP elástica.

La dirección reservada es el punto de acceso estable que se utiliza en Jenkins y, más adelante, en DuckDNS. Si te conectabas con la IPv4 pública o el DNS anterior, usa los datos que muestra EC2 después de la asociación. [Documentación de direcciones IP elásticas en EC2](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/working-with-eips.html).

![Acción para asociar la dirección reservada](imagenes/05-accion-asociar-ip.webp)
![Selección de la instancia existente en el formulario](imagenes/06-seleccionar-instancia.webp)
![Confirmación de asociación de la IP elástica](imagenes/07-asociacion-exitosa.webp)
![La IP elástica aparece como IPv4 pública de la instancia](imagenes/08-ec2-con-ip-elastica.webp)

## 3. Actualizar la dirección de Jenkins

1. Abre `http://IP_ELASTICA:8080/` con la IPv4 que acabas de asociar. Para esta etapa, GitHub también necesita poder llegar al puerto TCP `8080`. La [guía de Nginx y Certbot](02%20-%20Gu%C3%ADa%20de%20Nginx%20y%20Certbot%20con%20DuckDNS.md#3-configurar-el-grupo-de-seguridad) muestra las reglas usadas en la sesión.
2. En **Administrar Jenkins → System → Jenkins Location**, localiza **Dirección web de Jenkins**.
3. Sustituye la IP anterior por la elástica y guarda. Conserva el esquema `http://`, el puerto `8080` y la barra final de la URL que se usó en la práctica.

Esta configuración le indica a Jenkins cuál es su URL externa. El acceso al puerto sigue dependiendo de la instancia y su grupo de seguridad.

![Abrir System desde Administrar Jenkins](imagenes/09-administrar-jenkins.webp)
![Dirección anterior registrada en Jenkins Location](imagenes/10-jenkins-url-anterior.webp)
![Dirección de Jenkins actualizada con la IP elástica](imagenes/11-jenkins-url-ip-elastica.webp)

## 4. Crear el webhook en GitHub

En el mismo repositorio privado de PMNG que lee el pipeline, entra en **Settings → Webhooks → Add webhook**. Configura estos campos y guarda el webhook:

| Campo | Valor de la práctica |
|---|---|
| Payload URL | `http://IP_ELASTICA:8080/github-webhook/`, incluida la barra final |
| Content type | `application/json` |
| Events | **Just the push event** |
| Active | Activado |

La captura corresponde a la prueba por HTTP. Si se migra el webhook a un endpoint HTTPS con certificado válido, mantén activa la verificación SSL. [Buenas prácticas de webhooks de GitHub](https://docs.github.com/en/webhooks/using-webhooks/best-practices-for-using-webhooks).

Cuando GitHub muestre **Last delivery was successful**, quedó confirmada una entrega al endpoint. El estado de un build se comprueba por separado en Jenkins. [Pruebas de webhooks en GitHub](https://docs.github.com/en/webhooks/testing-and-troubleshooting-webhooks/testing-webhooks).

![Ubicación de Webhooks en los ajustes del repositorio](imagenes/12-github-seccion-webhooks.webp)
![Formulario con la URL de Jenkins, JSON y el evento push](imagenes/13-github-crear-webhook.webp)
![GitHub reporta que la última entrega fue exitosa](imagenes/14-github-entrega-exitosa.webp)

## 5. Activar el disparador de Jenkins

1. Entra al job `pmng` y abre **Configure → Triggers**.
2. Marca **GitHub hook trigger for GITScm polling** y guarda.
3. Revisa que **Pipeline script from SCM** apunte al mismo repositorio y que **Branch Specifier** incluya la rama a probar. En esta sesión se usó `*/test`.

Al recibir el aviso en `/github-webhook/`, el plugin hace que Jenkins consulte Git y determine si hay cambios que construir para el job. Las etapas de compilación y despliegue siguen definidas en el [Jenkinsfile del apunte anterior](../1.%20Despliegue%20con%20Jenkins/pmng/Jenkinsfile). [Documentación del plugin GitHub de Jenkins](https://plugins.jenkins.io/github/).

![Disparador GitHub hook trigger for GITScm polling activado](imagenes/15-jenkins-trigger-github.webp)

## 6. Probar con un cambio en la rama test

1. En GitHub, selecciona la rama `test` y edita `client/index.html`.
2. En la sesión se agregó `<span></span>` al inicio del cuerpo de la página para generar un cambio pequeño.
3. Pulsa **Commit changes** y confirma el commit directamente en `test`. Al guardar desde GitHub, el cambio queda publicado en el repositorio remoto y se genera el evento `push`.
4. Revisa **Recent Deliveries** en GitHub y, en Jenkins, **GitHub Hook Log**, el historial **Builds** y la consola de la ejecución. Si hubo entrega pero no hay una ejecución nueva, comprueba que el repositorio y la rama coincidan con la configuración del job.

![Edición del archivo client/index.html en la rama test](imagenes/17-github-editar-index.webp)
![Se agrega un elemento span vacío al HTML](imagenes/18-github-cambio-span.webp)
![Confirmación de un commit directamente en la rama test](imagenes/19-github-commit-rama-test.webp)
![Historial de Jenkins con el build 8 en curso y ejecuciones anteriores exitosas](imagenes/16-jenkins-build-en-curso.webp)

La captura de Jenkins muestra el build `#8` en curso. Para confirmar una ejecución concreta, abre su consola y revisa tanto el commit construido como el resultado final.

[Volver al índice](README.md) · [Continuar con Nginx y Certbot](02%20-%20Gu%C3%ADa%20de%20Nginx%20y%20Certbot%20con%20DuckDNS.md)
