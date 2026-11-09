# Guadalupe · Compra de ajo – Design System (MASTER)

> Fuente de verdad visual. Las páginas pueden tener overrides en `pages/<pagina>.md`.
> Base: `ui-ux-pro-max` (reglas UX, checklist) + dirección de marca elegida por el cliente: **Morado ajo + marfil**.
> Implementación: `garlic_app/lib/ui/core/theme/`.

## Marca (2026-11-06)
La app lleva la marca del cliente, **Agroexportadora Guadalupe** (logo, verde y naranja de su web
agroguadalupe.com). Logos en `garlic_app/assets/marca/` (`logo-color.png`, `logo-blanco.png`, `emblema.png`):
son **provisionales de baja resolución** (204×61 y 61 px); reemplazar por SVG o PNG ≥ 1024 px y regenerar
`web/icons/*` y `web/favicon.png`. El patrón sutil de ajos del encabezado se mantiene como decoración del producto.

## Color (tokens)
Los nombres de los tokens no cambiaron (`GColores.primario`, …); solo sus valores.
| Token | Hex | Uso |
|---|---|---|
| `primary` | `#10662F` | Verde Guadalupe: encabezados, botón primario, selección, navegación activa |
| `primaryDeep` | `#0B4521` | Fondos de encabezado, sombras de marca |
| `primarySoft` | `#E8F2EA` | Fondos de selección / chips activos |
| `onPrimary` | `#FFFFFF` | Texto sobre verde (7:1) |
| `secondary` | `#2E8B4E` | Verde hoja: OK, sincronizado, sin humedad |
| `secondarySoft` | `#DDEFE2` | |
| `accent` | `#EC9A2D` | Naranja cosecha: CTA destacado, badges, alertas de corte, gráficos |
| `accentSoft` | `#FCEBD3` | |
| `background` | `#F7F4EC` | Marfil (fondo de app) |
| `surface` | `#FFFFFF` | Tarjetas |
| `surfaceAlt` | `#EFEBDF` | Secciones, inputs |
| `ink` | `#1D2620` | Texto principal |
| `inkMuted` | `#55605A` | Texto secundario (≥ 4.5:1 sobre marfil) |
| `outline` | `#E2E0D6` | Bordes |
| `error` / `warning` / `info` | `#B42318` / `#B8740F` / `#2F6FA3` | Estados |

Reglas: nunca usar el color solo para comunicar (siempre texto/ícono); texto sobre ámbar usa `ink`.

## Tipografía
- **Bricolage Grotesque** (500–800) → títulos, cifras grandes (KPIs), nombre de lote.
- **Inter** (400–700) → texto, formularios, tablas. Números con `tabularFigures` para alinear %.
- Base 16px, interlineado 1.4–1.5, mínimo 12px en metadatos.

## Forma, espacio y elevación
- Espaciado base 4 → escala 4/8/12/16/20/24/32/40.
- Radios: 12 (inputs, chips), 18 (tarjetas), 28 (hojas/paneles).
- Sombras cálidas y bajas (`primaryDeep` al 6–10%); preferir bordes `outline` a sombras duras.
- Targets táctiles ≥ 48dp; separación ≥ 8dp.

## Iconografía e imagen
- **Phosphor** (regular/bold/fill) — nunca emojis.
- Sello de marca: diente de ajo dibujado (CustomPainter), usado en splash, estados vacíos y patrón sutil de encabezados.

## Navegación adaptable (flutter-build-responsive-layout)
- `< 600` compacto: barra inferior (4 destinos).
- `600–1024` medio: `NavigationRail`; listas en grilla.
- `> 1024` expandido: riel extendido tipo sidebar + contenido con ancho máximo y paneles lado a lado.
- Decidir por ancho disponible (`LayoutBuilder` / `MediaQuery.sizeOf`), nunca por "tipo de dispositivo".

## Formularios (ui-ux-pro-max)
- Etiqueta visible siempre (no solo placeholder), ayuda debajo, error junto al campo.
- `Form` + `GlobalKey`, validar al enviar; en el wizard, validar por paso.
- Divulgación progresiva: wizard por pasos con progreso visible y autoguardado.
- Feedback de envío: cargando → éxito/error; estado de sincronización siempre visible.

## Estados offline
- Chip de sincronización global (Sincronizado · N pendientes · Sin conexión · Error).
- Cada registro muestra su estado (punto de color + texto).
- Las acciones nunca se bloquean por falta de red: se guardan localmente y se encolan.

## Checklist antes de entregar
- [ ] Contraste 4.5:1 en texto; 3:1 en componentes
- [ ] Targets ≥ 48dp; foco visible con teclado (tablet/laptop)
- [ ] Sin overflow a 360px, 820px y 1440px
- [ ] Sin emojis como íconos; íconos con `semanticLabel`/tooltip
- [ ] Animaciones 150–300ms; respeta `disableAnimations`
- [ ] Estados vacío / cargando / error / offline en cada pantalla
