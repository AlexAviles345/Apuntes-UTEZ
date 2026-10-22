# Etapa 1: Build
# Compilar el proyecto, obtener imagen base de mvn para compilar el pom,
FROM maven:3.9-eclipse-temurin-21 AS build

# Generar firectorio
WORKDIR /app

# Copiar el pom
COPY pom.xml .

RUN mvn dependency:go-offline -B

# Copiar todo lo que se tiene al directorio del trabajo
COPY src ./src

# Compilar todo el proyecto sin conciliar todos los metodos que se tengan o no
RUN mvn clean package -DskipTests



# Etapa 2  Runtime
# Generar el entorno de ejecución, obtener imagen jdk
FROM eclipse-temurin:21-jre-jammy

# Generar directorio
WORKDIR /app

# Copiar el jar a ese direcorio
COPY --from=build /app/target/*.jar app.jar

# Cuando se levante se expone al 8081, por si solo no ejecuta el jar
EXPOSE 8080

# Se pasa el fragmento del comando a doker para correr el jar
ENTRYPOINT ["java", "-jar", "app.jar"]

