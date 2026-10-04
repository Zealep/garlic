# Despliegue del servidor de pruebas (instalación dedicada al cliente)

Objetivo: que el cliente valide el MVP desde su celular y su laptop en un entorno controlado,
**solo para su empresa**, con HTTPS y acceso restringido.

```
Internet ──HTTPS──► Caddy (certificado automático + usuario/clave)
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
| Dominio | Para empezar **no hace falta** (se usa `IP.sslip.io`); luego un dominio propio (~US$10/año) |

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
# clave de la base
openssl rand -base64 24
# hash de la clave de acceso que le darás al cliente
docker run --rm caddy:2-alpine caddy hash-password --plaintext 'LaClaveQueLeDas'
nano .env
```
- `DOMINIO`: la IP con guiones + `.sslip.io` (ej. `164-90-12-34.sslip.io`) o tu dominio
  (antes crea un registro **A** del dominio a la IP).
- `EMPRESA_RUC` / `EMPRESA_RAZON_SOCIAL`: la empresa de tu amigo. **Es la única que podrá usar la instancia.**
- `ADMIN_NOMBRE` / `ADMIN_EMAIL`: primer usuario (sale como evaluador en la app).
- `DB_PASSWORD`: la clave generada.
- `ACCESO_USUARIO` / `ACCESO_HASH`: usuario y hash de la clave de acceso. **En el `.env` cada `$` del hash va doble (`$$`).**

## 5. Levantar
```bash
cd /opt/garlic/deploy
mkdir -p web
docker compose up -d --build        # la primera vez tarda unos minutos (compila el backend)
docker compose logs -f backend      # esperar "Started GarlicbackendApplication"
```
Al arrancar, Flyway crea las tablas, la empresa, sus catálogos base (variedades, calidades, calibres,
empaques, gastos, condiciones de pago…) y el primer usuario. **No carga datos demo.**

## 6. Publicar la app web (desde tu PC con Windows)
En la raíz del repo:
```powershell
.\deploy\publicar-web.ps1 -Servidor root@164.90.12.34
```
Compila la app (`flutter build web --release --no-web-resources-cdn`) y la copia al servidor.
Repite este paso cada vez que cambie la app.

## 7. Probar
1. Abre `https://164-90-12-34.sslip.io` → pide usuario y clave (los de `ACCESO_*`).
2. La configuración inicial es automática: detecta el servidor y la única empresa; solo eliges el evaluador.
3. Verifica: `https://.../actuator/health` responde `{"status":"UP"}`.

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
Antes de la APK conviene tener **login propio (JWT)**, que reemplaza el usuario/clave compartido.

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
| Cambiar la clave de acceso | nuevo hash en `.env` → `docker compose up -d caddy` |
| Empezar de cero (borra TODO) | `docker compose down -v` |

Monitoreo gratuito: [UptimeRobot](https://uptimerobot.com) apuntando a `https://DOMINIO/actuator/health`.

## Seguridad en esta fase (importante)
- Acceso por **usuario y clave compartidos** (Caddy) + **HTTPS**. Suficiente para una prueba controlada;
  **no** distingue personas: todos los cambios figuran sin autor.
- La instancia es **dedicada**: el API solo atiende a la empresa de `EMPRESA_RUC` (cualquier otra → 403)
  y la app no muestra selector de empresas. Para volver a modo SaaS basta no definir
  `garlic.instalacion.empresa-ruc` (el código multiempresa sigue intacto).
- Swagger/OpenAPI está desactivado en producción. Postgres no tiene puertos públicos.
- Pendiente antes de uso real: **login con usuarios (JWT)** y roles.
