# garlicbackend

API de Garlic (compra de ajo en campo: lotes, evaluación, compra y pagos). Spring Boot 4.1 · Java 21 · PostgreSQL 16 · Flyway.

## Arranque
```bash
docker compose up -d                                    # desde la raíz del repo
./mvnw spring-boot:run -Dspring-boot.run.profiles=dev   # migra + carga datos demo
```
- Swagger: http://localhost:8080/swagger-ui.html
- Todas las rutas `/api/**` requieren el header `X-Empresa-Id` (UUID de la empresa).
  La empresa demo se consulta con `select id from empresa where ruc='00000000000'`.

## Tests
```bash
./mvnw verify    # unitarios (surefire, *Test) + integración con Testcontainers (failsafe, *IT)
```
Los `*IT` levantan un Postgres real (requiere Docker), aplican las migraciones de Flyway y
cada test crea sus propias empresas, así no dependen de datos previos.

## Arquitectura: monolito modular por feature
```
com.zealep.garlicbackend
├── shared/            Transversal: empresa de la instalación, errores RFC 9457, auditoría, OpenAPI,
│                      almacenamiento de archivos (storage), validaciones comunes
├── catalogo/          Catálogos por empresa (variedades, calibres, enfermedades, …)
│   └── base/          CRUD genérico: CatalogoEntity, AbstractCatalogoService/Controller
├── usuario/           Usuarios de la empresa (el evaluador)
├── tercero/           Personas y sus roles (agricultor, proveedor)
│   └── rol/           Base genérica de roles de persona
├── lote/              Punto 1 del protocolo: identificación del lote
├── evaluacion/        Punto 2 del protocolo: calidad del lote (muestras, factores, promedios)
│   └── evidencia/     Fotos por muestra / generales
└── compra/            Punto 3: fijación de precio, cargas (camiones), gastos vinculados, pagos,
                       comprobantes y balance (CalculoCompra = fórmulas puras)
```
Cada feature contiene su entity, request/response (records), mapper, repository, service y controller.

### Convenciones
- **Una sola empresa**: el sistema es de la agroexportadora del cliente (`garlic.instalacion.empresa-ruc`).
  `TenantInterceptor` fija esa empresa en cada request y toda consulta filtra por `TenantProvider` (la columna
  `empresa_id` se conserva). Solo sin RUC configurado (tests de integración) se toma del header `X-Empresa-Id`.
- **Referencias entre módulos**: se validan con `referenciaActiva(id)` del servicio dueño
  (422 si no existe en la empresa o está inactiva). No se accede al repositorio de otro módulo.
- **Errores**: 400 validación · 404 no existe · 409 duplicado/estado · 422 regla de negocio o referencia inválida.
  Las restricciones de la base (UNIQUE/FK/CHECK) son la red de seguridad y se traducen igual.
- **Borrado**: los catálogos y roles usan baja lógica (`DELETE` → `activo=false`, `PATCH /{id}/activar`);
  el lote se anula (`POST /{id}/anular`).
- **Evaluación**: agregado raíz `EvaluacionLote`. Mientras está en `BORRADOR` cada `PUT` reemplaza el
  contenido completo (las muestras se actualizan en sitio por número para conservar sus fotos);
  `POST /{id}/cerrar` valida que esté completa y la vuelve inmutable. Reglas en `ReglasEvaluacion`.
- **Archivos**: `StorageService` (hoy `LocalStorageService` en `garlic.storage.directorio`);
  para S3 basta otra implementación. Los archivos se borran solo si la transacción confirma.
- **Compra**: cargas, gastos y pagos se guardan con `PUT /lotes/{loteId}/{recurso}/{id}` (upsert idempotente con el
  UUID del cliente: 201 crea, 200 actualiza). Las fórmulas están en `CalculoCompra` y en `docs/modelo-datos/02-compra-lote.md`.
- **Esquema**: solo por migraciones Flyway nuevas (`V6__...`); Hibernate valida (`ddl-auto=validate`).

### Agregar un catálogo nuevo
1. Migración con la tabla (estructura común: `empresa_id, cultivo_id, codigo, nombre, orden, activo` + auditoría).
2. Entity que extienda `CatalogoCultivoEntity`, request/response, `@Mapper` que extienda `CatalogoMapper`,
   repository que extienda `CatalogoRepository`, service que extienda `AbstractCatalogoService`
   y controller que extienda `AbstractCatalogoController`.
3. Agregar el caso a `CatalogoCrudIT#catalogos()`.
