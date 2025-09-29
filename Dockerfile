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

# Environment & JVM tuning
ENV JAVA_TOOL_OPTIONS="-XX:+UseG1GC -XX:MaxRAMPercentage=75"

# Expose the port your app listens on
EXPOSE 8080

# Spring Boot 3 launcher classpath layout
ENTRYPOINT ["java", "org.springframework.boot.loader.launch.JarLauncher"]