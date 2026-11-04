# Imagen base para servir archivos estáticos
FROM nginx:alpine

# Eliminamos los archivos por defecto de Nginx
RUN rm -rf /usr/share/nginx/html/*

# Copiamos nuestro proyecto a la carpeta que Nginx publica
COPY . /usr/share/nginx/html

# Puerto en el que Nginx expone el sitio
EXPOSE 80
