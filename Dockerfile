# ==================== Stage 1: Build ====================
FROM maven:3.8.1-openjdk-17-slim AS builder
WORKDIR /build
COPY pom.xml .
RUN mvn dependency:resolve
COPY src/ src/
RUN mvn clean package -DskipTests

# ==================== Stage 2: Runtime ====================
FROM eclipse-temurin:17-jre-alpine

WORKDIR /app

# Tạo non-root user
RUN addgroup -g 1000 appgroup && \
    adduser -D -u 1000 -G appgroup appuser

# Copy JAR
COPY --from=builder /build/target/*.jar /app/app.jar

# Tạo thư mục config trước để tránh lỗi quyền truy cập khi mount volume từ K8s
RUN mkdir -p /app/config && chown -R appuser:appgroup /app

USER appuser

EXPOSE 8080

# Sửa lại ENTRYPOINT: Tất cả tham số phải nằm trong ngoặc vuông
ENTRYPOINT ["java", "-jar", "app.jar", "--spring.config.location=file:/app/config/application.properties"]