# Base de datos – App Garlic

PostgreSQL 16 en Docker. El **esquema lo crea y versiona Flyway** desde el backend.
Modelo documentado en `docs/modelo-datos/01-identificacion-calidad-lote.md`.

## Dónde están los scripts
```
garlicbackend/src/main/resources/db/
  migration/               # Se aplican en TODOS los ambientes
    V1__schema.sql         # Tipos, tablas, constraints, índices, triggers
    V2__views.sql          # Vistas de promedios (PROM)
    V3__cultivo_base.sql   # Datos de referencia globales (cultivo AJO)
  seed/                    # Solo perfil dev
    R__seed_demo.sql       # Empresa demo + catálogos del Excel (repetible e idempotente)
database/test/
  demo_lote_kevin.sql      # Carga el lote modelo y valida (hace ROLLBACK)
```

## Reglas para cambiar el esquema
- **Nunca** edites una migración `V*` ya aplicada: crea una nueva (`V4__descripcion.sql`, …).
- `R__seed_demo.sql` se re-ejecuta cuando cambia su contenido; debe seguir siendo idempotente (`ON CONFLICT DO NOTHING`).
- Hibernate corre con `ddl-auto=validate`: si una entidad no coincide con el esquema, la app no arranca (y los tests fallan).

## Uso
```bash
docker compose up -d                          # Postgres vacío en localhost:5432 (garlic/garlic)
cd garlicbackend
./mvnw spring-boot:run -Dspring-boot.run.profiles=dev   # Flyway migra + seed demo

# Id de la empresa demo (para el header X-Empresa-Id)
docker compose exec db psql -U garlic -d garlic -tAc "select id from empresa where ruc='00000000000'"

# Prueba del modelo (con la app ya migrada)
docker compose exec -T db psql -U garlic -d garlic -v ON_ERROR_STOP=1 < database/test/demo_lote_kevin.sql

# Recrear desde cero (BORRA los datos)
docker compose down -v && docker compose up -d
```
