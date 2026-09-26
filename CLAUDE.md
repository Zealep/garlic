# App Garlic — contexto para Claude Code

SaaS agrícola (inicio: **ajo**) para la agroexportadora de un amigo del usuario, pensado para ofrecerse luego
a otras empresas (**multi-tenant desde el día 1**; RLS de PostgreSQL diferido hasta el 2.º cliente).
Idioma del proyecto: **español** (código de dominio, UI, docs y respuestas).

## Fuente de requisitos
Excel del cliente "N°1 EVALUACION CAMPO AJO 2025", hoja **"LOTE #XXX MODELO - VARIEDAD - C"** (protocolo de compra en campo):
1. Identificación del lote → módulo `lote` ✅
2. Calidad del lote → módulo `evaluacion` (+ evidencias) ✅
3. Pesos / precio / abonos / saldos → **pendiente**; primero hay que modelar sus tablas con el cliente.

## Decisiones acordadas con el cliente
- Modelo **híbrido**: una tabla por objeto + catálogos configurables por empresa.
- **Humedad**: solo nivel BAJA/MEDIA/ALTA por tipo; la columna "stand by" es futura.
- **ZONA** es un solo texto y es la clave antiduplicados: no puede haber dos lotes activos con la misma zona en la campaña.
- **DNI LC** = DNI a cuyo nombre se emite la liquidación de compra (`lote.titular_liquidacion_id`).
- Fechas arrancado/corte/carga pertenecen al **lote**; el **tipo de compra lo decide el evaluador**.
- Calidad y calibre se registran **por muestra**; humedad, empaste, daños y sanidad **por evaluación**.
- Calibres: por ahora **no** se exige que sumen 100 %.

## Estructura
- `garlicbackend/` — Spring Boot 4.1 / Java 21, monolito modular por feature (ver su README). Skill: `java-springboot`.
- `garlic_app/` — Flutter 3.29 / Dart 3.7, MVVM + repositorios (guía oficial), offline-first con Drift + outbox.
  Skills: `flutter-apply-architecture-best-practices`, `flutter-build-responsive-layout`, además de `ui-ux-pro-max`/`frontend-design` (usuario).
- `design-system/garlic/MASTER.md` — marca "morado ajo + marfil" (fuente de verdad visual).
- `docs/modelo-datos/` — modelo y diccionario de datos.

## Convenciones clave
- Tenant por header `X-Empresa-Id` (hasta agregar JWT); nunca confiar en el body.
- Esquema solo por **migraciones Flyway nuevas** (`V4__...`); nunca editar una ya aplicada. `ddl-auto=validate`.
- Errores: 400 validación · 404 · 409 duplicado/estado · 422 regla de negocio (ProblemDetail RFC 9457).
- IDs UUID generados por el cliente para sincronización idempotente (lote, evaluación, evidencia).
- Tests obligatorios al agregar funcionalidad: `./mvnw verify` (backend) y `flutter analyze && flutter test` (app).
- No subir secretos (`.env`) ni datos locales (`data/`).

## Cómo levantar
```bash
docker compose up -d
cd garlicbackend && ./mvnw spring-boot:run -Dspring-boot.run.profiles=dev     # :8080, datos demo
cd garlic_app && flutter run -d chrome                                        # o emulador Android (10.0.2.2)
```
Empresa demo: RUC `00000000000` (la app la lista vía `/dev/empresas`, solo perfil dev).

## Pendientes
- [ ] App: enviar lo nuevo directo con `POST` (hoy intenta `PUT` y ante 404 hace `POST`, lo que deja un 404 visible en la consola del navegador).
- [ ] Verificar la app en emulador Android (en Windows requiere Modo desarrollador para compilar con plugins).
- [ ] Autenticación JWT (reemplaza el header de tenant y el selector de empresa de desarrollo).
- [ ] Punto 3 del protocolo (pesos, precio, abonos, saldos) tras modelarlo con el cliente.
- [ ] Confirmar con el cliente: duplicado de zona por campaña, calibre "<45"/suma 100 %, orden de fechas del lote,
      motivo de anulación del lote.
