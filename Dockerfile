################ Build Stage ################
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /workspace
COPY pom.xml .
RUN mvn -q -e -DskipTests dependency:go-offline
COPY src ./src
RUN mvn -q -DskipTests package

################ Prep Stage ################
FROM eclipse-temurin:21-jre-jammy AS prep
WORKDIR /app

COPY --from=build /workspace/target/*.jar app.jar

RUN mkdir -p /app/tmp && chmod 1777 /app/tmp

# Extract Spring Boot layers to separate layers
RUN java -Djarmode=layertools -jar app.jar extract

################# Runtime stage #####################
FROM gcr.io/distroless/java21:nonroot

WORKDIR /app

# Copy extracted layers from build stage
COPY --from=prep /app/dependencies/ ./
COPY --from=prep /app/spring-boot-loader/ ./
COPY --from=prep /app/snapshot-dependencies/ ./
COPY --from=prep /app/application/ ./

COPY --from=prep --chown=65532:65532 /app/tmp /app/tmp

ENV JAVA_TOOL_OPTIONS="-Djava.io.tmpdir=/app/tmp -XX:+UseG1GC -XX:MaxRAMPercentage=75"

EXPOSE 8080

ENTRYPOINT ["java", "org.springframework.boot.loader.launch.JarLauncher"]