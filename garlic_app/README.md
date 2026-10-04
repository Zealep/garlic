# garlic_app

App de campo de Garlic (Flutter): **evaluación de lotes de ajo** y **compra del lote** (precio, camiones, gastos,
pagos y balance hasta la materia prima puesta en packing).
Celular primero, adaptable a tablet y laptop, y **funciona sin conexión**.

## Correr
```bash
# 1. Backend (desde la raíz del repo)
docker compose up -d
cd garlicbackend && ./mvnw spring-boot:run -Dspring-boot.run.profiles=dev

# 2. App
cd garlic_app
flutter pub get
flutter run -d chrome          # web / laptop (servidor: http://localhost:8080)
flutter run                    # emulador Android (servidor: http://10.0.2.2:8080)
```
Primer uso: la pantalla **Configurar** conecta al servidor, elige la empresa (endpoint `/dev/empresas`,
solo perfil dev) y el evaluador, y descarga catálogos y lotes para trabajar sin red.

> En Windows, compilar para Android/escritorio con plugins requiere activar el **Modo desarrollador**
> (soporte de symlinks): `start ms-settings:developers`.

## Verificar
```bash
flutter analyze   # sin issues
flutter test      # reglas, promedios del Excel, motor de sincronización, componentes
```

## Arquitectura (guía oficial: flutter-apply-architecture-best-practices)
```
lib/
├── data/
│   ├── services/        ApiClient (Dio, ProblemDetail → AppFailure), ConectividadService,
│   │                    local/ AppDatabase (Drift/SQLite; wasm en web) + KvStore
│   └── repositories/    Config, Catalogos, Lotes, Evaluaciones, Compra, Sync (motor offline)
├── domain/
│   ├── models/          Lote, EvaluacionBorrador, FormularioEvaluacion, CompraLote (fijación, carga, gasto, pago), SyncState…
│   └── use_cases/       ReglasEvaluacion, CalculoCompra y ReglasCompra (mismas fórmulas y reglas que el backend)
├── ui/
│   ├── core/            theme/ (tokens de marca), widgets/, layout/ (breakpoints, shell adaptable)
│   └── features/        setup · inicio · lotes · evaluacion · compra · catalogos · sync  (view_models/ + views/)
├── routing/             go_router (shell con navegación adaptable + rutas a pantalla completa)
├── config/              Dependencias (provider)
└── utils/               Result, Command, Formato
```
- **MVVM**: ViewModels `ChangeNotifier` con `Command` para acciones asíncronas; vistas con `ListenableBuilder`.
- **Offline-first**: se escribe primero en SQLite y se encola en una *outbox*. `SyncRepository` envía en orden
  cuando hay red (al encolar, al volver la conexión, cada 45 s y a pedido), con backoff exponencial.
  Los IDs los genera el teléfono y el backend crea de forma idempotente → reintentar no duplica.
  Errores de negocio (409/422) bloquean la operación y marcan el registro con el mensaje del servidor.
  La compra (punto 3) usa operaciones genéricas `recursoGuardar` (PUT upsert) y `recursoEliminar` (DELETE; 404 = hecho).
- **Catálogos**: pantalla genérica (en línea) definida por `DefinicionCatalogo.todas`; agregar un catálogo nuevo
  del backend a la app = agregar su definición (campos y tipo de control).
- **Adaptable** (flutter-build-responsive-layout): `< 600` barra inferior · `600–1024` riel · `> 1024` sidebar,
  paneles lado a lado y ancho máximo. El wizard en laptop muestra pasos + formulario + resumen en vivo.
- **Marca**: `design-system/garlic/MASTER.md` → `lib/ui/core/theme/` (morado ajo, marfil, verde tallo, ámbar cosecha;
  Bricolage Grotesque + Inter empaquetadas para funcionar sin red).

## Probar el modo sin conexión
1. Con la app abierta, detén el backend.
2. Registra un lote (la zona repetida se valida también sin red) y evalúalo: todo queda "Pendiente".
3. Levanta el backend: la cola se envía sola (o desde **Sincronizar**) y los registros pasan a "Sincronizado".
