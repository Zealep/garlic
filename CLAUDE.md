# App Garlic — contexto para Claude Code

Sistema de compra de ajo en campo **dedicado a una sola empresa**: **Agroexportadora Guadalupe** (la de un amigo
del usuario; web agroguadalupe.com). La app lleva su marca (logo, verde y naranja).
**No es un SaaS** (decisión 2026-10-19): no se diseña para otros clientes. La columna `empresa_id` se conserva en el
modelo (el servidor la llena con la empresa de la instalación) para no reestructurar la base.
Idioma del proyecto: **español** (código de dominio, UI, docs y respuestas).

## Fuente de requisitos
Excel del cliente "N°1 EVALUACION CAMPO AJO 2025", hoja **"LOTE #XXX MODELO - VARIEDAD - C"** (protocolo de compra en campo):
1. Identificación del lote → módulo `lote` ✅
2. Calidad del lote → módulo `evaluacion` (+ evidencias) ✅
3. Pesos / precio / abonos / saldos → módulo `compra` ✅ (fijación de precio, cargas, gastos vinculados, pagos y balance;
   fórmulas en `docs/modelo-datos/02-compra-lote.md`). El MVP termina con la materia prima puesta en packing.

## Decisiones acordadas con el cliente
- Modelo **híbrido**: una tabla por objeto + catálogos configurables por empresa.
- **Humedad**: SI/NO por indicador (2026-11-02; antes BAJA/MEDIA/ALTA); la columna "stand by" es futura.
- **ZONA** es un solo texto y es la clave antiduplicados: no puede haber dos lotes activos con la misma zona en la campaña.
- **Código del lote** (2026-10-19): correlativo por campaña **asignado por el servidor** (`LOTE 001`, `002`…; reinicia en
  cada campaña, los anulados no liberan su número). La app muestra un número provisional hasta sincronizar.
- **Un lote puede tener varias evaluaciones.** Cada evaluación: `BORRADOR` → `CERRADA` y luego un **resultado**:
  `ACEPTADA`, `RECHAZADA` o `SIN_ACUERDO` (no se cerró precio con el agricultor); null = pendiente, se puede corregir.
- **La compra no depende del resultado**: un lote rechazado puede comprarse por necesidad de producto (solo se avisa).
  La compra es **por lote** (no por evaluación).
- **Seguimiento**: "Próximos cortes" (Inicio y filtro en Lotes) según `fecha_corte`: es cuando se vuelve al campo a cerrar.
- **Comparar evaluaciones** (2026-10-21, solo app): 2 evaluaciones **cerradas** (de lotes distintos o del mismo), desde la
  bandeja ("Comparar") o el detalle del lote. Resalta el mejor valor **solo** donde la dirección es clara (más % de la
  primera clase, más valor por kg, menos enfermedades/incidencia/% parálisis/daños sobre todas las muestras;
  "NO CONTIENE" no es daño) y calcula el precio técnico de ambas con **los mismos precios base**. Sin puntaje global (los pesos los tendría que definir el cliente).
- **DNI LC** = DNI a cuyo nombre se emite la liquidación de compra (`lote.titular_liquidacion_id`).
- Fechas arrancado/corte/carga pertenecen al **lote**; el **tipo de compra lo decide el evaluador**.
- **Lote** (2026-11-02): proveedor se registra desde el formulario (como el agricultor); **N° de cuenta o CCI** de quien
  cobra la liquidación (`lote.cuenta_liquidacion`); con **punto GPS la ciudad/CCPP es opcional** (se oculta).
- **Inicio**: primero las **alertas de corte** (resaltadas) y **Pendientes de pago** (`GET /compras/pendientes`).
- **Todo se registra por muestra** (2026-11-02): calidad, calibre, sensoriales (humedad, empaste, daños) y sanidad.
  El wizard es Datos → Muestras → Resumen; cada muestra tiene sus secciones y fotos ("copiar de la muestra anterior").
- **Daños con cantidades** (`tipo_dano.pide_cantidades`, ej. parálisis): frutos total y con problema → % de daño
  automático; obligatorios para cerrar. El resumen destaca la parálisis (PROM y % por muestra).
- **Muestras**: la app asigna su id; al quitar una se **renumeran 1..n** y sus fotos siguen en su muestra (`muestraId`).
- **Calibres**: el evaluador elige del catálogo los calibres de cada muestra (incluye rangos amplios 50/60 y 60/70;
  se permiten superpuestos). **Deben sumar 100 % y son obligatorios para cerrar**; mientras se edita el borrador no se exige.
- Catálogos (clases de calidad, calibres, empaques, gastos, …) se administran desde la app (pestaña **Catálogos**, en línea);
  todo es dinámico: una clase nueva (ej. POROTO) aparece en la evaluación y en la fijación de precio.
- Fotos: generales en Datos y una galería por muestra (calidad, calibre, sensoriales); se suben con el id de la muestra.
- **Acceso** (2026-11-06): login propio con **DNI + contraseña** (sin roles de negocio). JWT HS256 de 8 h + refresh
  token rotativo de 30 días (`sesion_usuario`, solo el hash), para trabajar sin señal. La clave inicial o restablecida
  es temporal (se cambia al entrar). Solo el **administrador** (`rol = ADMIN`) gestiona usuarios. El evaluador de las
  evaluaciones es el usuario logueado. Una sesión vencida no bloquea el outbox: lo pendiente se envía al volver a entrar.
- **Precio**: precio técnico = promedio de (Σ precio base por clase × % de calidad de cada muestra) **− gasto de llenado**;
  luego el precio pactado (manual). Se fija con una evaluación **cerrada**.
- **Cargas**: una por camión; **destare en kg por carga** (2026-11-02; antes %). Total MP = Σ (kg − destare) × precio.
- **Pagos** solo por materia prima; los **gastos vinculados** (estiba, pesaje, flete, otros) van aparte.
  Saldo = total MP − pagos. C.U. MP y C.U. puesto en packing se calculan sobre **kg netos** (packing a 2 decimales).

## Estructura
- `garlicbackend/` — Spring Boot 4.1 / Java 21, monolito modular por feature (ver su README). Skill: `java-springboot`.
- `garlic_app/` — Flutter 3.29 / Dart 3.7, MVVM + repositorios (guía oficial), offline-first con Drift + outbox.
  Skills: `flutter-apply-architecture-best-practices`, `flutter-build-responsive-layout`, además de `ui-ux-pro-max`/`frontend-design` (usuario).
- `design-system/garlic/MASTER.md` — marca Guadalupe "verde + naranja sobre marfil" (fuente de verdad visual).
- `docs/modelo-datos/` — modelo y diccionario de datos.

## Convenciones clave
- **Una sola empresa**: `garlic.instalacion.empresa-ruc` (dev: `00000000000`, prod: `.env`). El servidor fija esa
  empresa en `TenantContext` para cada request; la app **no** envía empresa. El header `X-Empresa-Id` solo se usa en los
  tests de integración (sin RUC configurado) para aislar cada test.
- Esquema solo por **migraciones Flyway nuevas** (`V9__...`); nunca editar una ya aplicada. `ddl-auto=validate`.
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
Empresa demo: RUC `00000000000` (`GET /instalacion/empresa` la devuelve; la app la usa sin elegirla).
Login dev: DNI `40000001` (Evaluador Demo, administrador), clave temporal `garlic2026` (`application-dev.yml`;
se pide cambiarla al entrar; si se olvida: `UPDATE usuario SET clave_hash = NULL WHERE dni = '40000001'` y reiniciar).

## Despliegue
Ver `deploy/DESPLIEGUE.md`: Droplet de DigitalOcean + Docker Compose (Postgres, backend perfil `prod`, Caddy con
HTTPS). La app se instala como PWA en el celular.
- **Pruebas** (actual): `147.182.182.133.sslip.io`, con datos de prueba (se conservan).
- **Producción** (2026-11-06): droplet **nuevo** que comprará el cliente, base limpia (empresa + catálogos base +
  administrador), dominio = subdominio de agroguadalupe.com (ej. `compras.`). Kit listo, aún no desplegado.
- La empresa del cliente se define con `EMPRESA_RUC` en el `.env` del servidor.
- Perfil `prod`: catálogos base y empresa desde `db/inicial/R__instalacion.sql` (placeholders por variables de entorno).

## Pendientes
- [ ] App: enviar lo nuevo directo con `POST` (hoy intenta `PUT` y ante 404 hace `POST`, lo que deja un 404 visible en la consola del navegador).
- [ ] Verificar la app en emulador Android (en Windows requiere Modo desarrollador para compilar con plugins).
- [ ] Roles de negocio: quién registra / quién aprueba (el cliente no lo definió; el login ya existe).
- [ ] Datos de Guadalupe para producción: RUC 20614219824, AGROEXPORTADORA GUADALUPE S.A.C. y administrador (DNI 72790829) ya están en `deploy/.env.produccion` (local, no se sube). Faltan: confirmar subdominio y logo en alta resolución.
- [ ] APK release: `applicationId` propio y firma de release en `garlic_app/android/app/build.gradle.kts`.

Las reglas de negocio implementadas se dan por **definidas** (2026-10-30). No hay preguntas abiertas con el cliente:
si pide cambios, el usuario los informará.
