# Spec — F12: Gestión de Discrepancias y Prendas no Ubicadas (v1.0)

### Responsables: Angie (DBA), Guillermo (QA) & Maylle (Arquitectura)
### Requerimientos Funcionales Incluidos: RF-32, RF-33, RF-34
### Prioridad: Could have (Secundario / Opcional para Hito 3)

---

## 1. Visión General del Módulo

Durante la rutina operativa en el mostrador o depósito de tienda física ocurren incidencias con los productos: una prenda en exhibición o probador se mancha con maquillaje, un cliente daña una costura al medirse una talla ajustada, o el sistema indica stock disponible pero físicamente la caja no aparece en el almacén (extravío o faltante). 

La funcionalidad **F12** permite al personal de tienda reportar de forma ágil incidencias sobre prendas específicas, ponerlas de inmediato en cuarentena preventiva bloqueando su venta en el mostrador (POS), emitir actas oficiales de discrepancia/merma con código correlativo e informar formalmente al módulo de *Productos y Ofertas* para el decremento contable del stock.

---

## 2. Requerimientos Funcionales Detallados

---

### <a id="rf-32"></a>RF-32: Reporte de Prenda Dañada o No Ubicada en Mostrador

#### ¿Por qué? (Problema)
Si el vendedor detecta una prenda rota, manchada o extraviada y no tiene forma de registrar la novedad al instante, el sistema sigue mostrando esa unidad como vendible, ocasionando que otros vendedores la prometan o que un cliente la agregue a su carrito para luego sufrir una cancelación forzada en caja.

#### ¿Para qué? (Objetivo)
Permitir al personal de tienda reportar ágilmente una incidencia física sobre un artículo específico mediante escaneo de su código de barras o búsqueda por SKU, seleccionando la tipología de falla (*"Prenda manchada en probador"*, *"Costura o tela dañada"*, *"Falla de confección"*, *"Artículo extraviado / no ubicado físicamente"*), adjuntando descripción y generando el registro formal de la discrepancia.

#### Alcance
* **Incluido:** Modal de captura rápida de incidencia en catálogo; búsqueda o pistoleo del SKU de la prenda; selector de tipo de falla con opciones predeterminadas de tienda deportiva (`MANCHADO_PROBADOR`, `COSTURA_ROTA`, `EXTRAVIO_NO_UBICADO`, `DEFECTO_FABRICA`); campo de observaciones; adjunto opcional de URL de foto/evidencia; persistencia en la tabla `RET_INCIDENCIA_INVENTARIO`.
* **Excluido:** Retiro físico del producto hacia la trastienda (acción manual del personal) y peritaje contable de seguros.

#### Comportamiento Técnico y de Flujo
1. Expone `POST /api/v1/retail/inventario/incidencias`:
   * Verifica token Bearer del vendedor con turno activo.
   * Valida campos obligatorios: `varianteSkuId`, `tipoFalla`, `detalleObservacion` (mínimo 5 caracteres).
   * Asocia la tienda del vendedor (`tienda_id`) y marca temporal de auditoría.
2. Inserta el registro en `RET_INCIDENCIA_INVENTARIO` con `estado_cuarentena = 'EN_CUARENTENA'`.
3. Dispara la orden de bloqueo preventivo en mostrador (RF-33).
4. Retorna `201 Created` con el ID de la incidencia y la confirmación de puesta en cuarentena.

#### Criterios de Aceptación (RF-32)
- [ ] **CA-RF32-01:** Escanear el código de barras de una prenda rota en el modal carga automáticamente su nombre, SKU y talla/color.
- [ ] **CA-RF32-02:** Seleccionar el motivo "Costura dañada" y confirmar guarda la incidencia en estado `EN_CUARENTENA`.
- [ ] **CA-RF32-03:** El sistema asocia automáticamente el vendedor autenticado que reportó el incidente para control de calidad y auditoría.
- [ ] **CA-RF32-04:** Enviar el formulario sin seleccionar tipo de falla muestra validación de campo requerido.

---

### <a id="rf-33"></a>RF-33: Puesta en Cuarentena y Bloqueo Temporal en POS

#### ¿Por qué? (Problema)
Cuando una prenda sufre una avería o se pierde en mostrador, si el bloqueo no se refleja de inmediato en los terminales de la tienda, otro vendedor que esté atendiendo a otro cliente al mismo tiempo podría agregar esa misma unidad al carrito e intentar cobrarla, causando frustración y mala experiencia de compra.

#### ¿Para qué? (Objetivo)
Asegurar que inmediatamente tras el registro de una incidencia (RF-32), la unidad afectada pase a estado **En Cuarentena / Bloqueada para Venta en Mostrador**: descontándose de forma provisional del stock disponible en tienda visible en el POS, impidiendo su selección en el catálogo y bloqueando su adición a nuevos carritos de venta.

#### Alcance
* **Incluido:** Reducción inmediata en 1 unidad del `stockDisponible` local en memoria/caché de la tienda; etiquetado visual del SKU como *"Artículo en Cuarentena"* en la matriz de variantes; rechazo automático en el carrito POS si se intenta forzar la adición por código de barras; bandeja interna *"Artículos en Cuarentena de la Tienda"* accesible por el jefe de tienda o cajero principal (`GET /api/v1/retail/inventario/cuarentena`).
* **Excluido:** Bloqueo en canales web o chatbot (se gestiona al sincronizar la baja con Productos en RF-34).

#### Comportamiento Técnico y de Flujo
1. Al confirmarse la incidencia (RF-32):
   * Actualiza el contador local de stock vendible para esa tienda y SKU: `stock_disponible = stock_disponible - 1`.
   * Mantiene el registro en estado `EN_CUARENTENA`.
2. Expone `GET /api/v1/retail/inventario/cuarentena`:
   * Retorna la lista de todas las prendas actualmente retenidas en la tienda física que no han sido devueltas al almacén central ni dadas de baja definitiva.
3. En el POS:
   * Si el stock disponible de la talla cae a 0, la talla se deshabilita visualmente (`🚫 No disponible (En revisión física)`).
   * Si se escanea el código de barras de un ítem en cuarentena, emite sonido de error y modal de advertencia impidiendo la adición al carrito.

#### Criterios de Aceptación (RF-33)
- [ ] **CA-RF33-01:** Reportar una prenda con stock de 1 unidad inactiva la talla para la venta en el catálogo de inmediato.
- [ ] **CA-RF33-02:** Intentar escanear el código de barras de la prenda en cuarentena bloquea la adición al carrito con alerta explícita: *"PRODUCTO BLOQUEADO POR CUARENTENA"*.
- [ ] **CA-RF33-03:** La bandeja de cuarentena lista la prenda con su número de incidencia, SKU y motivo de retención.

---

### <a id="rf-34"></a>RF-34: Acta de Discrepancia y Notificación a Inventarios

#### ¿Por qué? (Problema)
Las prendas retenidas en cuarentena no pueden permanecer indefinidamente en el limbo físico ni en la base de datos de la tienda: deben derivarse formalmente al Almacén Central (reparación, lavado o devolución al fabricante) o declararse como merma definitiva. Si este proceso no genera un documento digital (Acta de Discrepancia) y no notifica al microservicio de *Productos y Ofertas*, el inventario contable y el físico jamás cuadrarán.

#### ¿Para qué? (Objetivo)
Permitir al jefe de tienda consolidar las prendas en cuarentena al cierre de turno o semana, emitir un **Acta Digital de Discrepancia / Merma de Tienda** con código correlativo e imprimirla para adjuntarla al bulto físico, enviando simultáneamente una notificación vía API a *Productos y Ofertas* (`POST /api/v1/productos/inventario/ajuste-discrepancia`) para regularizar el stock contable de la tienda.

#### Alcance
* **Incluido:** Selección de artículos en cuarentena para inclusión en el acta; opciones de destino (*"Devolución a Almacén Central por Garantía"*, *"Baja por Deterioro / Merma Irrecuperable"*, *"Ajuste por Faltante / Pérdida"*); generación de acta con correlativo oficial (ej. `ACTA-MERMA-2026-0012`); formato imprimible con casillas de firma del jefe de tienda; notificación vía API REST a *Productos y Ofertas* para el decremento contable definitivo.
* **Excluido:** Deducciones contables del balance corporativo o liquidaciones de seguros (módulo de Finanzas).

#### Comportamiento Técnico y de Flujo
1. Expone `POST /api/v1/retail/inventario/actas-merma`:
   * Verifica permisos de supervisor o jefe de tienda.
   * Recibe la lista de incidencias en cuarentena a liquidar.
   * Genera el correlativo oficial del acta (`ACTA-MERMA-TIENDA-YYYY-XXXX`).
   * Envía petición al microservicio de *Productos y Ofertas*: `POST /api/v1/inventario/ajuste-discrepancia` solicitando el decremento del stock patrimonial por merma/devolución.
   * Actualiza el estado de las incidencias en `RET_INCIDENCIA_INVENTARIO` a `DERIVADO_ALMACEN` o `BAJA_DEFINITIVA`.
2. Retorna `201 Created` con el acta digital y la constancia de ajuste de inventario.

#### Criterios de Aceptación (RF-34)
- [ ] **CA-RF34-01:** Selección de prendas en cuarentena y emisión del acta cambia su estado a `DERIVADO_ALMACEN`, retirándolas de la bandeja activa de cuarentena.
- [ ] **CA-RF34-02:** El sistema invoca exitosamente la API de Productos y Ofertas reportando el ajuste de inventario.
- [ ] **CA-RF34-03:** El acta generada cuenta con número correlativo inmutable, marca de tiempo y desglose detallado apto para impresión.
- [ ] **CA-RF34-04:** Intentar generar un acta sin seleccionar ninguna prenda muestra validación de lista vacía.

---

## 3. Modelo de Datos y Entidades Involucradas

* **`RET_INCIDENCIA_INVENTARIO`**:
  * `id` (PK, UUID/Long)
  * `tienda_id` (FK a tienda)
  * `variante_sku_id` (FK a SKU de prenda)
  * `codigo_barras` (VARCHAR)
  * `vendedor_id` (FK a usuario)
  * `tipo_falla` (`MANCHADO_PROBADOR`, `COSTURA_ROTA`, `EXTRAVIO_NO_UBICADO`, `DEFECTO_FABRICA`)
  * `detalle_observacion` (TEXT)
  * `foto_url` (VARCHAR, opcional)
  * `estado_cuarentena` (`EN_CUARENTENA`, `DERIVADO_ALMACEN`, `BAJA_DEFINITIVA`)
  * `fecha_reporte` (TIMESTAMP)

* **`RET_ACTA_DISCREPANCIA`**:
  * `id` (PK, UUID/Long)
  * `numero_acta` (VARCHAR, único, ej. `ACTA-MERMA-2026-0012`)
  * `tienda_id` (FK)
  * `responsable_id` (FK al supervisor/jefe)
  * `tipo_destino` (`DEVOLUCION_CENTRAL`, `BAJA_DEFINITIVA`, `AJUSTE_PERDIDA`)
  * `total_prendas` (INT)
  * `observaciones` (TEXT)
  * `estado_notificacion_productos` (`PENDIENTE`, `ENVIADO`, `FALLIDO`)
  * `fecha_emision` (TIMESTAMP)

---

## 4. Endpoints Asociados

| Método | Ruta | Requerimiento | Descripción |
| :--- | :--- | :--- | :--- |
| `POST` | `/api/v1/retail/inventario/incidencias` | RF-32 | Registra reporte de prenda rota, manchada o no ubicada |
| `GET` | `/api/v1/retail/inventario/cuarentena` | RF-33 | Consulta artículos actualmente en cuarentena en la tienda |
| `POST` | `/api/v1/retail/inventario/actas-merma` | RF-34 | Genera acta formal de merma y notifica a Productos y Ofertas |
