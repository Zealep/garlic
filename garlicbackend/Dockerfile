# ---- build ----
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /src
COPY pom.xml .
RUN mvn -q -B dependency:go-offline
COPY src src
RUN mvn -q -B package -DskipTests

# ---- runtime ----
FROM eclipse-temurin:21-jre
RUN useradd --system --uid 1001 garlic && mkdir -p /data/evidencias && chown -R garlic /data
USER garlic
WORKDIR /app
COPY --from=build /src/target/*.jar app.jar
ENV SPRING_PROFILES_ACTIVE=prod \
    JAVA_OPTS="-XX:MaxRAMPercentage=60 -XX:+ExitOnOutOfMemoryError"
EXPOSE 8080
ENTRYPOINT ["sh", "-c", "exec java $JAVA_OPTS -jar app.jar"]
