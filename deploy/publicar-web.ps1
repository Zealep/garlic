# Compila la app web y la copia al servidor (ejecutar en Windows, desde la raiz del repo).
# Uso: .\deploy\publicar-web.ps1 -Servidor root@164.90.12.34
param([Parameter(Mandatory = $true)][string]$Servidor)
$ErrorActionPreference = 'Stop'
Push-Location garlic_app
try {
    # --no-web-resources-cdn: CanvasKit se sirve desde el propio servidor (funciona sin conexion)
    flutter build web --release --no-web-resources-cdn
    if ($LASTEXITCODE -ne 0) { throw 'flutter build web fallo' }
} finally { Pop-Location }
ssh $Servidor "rm -rf /opt/garlic/deploy/web.nueva && mkdir -p /opt/garlic/deploy/web.nueva"
scp -r garlic_app/build/web/* "${Servidor}:/opt/garlic/deploy/web.nueva/"
ssh $Servidor "cd /opt/garlic/deploy && rm -rf web.anterior && (mv web web.anterior 2>/dev/null || true) && mv web.nueva web && docker compose restart caddy"
Write-Host 'App web publicada.'
