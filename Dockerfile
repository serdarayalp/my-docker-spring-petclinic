# syntax=docker/dockerfile:1

FROM eclipse-temurin:17-jdk-jammy as base

# Arbeitsverzeichnis (Working Directory) für alle nachfolgenden
# Anweisungen im Dockerfile
WORKDIR /app

# Kopiert den Inhalt des .mvn-Verzeichnisses von der Build-Quelle (lokal auf dem Host)
# in das Zielverzeichnis .mvn im Docker-Image.
COPY .mvn/ .mvn

# Kopiert die Dateien mvnw und pom.xml in das aktuelle Arbeitsverzeichnis im Docker-Image
COPY mvnw pom.xml ./

# alle in Projekt definierten Abhängigkeiten auflösen
# und die benötigten JAR-Dateien und Ressourcen herunterladen
RUN ./mvnw dependency:resolve

# Quellcode in das Image einfügen.
COPY src ./src

FROM base as test
RUN ["./mvnw", "test"]

# Docker mitteilen, welchen Befehl Sie ausführen möchten,
# wenn Ihr Image in einem Container ausgeführt wird.
FROM base as development
CMD ["./mvnw", "spring-boot:run", "-Dspring-boot.run.profiles=mysql", "-Dspring-boot.run.jvmArguments='-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:8000'"]

FROM base as build
RUN ./mvnw package

FROM eclipse-temurin:17-jre-jammy as production
EXPOSE 8080
COPY --from=build /app/target/spring-petclinic-*.jar /spring-petclinic.jar
CMD ["java", "-Djava.security.egd=file:/dev/./urandom", "-jar", "/spring-petclinic.jar"]

# Erstellen des Images
# docker build --tag java-docker .

# Ein neues Tag für ein Image erstellen. Es wird kein neues Bild erstellt.
# Das Tag verweist auf dasselbe Image und ist nur eine weitere Möglichkeit, auf das Bild zu verweisen.
# docker tag java-docker:latest java-docker:v1.0.0
