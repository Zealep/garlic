# Punto 3 · Compra del lote (precio, cargas, gastos, pagos y balance)

Fuente: hoja **"LOTE #XXX MODELO - VARIEDAD - C"** del Excel, filas 64–98:
3.1 abonos/adelantos · módulo de fijación de precio · 3.2 detalle de la compra · 3.4 balance de pago ·
3.5 total puesto en packing · 3.6 costo unitario. Migración: `V5__compra_lote.sql`.

El flujo del MVP termina con la **materia prima puesta en packing**.

## Decisiones (usuario, 2026-10-03)
- **Gasto de llenado se resta**: precio técnico = promedio de muestras − llenado (como la celda N72 del Excel).
- **Destare = % por carga** (sugerido 1 %, editable; 0 si no aplica). Es el estimado de kg que pierde el ajo.
- **Pagos** solo por la materia prima (al agricultor/proveedor). Los **gastos vinculados** (llevar el producto
  al packing) van aparte y no se descuentan del pago.
- **Costos unitarios separados** y sobre **kg netos** (kg cargados − destare).
- La app trabaja **offline-first**: la fijación de precio se hace en campo frente al agricultor.

## Fórmulas (fuente de verdad: `CalculoCompra.java`; la app replica `calculo_compra.dart`)

| Concepto | Fórmula | Excel |
|---|---|---|
| Precio de la muestra *m* | Σ precio_base[clase] × %calidad[clase, m] / 100 | K70:M70 |
| Precio promedio | promedio(precio de cada muestra) | N70 |
| Precio técnico | precio promedio − gasto de llenado | N72 |
| Ajuste | precio pactado − precio técnico | — |
| Destare (kg) | kg × destare % / 100 | E83 |
| Kg netos de la carga | kg − destare | — |
| Importe de la carga | kg × precio | H81 |
| Descuento por destare | destare (kg) × precio | H83 |
| Total de la carga | importe − descuento | — |
| **Total MP** (pago final al agricultor) | Σ total de cargas | H84 |
| Total pagado | Σ pagos | F75 |
| **Saldo** (balance de pago) | total MP − total pagado | L80 (*) |
| Gastos vinculados | Σ gastos | H92 |
| **Total puesto en packing** | total MP + gastos vinculados | L97 |
| **C.U. materia prima** | total MP / kg netos | — |
| C.U. gastos | gastos vinculados / kg netos | — |
| **C.U. puesto en packing** | total puesto en packing / kg netos | H94 / L98 (*) |

Redondeo HALF_UP: montos a 2 decimales; precios por kg y costos unitarios a 4.

(*) Correcciones al Excel, que tenía fórmulas desordenadas por ediciones:
- L80 calculaba `H92 − F75` (gastos vinculados − abonos). El saldo correcto es **total MP − abonos** (`H84 − F75`).
- H94 ("C.U packing") y L98 ("COST UNIT MP") daban lo mismo, y H94 tenía 29 700 escrito a mano. Ahora:
  C.U. MP = total MP / kg netos y C.U. packing = (MP + gastos) / kg netos.

Estado de pago: `SIN_COMPRAS` · `POR_PAGAR` · `PARCIAL` · `PAGADO` (saldo 0) · `PAGADO_DE_MAS` (saldo < 0: adelanto excedente).

### Ejemplo del Excel (usado en los tests)
- Precios base PRIMERA 3.40 y ABIERTOS 1.40 con PRIMERA 80/85/75 % dan 3.00 / 3.10 / 2.90 por muestra y un **promedio de 3.00**.
- Con llenado 0.30 queda un **técnico de 2.70**; se **pacta en 2.80** (ajuste +0.10).
- 2 camiones × 15 000 kg (375 mallas) a 2.80 con 1 % de destare dan **29 700 kg netos** y **MP S/ 83 160**.
- Gastos: estiba 1 800 + pesaje 30 + flete 900 + otros 70 = **S/ 2 800**.
- Total puesto en packing: **S/ 85 960**. C.U. MP: **2.8000**. C.U. packing: **2.8943**.

## Tablas

### Catálogos (por empresa + cultivo, estructura común)
| Tabla | Campos propios | Semilla demo |
|---|---|---|
| `tipo_empaque` | `peso_referencial_kg` (sugiere la cantidad: kg ÷ peso) | MALLA (40 kg), JAVA, SACO |
| `tipo_gasto` | `por_carga` (se registra por camión), `requiere_descripcion` | ESTIBA/DESESTIBA, COSTO PESAJE, FLETE INTERNO (por carga), OTROS GASTOS (con descripción) |
| `condicion_pago` | — | CTA BANCO, EFECTIVO, CREDITO |

### `fijacion_precio` (una por lote)
| Campo | Tipo | Descripción |
|---|---|---|
| `lote_id` | uuid UNIQUE | Lote |
| `evaluacion_id` | uuid | Evaluación **CERRADA** del lote de la que salen los % de calidad |
| `gasto_llenado` | numeric(10,4) ≥ 0 | S/ por kg que se resta |
| `precio_promedio`, `precio_tecnico` | numeric(10,4) | Calculados por el servidor al guardar |
| `precio_pactado` | numeric(10,4) > 0, null | Precio final acordado (null = aún en cálculo) |
| `fecha_pacto`, `observacion` | | |

`fijacion_precio_clase (fijacion_id, clase_calidad_id, precio_base ≥ 0)`: precio base por clase.
Para **pactar**, cada clase con % > 0 en alguna muestra debe tener precio base (422).

### `carga` (un camión)
`lote_id`, `fecha`, `placa`, `kg > 0`, `cantidad_empaques ≥ 0`, `tipo_empaque_id`, `precio_kg > 0`
(sugerido = pactado), `destare_pct 0–100` (default 1), `observacion`.

### `gasto_vinculado`
`lote_id`, `carga_id` (null = gasto general), `tipo_gasto_id`, `fecha`, `monto > 0`, `descripcion`.
Una carga con gastos no se puede eliminar (409).

### `pago`
`lote_id`, `fecha`, `condicion_pago_id`, `monto > 0`, `beneficiario_id` (persona: agricultor, proveedor o DNI LC),
`referencia` (n.º de operación), `observacion`.

### `comprobante`
Fotos de respaldo: `entidad` CARGA (ticket de balanza) · PAGO (voucher) · GASTO (recibo), `entidad_id`, `url_archivo`.
Se borran junto con su registro.

## API
| Método | Ruta | |
|---|---|---|
| GET | `/api/v1/lotes/{loteId}/compra` | Fijación, cargas, gastos, pagos, comprobantes y `resumen` (balance) |
| PUT | `/api/v1/lotes/{loteId}/fijacion-precio` | Crea o reemplaza (201/200) |
| PUT / DELETE | `/api/v1/lotes/{loteId}/{cargas\|gastos\|pagos}/{id}` | Upsert idempotente con el UUID del cliente (201/200) / 204 |
| POST | `/api/v1/lotes/{loteId}/comprobantes` | Multipart: `archivo`, `entidad`, `entidadId`, `id` opcional |
| GET / DELETE | `/api/v1/comprobantes/{id}[/archivo]` | Descargar / eliminar foto |

Un lote **anulado** no acepta cambios (409), pero se puede consultar.

## Pendiente de confirmar con el cliente
- Modalidades de precio de la hoja DATOS: **"Precio Barre"** (1ra y 2da un precio, abierto y poroto otro) y
  **"Precio Escoba"** (todo un precio; enfermos y cebollín aparte).
- Si **POROTO** debe ser una clase de calidad (el Excel tiene "Precio Poroto 1.1" pero 2.1 solo usa PRIMERA/ABIERTOS).
  Si se agrega al catálogo, entra solo en la fijación de precio.
- Qué significa la condición de pago **CREDITO**: ¿compensa deudas del proveedor? (ver hoja "Deuda Neiver Deivi").
- Si la liquidación debe **cerrarse** (inmutable) al terminar de pagar.
