# Spec — F9: Solicitud de Cambio de Prenda y Emisión de Vales (v1.0)

### Responsable: Guillermo (QA & Control de Calidad) & Cristhian (Backend Developer)
### Requerimientos Funcionales Incluidos: RF-23, RF-24, RF-25
### Prioridad: Should have

---

## 1. ¿Por qué? (Problema de Negocio)
Los clientes acuden con frecuencia a las tiendas físicas solicitando cambio de talla de zapatillas o indumentaria, o cambios por fallas de fábrica:
1. Si el vendedor no puede comprobar la autenticidad del comprobante original, el tiempo transcurrido o si el producto ya fue cambiado, se aceptan prendas dudosas o fuera de garantía.
2. Si se reciben prendas con signos de uso, manchas o sin etiquetas, se generan pérdidas irreparables de mercadería no comercializable.
3. Si la compensación no queda registrada con un código inmutable de vale o nota de crédito, se generan fraudes por doble canje en caja.

---

## 2. ¿Para qué? (Objetivo)
Gestionar solicitudes de postventa presenciales en mostrador: buscar y validar la compra original por número de boleta/factura o ticket de regalo verificando el plazo legal de 30 días naturales, ejecutar un checklist estandarizado de inspección física de la prenda (etiquetas intactas, sin uso), y formalizar la compensación económica mediante canje inmediato en el carrito POS o emisión de un Vale de Compra / Nota de Crédito térmico con vigencia de 90 días y código de barras.

---

## 3. ¿Hasta dónde? (Alcance)
* **Incluido:**
  * Búsqueda de comprobante original por serie/correlativo, DNI o Ticket de Regalo (`GET /api/v1/ventas/comprobantes/validar-cambio`).
  * Validación de plazo comercial (máximo 30 días calendario desde la emisión).
  * Checklist digital de inspección física (4 criterios excluyentes: etiquetas, sin uso, caja original, catálogo).
  * Determinación de destino: reingreso a inventario (`REINGRESO_INVENTARIO`) o merma/garantía (`MERMA_GARANTIA`).
  * Modalidad de compensación: Canje Inmediato en carrito POS o Emisión de Vale / Nota de Crédito térmica con código de barras.
  * Reingreso automático de 1 unidad al stock de tienda si la prenda está apta.
* **Excluido:**
  * Devolución de dinero en efectivo en mostrador (los cambios son por prendas/vales, o extorno bancario en postventa central).

---

## 4. Referencias y Contratos
* **Contrato de API:** [`specs/generales/api-contracts.md`](../generales/api-contracts.md) → `POST /api/v1/devoluciones`, `POST /api/v1/vales`
* **Design System:** [`specs/generales/design-system.md`](../generales/design-system.md)
* **Modelo de Base de Datos:** `RET_DEVOLUCIONES`, `RET_VALES_COMPRA`

---

## 5. Requerimientos Funcionales Detallados

### <a id="rf-23"></a>RF-23: Validación de Comprobante y Plazos de Cambio Presencial
* **Backend:**
  1. Expone endpoint de validación de comprobante recibiendo serie/correlativo, ticket de regalo o DNI.
  2. Calcula `diasTranscurridos = diferenciaDias(NOW(), fechaEmision)`.
  3. Si `diasTranscurridos > 30`: marca `plazoValido = false` (*"Plazo de cambio expirado: máximo 30 días"*).
  4. Valida estado del pedido: debe ser `PAGADO` o `ENTREGADO`.
  5. Retorna prendas compradas indicando cuántas unidades están disponibles para cambio.
* **Frontend:**
  1. Módulo *"Cambios y Devoluciones en Mostrador"* con lector de código de barras para boleta o ticket de regalo.
  2. Si es válido y en plazo: muestra datos de compra, etiqueta verde *"Válido para cambio (Día X de 30)"* y casillas para seleccionar prendas.
  3. Si expiró: etiqueta roja *"Plazo Expirado"* y bloquea la selección.
* **Criterios de Aceptación (RF-23):**
  - [ ] Boleta emitida hace <= 30 días permite seleccionar artículos para cambio.
  - [ ] Boleta con más de 30 días muestra mensaje de plazo vencido e inhabilita el trámite.
  - [ ] Escaneo de Ticket de Regalo carga la compra original sin mostrar precios al comprador.

---

### <a id="rf-24"></a>RF-24: Inspección Física y Registro de Estado de la Prenda
* **Backend:**
  1. Expone endpoint de inspección física.
  2. Si `motivo == 'FALLA_FABRICA'`: permite flexibilizar etiquetas según garantía y sugiere `MERMA_GARANTIA`.
  3. Si es cambio ordinario de talla: exige obligatoriamente `etiquetasIntactas == true` y `sinSignosUso == true`, sugiriendo `REINGRESO_INVENTARIO`.
* **Frontend:**
  1. Modal *"Inspección de Estado Físico de la Prenda"* con selector de motivo.
  2. Checklist interactivo:
     - `[ ]` Etiquetas colgantes originales intactas.
     - `[ ]` Prenda limpia y sin signos de uso.
     - `[ ]` Empaque o caja original apta.
  3. Si falta alguna casilla crítica en cambio de talla: botón *"Aprobar Cambio"* bloqueado con advertencia.
  4. Si es falla de fábrica: permite observaciones y habilita aprobación por garantía.
* **Criterios de Aceptación (RF-24):**
  - [ ] Intento de aprobar cambio de talla sin etiquetas intactas es bloqueado en frontend.
  - [ ] Cambio de talla con checklist completo aprueba y sugiere `REINGRESO_INVENTARIO`.
  - [ ] Registro almacena el ID del vendedor auditor.

---

### <a id="rf-25"></a>RF-25: Emisión de Vale de Compra / Nota de Crédito Presencial
* **Backend:**
  1. Expone endpoint para completar cambio.
  2. Registra la transacción en `RET_SOLICITUD_CAMBIO_MOSTRADOR` y genera el vale en `RET_VALES_COMPRA` con vigencia de 90 días.
  3. Si la prenda fue declarada apta: incrementa en 1 el stock en `RET_STOCK_TIENDA`.
  4. Retorna código de vale, monto a favor y código de barras.
* **Frontend:**
  1. Selector de compensación:
     - *Opción A (Canje Inmediato):* abona el monto como saldo a favor en el carrito POS activo para cobrar solo la diferencia.
     - *Opción B (Emitir Vale):* emite comprobante térmico con código `NC-RET-2026-XXXXX`, DNI del titular, monto, código de barras y vigencia de 90 días.
* **Criterios de Aceptación (RF-25):**
  - [ ] Canje inmediato abona el monto exacto al carrito POS para la nueva compra.
  - [ ] Emisión de vale genera código único con 90 días de vigencia y código de barras escaneable.
  - [ ] El stock de la prenda devuelta en buen estado se incrementa automáticamente en la tienda.

---

## 6. Precondiciones y Dependencias
* Comprobante original existente y dentro del plazo de 30 días (RN-05).
