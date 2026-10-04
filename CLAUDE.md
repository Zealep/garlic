# App Garlic — contexto para Claude Code

SaaS agrícola (inicio: **ajo**) para la agroexportadora de un amigo del usuario, pensado para ofrecerse luego
a otras empresas (**multi-tenant desde el día 1**; RLS de PostgreSQL diferido hasta el 2.º cliente).
Idioma del proyecto: **español** (código de dominio, UI, docs y respuestas).

## Fuente de requisitos
Excel del cliente "N°1 EVALUACION CAMPO AJO 2025", hoja **"LOTE #XXX MODELO - VARIEDAD - C"** (protocolo de compra en campo):
1. Identificación del lote → módulo `lote` ✅
2. Calidad del lote → módulo `evaluacion` (+ evidencias) ✅
3. Pesos / precio / abonos / saldos → módulo `compra` ✅ (fijación de precio, cargas, gastos vinculados, pagos y balance;
   fórmulas en `docs/modelo-datos/02-compra-lote.md`). El MVP termina con la materia prima puesta en packing.

## Decisiones acordadas con el cliente
- Modelo **híbrido**: una tabla por objeto + catálogos configurables por empresa.
- **Humedad**: solo nivel BAJA/MEDIA/ALTA por tipo; la columna "stand by" es futura.
- **ZONA** es un solo texto y es la clave antiduplicados: no puede haber dos lotes activos con la misma zona en la campaña.
- **DNI LC** = DNI a cuyo nombre se emite la liquidación de compra (`lote.titular_liquidacion_id`).
- Fechas arrancado/corte/carga pertenecen al **lote**; el **tipo de compra lo decide el evaluador**.
- Calidad y calibre se registran **por muestra**; humedad, empaste, daños y sanidad **por evaluación**.
- **Calibres**: el evaluador elige del catálogo los calibres de cada muestra (incluye rangos amplios 50/60 y 60/70;
  se permiten superpuestos). **Deben sumar 100 % y son obligatorios para cerrar**; mientras se edita el borrador no se exige.
- Catálogos (clases de calidad, calibres, empaques, gastos, …) se administran desde la app (pestaña **Catálogos**, en línea);
  todo es dinámico: una clase nueva (ej. POROTO) aparece en la evaluación y en la fijación de precio.
- Fotos: se toman dentro de cada sección (Datos = generales, cada muestra, Sensoriales); Sanidad no lleva fotos.
- **Precio**: precio técnico = promedio de (Σ precio base por clase × % de calidad de cada muestra) **− gasto de llenado**;
  luego el precio pactado (manual). Se fija con una evaluación **cerrada**.
- **Cargas**: una por camión; **destare = % por carga** (sugerido 1 %). Total MP = Σ (kg − destare) × precio.
- **Pagos** solo por materia prima; los **gastos vinculados** (estiba, pesaje, flete, otros) van aparte.
  Saldo = total MP − pagos. C.U. MP y C.U. puesto en packing se calculan sobre **kg netos**.

## Estructura
- `garlicbackend/` — Spring Boot 4.1 / Java 21, monolito modular por feature (ver su README). Skill: `java-springboot`.
- `garlic_app/` — Flutter 3.29 / Dart 3.7, MVVM + repositorios (guía oficial), offline-first con Drift + outbox.
  Skills: `flutter-apply-architecture-best-practices`, `flutter-build-responsive-layout`, además de `ui-ux-pro-max`/`frontend-design` (usuario).
- `design-system/garlic/MASTER.md` — marca "morado ajo + marfil" (fuente de verdad visual).
- `docs/modelo-datos/` — modelo y diccionario de datos.

## Convenciones clave
- Tenant por header `X-Empresa-Id` (hasta agregar JWT); nunca confiar en el body.
- Esquema solo por **migraciones Flyway nuevas** (`V6__...`); nunca editar una ya aplicada. `ddl-auto=validate`.
- Errores: 400 validación · 404 · 409 duplicado/estado · 422 regla de negocio (ProblemDetail RFC 9457).
- IDs UUID generados por el cliente para sincronización idempotente (lote, evaluación, evidencia, carga, gasto, pago,
  comprobante). Lo nuevo del punto 3 usa **PUT upsert** (201/200), así no hay 404 al sincronizar.
- Tests obligatorios al agregar funcionalidad: `./mvnw verify` (backend) y `flutter analyze && flutter test` (app).
- No subir secretos (`.env`) ni datos locales (`data/`).

## Cómo levantar
```bash
docker compose up -d
cd garlicbackend && ./mvnw spring-boot:run -Dspring-boot.run.profiles=dev     # :8080, datos demo
cd garlic_app && flutter run -d chrome                                        # o emulador Android (10.0.2.2)
```
Empresa demo: RUC `00000000000` (la app lista las empresas vía `/instalacion/empresas`).

## Despliegue (servidor de pruebas del cliente)
Ver `deploy/DESPLIEGUE.md`: Droplet de DigitalOcean + Docker Compose (Postgres, backend perfil `prod`, Caddy con
HTTPS y usuario/clave). La app se instala como PWA en el celular.
- **Instalación dedicada** (decisión 2026-10-04): por ahora el sistema es solo para el cliente. Con
  `garlic.instalacion.empresa-ruc` definido, el API rechaza otras empresas (403) y la app no muestra selector.
  El código multiempresa queda intacto para el SaaS futuro.
- Perfil `prod`: catálogos base y empresa desde `db/inicial/R__instalacion.sql` (placeholders por variables de entorno).

## Pendientes
- [ ] App: enviar lo nuevo directo con `POST` (hoy intenta `PUT` y ante 404 hace `POST`, lo que deja un 404 visible en la consola del navegador).
- [ ] Verificar la app en emulador Android (en Windows requiere Modo desarrollador para compilar con plugins).
- [ ] Autenticación JWT (reemplaza el header de tenant y el usuario/clave compartido de Caddy); necesaria antes de la APK.
- [ ] Confirmar con el cliente (punto 3): modalidades "Precio Barre/Escoba" (hoja DATOS), si POROTO es clase de calidad,
      qué significa la condición CREDITO y si la liquidación se cierra (inmutable) al pagar.
- [ ] Confirmar con el cliente: duplicado de zona por campaña, orden de fechas del lote,
      motivo de anulación del lote.
