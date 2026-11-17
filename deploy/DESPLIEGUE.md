# Despliegue (instalación dedicada a Agroexportadora Guadalupe)

Sirve para los dos servidores:
- **Pruebas** (actual): `147.182.182.133.sslip.io`, con datos de prueba.
- **Producción** (droplet nuevo, aún por comprar): `compras.agroguadalupe.com` (o el subdominio que elijan),
  base limpia. Ver **[Producción Guadalupe](#producción-guadalupe-droplet-nuevo)** al final.

Cada persona entra con **su DNI y su contraseña** (login propio de la app). El sistema es **solo para su empresa**.

```
Internet ──HTTPS──► Caddy (certificado automático)
                     ├── /            app web (PWA, se instala en el celular)
                     └── /api, /instalacion ──► backend Spring Boot (perfil prod) ──► PostgreSQL
```
Todo corre con Docker Compose en un solo servidor. La base de datos no se expone a internet.

## 0. Qué contratar (recomendación)

| | Recomendado para la prueba |
|---|---|
| Servidor | **DigitalOcean Droplet** Basic · Regular · **2 GB RAM / 1 vCPU / 50 GB** (~US$12/mes) |
| Región | **NYC1/NYC3** o **SFO3** (las más cercanas a Perú entre las de DO) |
| Sistema | **Ubuntu 24.04 LTS** |
| Extras | **Backups semanales del droplet** (+20 %, ~US$2.4/mes) |
| Dominio | Pruebas: `IP.sslip.io`. Producción: **subdominio de agroguadalupe.com** (registro DNS tipo A) |

Por qué un droplet: es simple, barato, con precio fijo y suficiente para 1 empresa con pocos usuarios.
El mismo `docker-compose.yml` sirve luego en cualquier otro proveedor (Hetzner, AWS Lightsail, etc.).
2 GB es lo mínimo cómodo (Java + Postgres + compilación de la imagen); con 1 GB habría que precompilar.

## 1. Crear el droplet
1. En tu PC (PowerShell), si no tienes llave SSH: `ssh-keygen -t ed25519` (Enter a todo).
   Copia el contenido de `C:\Users\<tu usuario>\.ssh\id_ed25519.pub`.
2. DigitalOcean → **Create → Droplets** → Ubuntu 24.04 · Basic · Regular 2 GB · región NYC/SFO →
   **Authentication: SSH Key** (pega la llave) → activa **Backups** → nombre `garlic-pruebas` → Create.
3. Anota la **IP pública** (ej. `164.90.12.34`).
4. **Networking → Firewalls → Create**: entrada solo **SSH (22), HTTP (80), HTTPS (443)**; aplícalo al droplet.

## 2. Preparar el servidor (una sola vez)
```bash
ssh root@164.90.12.34

# actualizaciones automáticas de seguridad + swap de 2 GB (ayuda al compilar)
apt update && apt -y upgrade && apt -y install unattended-upgrades git
fallocate -l 2G /swapfile && chmod 600 /swapfile && mkswap /swapfile && swapon /swapfile
echo '/swapfile none swap sw 0 0' >> /etc/fstab
timedatectl set-timezone America/Lima

# Docker
curl -fsSL https://get.docker.com | sh
```

## 3. Bajar el proyecto
El repositorio es privado o público: si es **privado**, crea una *deploy key* de solo lectura:
```bash
ssh-keygen -t ed25519 -f ~/.ssh/garlic_deploy -N ''
cat ~/.ssh/garlic_deploy.pub     # GitHub → repo → Settings → Deploy keys → Add (sin escritura)
printf 'Host github.com\n  IdentityFile ~/.ssh/garlic_deploy\n' >> ~/.ssh/config
```
```bash
git clone git@github.com:Zealep/garlic.git /opt/garlic
cd /opt/garlic/deploy
cp .env.example .env
```

## 4. Configurar `.env`
```bash
openssl rand -base64 24     # DB_PASSWORD
openssl rand -base64 48     # JWT_SECRET
nano .env
```
- `DOMINIO`: el subdominio (antes crea el registro **A** hacia la IP del droplet) o, para pruebas,
  la IP + `.sslip.io` (ej. `164-90-12-34.sslip.io`).
- `EMPRESA_RUC` / `EMPRESA_RAZON_SOCIAL`: Agroexportadora Guadalupe (el sistema trabaja solo con ella).
- `ADMIN_NOMBRE` / `ADMIN_DNI` / `ADMIN_CLAVE_INICIAL`: el **administrador**. Entra con su DNI y esa clave
  temporal; en el primer ingreso la app le pide crear su propia contraseña. `ADMIN_EMAIL` es opcional.
- `JWT_SECRET`: firma de las sesiones (si se cambia, todos vuelven a iniciar sesión).
- `DB_PASSWORD`: la clave de la base.

## 5. Levantar
```bash
cd /opt/garlic/deploy
mkdir -p web
docker compose up -d --build        # la primera vez tarda unos minutos (compila el backend)
docker compose logs -f backend      # esperar "Started GarlicbackendApplication"
```
Al arrancar, Flyway crea las tablas, la empresa, sus catálogos base (variedades, calidades, calibres,
empaques, gastos, condiciones de pago…) y el administrador; el backend le asigna la clave temporal
(`ADMIN_CLAVE_INICIAL`, solo si aún no tiene una). **No carga datos demo.**

## 6. Publicar la app web (desde tu PC con Windows)
En la raíz del repo:
```powershell
powershell -ExecutionPolicy Bypass -File .\deploy\publicar-web.ps1 -Servidor root@164.90.12.34
```
(`-ExecutionPolicy Bypass` es necesario porque Windows bloquea los scripts `.ps1` por defecto; solo aplica a esta
ejecución. Alternativa permanente para tu usuario: `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`.)
Compila la app (`flutter build web --release --no-web-resources-cdn`) y la copia al servidor.
Repite este paso cada vez que cambie la app.

## 7. Probar
1. Abre `https://DOMINIO` → **Iniciar sesión** con `ADMIN_DNI` y `ADMIN_CLAVE_INICIAL`.
2. La app pide crear la contraseña personal del administrador.
3. Menú de cuenta (avatar) → **Usuarios** → **Nuevo usuario** para cada evaluador (nombres, DNI y una
   contraseña temporal que la app sugiere). Entrégale su DNI y la temporal: al entrar la cambia.
4. Verifica: `https://.../actuator/health` responde `{"status":"UP"}`.

## 8. Instalar en el celular (fase de pruebas: PWA, sin tienda)
- **Android (Chrome)**: abrir la URL → iniciar sesión → menú ⋮ → **Instalar aplicación** /
  "Agregar a la pantalla principal". Queda con su ícono, a pantalla completa, y **funciona sin señal**
  después de la primera carga (los datos se guardan en el teléfono y se sincronizan al volver la red).
  La cámara funciona desde la app para las fotos.
- **iPhone (Safari)**: Compartir → **Agregar a inicio**. Funciona, pero iOS puede borrar los datos locales
  de apps web que no se usan en semanas: sincronizar seguido.
- **Laptop**: el mismo enlace en Chrome/Edge (también se puede "instalar").

Más adelante (cuando se valide): **APK de Android** con
`flutter build apk --release --dart-define=API_URL=https://su-dominio`, que se instala directo
(compartiendo el archivo) o por **Google Play – prueba interna** (cuenta de desarrollador US$25 pago único).
El login ya existe; antes de la APK falta su `applicationId` y la firma de release.

## 9. Actualizar a una versión nueva
```bash
cd /opt/garlic && git pull
cd deploy && docker compose up -d --build backend
```
y desde tu PC `.\deploy\publicar-web.ps1 -Servidor root@IP` si cambió la app.
Las migraciones de base se aplican solas y nunca borran datos.

## 10. Respaldos
```bash
chmod +x /opt/garlic/deploy/backup.sh
crontab -e
# respaldo diario a las 02:30 (base + fotos, conserva 14 días en /opt/garlic/backups)
30 2 * * * /opt/garlic/deploy/backup.sh >> /var/log/garlic-backup.log 2>&1
```
Además de los backups del droplet, descarga de vez en cuando `/opt/garlic/backups` a tu PC
(`scp -r root@IP:/opt/garlic/backups .`). Restaurar la base:
`docker compose exec -T db pg_restore -U garlic -d garlic --clean < garlic-AAAA-MM-DD.dump`.

## 11. Operación diaria
| Tarea | Comando (en `/opt/garlic/deploy`) |
|---|---|
| Ver estado | `docker compose ps` |
| Logs | `docker compose logs -f backend` / `caddy` |
| Reiniciar | `docker compose restart backend` |
| Olvido de contraseña | el administrador asigna una temporal desde **Usuarios** |
| Administrador sin acceso | `docker compose exec db psql -U garlic -c "UPDATE usuario SET clave_hash = NULL WHERE dni = 'DNI'"` y reiniciar el backend (vuelve a tomar `ADMIN_CLAVE_INICIAL`) |
| Empezar de cero (borra TODO) | `docker compose down -v` |

Monitoreo gratuito: [UptimeRobot](https://uptimerobot.com) apuntando a `https://DOMINIO/actuator/health`.

## Seguridad
- **Login por persona** (DNI + contraseña, guardada como hash BCrypt) + **HTTPS**. Cada registro guarda quién
  lo creó/modificó (`created_by` / `updated_by`).
- Sesión: token de acceso de 8 h + sesión de **30 días** que se renueva con el uso (el evaluador trabaja sin
  señal en campo). Cerrar sesión, cambiar la contraseña, restablecerla o desactivar al usuario la invalidan.
- 5 intentos fallidos seguidos bloquean ese DNI 15 minutos.
- Sin roles de negocio todavía: todos pueden registrar todo; solo el **administrador** gestiona usuarios.
- El sistema es de **una sola empresa** (`EMPRESA_RUC`): el servidor la fija en cada consulta; la app no la envía.
- Swagger/OpenAPI está desactivado en producción. Postgres no tiene puertos públicos.

## Producción Guadalupe (desplegado 2026-11-17)
Se usó el droplet **existente** de agroguadalupe.com (`143.198.121.232`, 1 vCPU / 2 GB + 2 GB swap), que ya tiene
nginx en 80/443 (web de la empresa con certbot) y la app "liberty". Por eso **no se levanta Caddy**:
- `.env` con `COMPOSE_FILE=docker-compose.yml:docker-compose.nginx.yml`: el backend escucha en `127.0.0.1:8090`
  (máx. 900 MB de RAM) y Caddy queda apagado.
- nginx: sitio propio `/etc/nginx/sites-available/compras.conf` (copia de `nginx-compras.conf`) que sirve
  `/opt/garlic/deploy/web` y pasa `/api`, `/instalacion` y `/actuator/health` al backend. HTTPS con
  `certbot --nginx -d compras.agroguadalupe.com` (se renueva solo, igual que la web).
- El droplet **no tiene acceso a GitHub**: el código se copia desde la PC (backend + deploy, sin `.env`):
  ```bash
  { git ls-files; git ls-files --others --exclude-standard; } | grep -E "^(deploy|garlicbackend)/" \
    | grep -v "^deploy/\.env" | tar -czf - -T - | ssh root@143.198.121.232 "tar -xzf - -C /opt/garlic"
  ssh root@143.198.121.232 "cd /opt/garlic/deploy && docker compose up -d --build backend"
  ```
  y la app web con `.\deploy\publicar-web.ps1 -Servidor root@143.198.121.232` (no reinicia nada más).

## Producción Guadalupe (droplet nuevo, alternativa)
Base **limpia**: solo la empresa, sus catálogos base, la campaña y el administrador (sin lotes ni compras de prueba).
1. **Droplet**: como en los pasos 0–2, nombre `guadalupe-produccion`. Para el uso real conviene **4 GB RAM / 2 vCPU**
   con backups activados.
2. **DNS**: quien administra el dominio `agroguadalupe.com` crea un registro **A**
   `compras` → IP del droplet nuevo (TTL 300). Comprobar con `nslookup compras.agroguadalupe.com`
   antes de levantar (Caddy necesita que el dominio ya apunte para emitir el certificado).
3. Pasos 3–6 con el `.env` de producción. Ya está preparado en la PC de desarrollo como `deploy/.env.produccion`
   (no se sube al repo): RUC 20614219824, AGROEXPORTADORA GUADALUPE S.A.C., administrador Cristian Flores
   (DNI 72790829) con su clave temporal, y `JWT_SECRET`/`DB_PASSWORD` **nuevos** generados al azar.
   Copiarlo al droplet: `scp deploy/.env.produccion root@IP_NUEVA:/opt/garlic/deploy/.env`
   y revisar `DOMINIO` si eligen otro subdominio.
4. Publicar la app con `publicar-web.ps1 -Servidor root@IP_NUEVA`.
5. Primer ingreso del administrador, alta de evaluadores (paso 7) y configurar respaldos (paso 10).
6. En los celulares: instalar la PWA desde el dominio nuevo (la de pruebas queda aparte, con sus datos),
   o la APK (abajo).

### APK Android (producción)
- Paquete `com.agroguadalupe.compras`, firmada con la llave de Guadalupe: `garlic_app/android/key.properties` +
  `garlic_app/android/app/guadalupe-release.jks` (no se suben al repo). **Respaldarlas** fuera de la PC (USB/nube
  privada): sin esa llave Android no acepta actualizaciones de la APK instalada y habría que desinstalar.
- Compilar (el servidor queda fijo en la APK):
  `flutter build apk --release --dart-define=API_URL=https://compras.agroguadalupe.com`
  y copiar `build/app/outputs/flutter-apk/app-release.apk` a `entregables/Guadalupe-X.Y.Z.apk`.
- Cada versión nueva sube `version:` en `pubspec.yaml` (ej. `1.0.1+2`; el `+N` debe crecer) para que se instale
  encima sin perder datos.
- Instalar: enviar el archivo al celular (WhatsApp/Drive/cable), abrirlo y permitir "instalar apps desconocidas".

## Servidor de pruebas: pasar al login
El servidor actual conserva sus datos. Al actualizarlo (paso 9):
1. En `.env`: quitar `ACCESO_USUARIO`/`ACCESO_HASH` y agregar `ADMIN_DNI`, `ADMIN_CLAVE_INICIAL` y `JWT_SECRET`.
2. El administrador ya existía sin DNI: asignárselo una vez
   `docker compose exec db psql -U garlic -c "UPDATE usuario SET dni = 'DNI' WHERE rol = 'ADMIN' AND dni IS NULL"`
   (antes de `docker compose up -d --build backend`, o reiniciar el backend después).
3. `docker compose up -d --build` (recrea Caddy sin usuario/clave compartidos) y publicar la app.
