# App Garlic

Sistema de compra de **ajo** en campo para una agroexportadora: identificación y evaluación de lotes,
fijación de precio, camiones, gastos, pagos y balance hasta la materia prima puesta en packing.
App móvil/web que funciona sin conexión.

| Carpeta | Contenido |
|---|---|
| `garlicbackend/` | API Spring Boot 4 · Java 21 · PostgreSQL · Flyway ([README](garlicbackend/README.md)) |
| `garlic_app/` | App Flutter offline-first para celular, tablet y laptop ([README](garlic_app/README.md)) |
| `docs/modelo-datos/` | Modelo de datos y diccionario |
| `design-system/garlic/` | Sistema de diseño (marca "morado ajo + marfil") |
| `database/` | Scripts de prueba del modelo |
| `.agents/skills/` | Skills de Claude Code usados en el proyecto (ver `skills-lock.json`) |

## Levantar todo en local
```bash
docker compose up -d                                              # PostgreSQL
cd garlicbackend && ./mvnw spring-boot:run -Dspring-boot.run.profiles=dev
cd garlic_app && flutter pub get && flutter run -d chrome
```

Requisitos: Docker, Java 21, Flutter 3.29+ (Dart 3.7).
