FROM maven:3.10.2-eclipse-temurin-25-noble AS build
WORKDIR /workspace
COPY pom.xml .
COPY src src
RUN mvn -B verify

FROM eclipse-temurin:25-jre-noble
WORKDIR /app
COPY --from=build /workspace/target/dehiwala-zoo-api-0.1.0-SNAPSHOT.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
