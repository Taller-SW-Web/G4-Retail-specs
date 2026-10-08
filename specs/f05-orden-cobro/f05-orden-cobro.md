# Spec — F5: Registro de Venta Asistida y Emisión de Boleta (v1.0)

### Responsable: Miguel (DevOps / Tech Lead) & Kevin (Frontend Lead)
### Requerimientos Funcionales Incluidos: RF-13, RF-14, RF-15
### Prioridad: Must have (Crítico para Hito 3)

---

## 1. ¿Por qué? (Problema de Negocio)
El cierre de la transacción en caja es el punto de mayor exigencia operativa y tributaria:
1. Los clientes pagan con efectivo (exigiendo cálculo exacto de vuelto), tarjeta (requiriendo comprobación de voucher de operación) o medios mixtos. Errores de digitación o cálculo producen descuadres en el arqueo de caja.
2. La orden debe registrarse de forma transaccional atómica debitando las existencias físicas en la tienda y notificando al módulo de ventas corporativo.
3. Bajo las normas fiscales de SUNAT, es obligatorio entregar un comprobante electrónico (Boleta o Factura) con serie y correlativo únicos, identificando al cliente si el importe supera S/ 700.00 o emitiendo ticket de cambio si la prenda es para regalo.

---

## 2. ¿Para qué? (Objetivo)
Permitir al cajero registrar el pago de la orden en mostrador calculando automáticamente el vuelto en efectivo o registrando el voucher de tarjeta, orquestar la transacción atómica de venta (rebajando stock local y creando la orden oficial con canal `"RETAIL"`), y emitir y renderizar el comprobante de pago electrónico (Boleta de Venta `B001` o Factura `F001`) con formato de ticket térmico imprimible (80 mm) y opción de ticket de regalo sin precios.

---

## 3. ¿Hasta dónde? (Alcance)
* **Incluido:**
  * Modal de cobro multimétodo (`EFECTIVO`, `TARJETA_POS`, `MIXTO`).
  * Denominaciones rápidas de billetes peruanos y cálculo reactivo de vuelto.
  * Creación transaccional de la orden (`POST /api/v1/ordenes`) dentro de `@Transactional`.
  * Decremento del stock en `RET_STOCK_TIENDA` y manejo de conflicto de concurrencia (`409 Conflict`).
  * Reglas SUNAT: DNI obligatorio para ventas >= S/ 700.00; RUC de 11 dígitos para facturas.
  * Generación de comprobante con serie y número correlativo oficial incremental.
  * Emisión opcional de Ticket de Regalo / Cambio (sin importes visibles y con código de canje a 30 días).
  * Vista previa del ticket térmico con botón de impresión directa (`window.print()`) y reinicio de venta.
* **Excluido:**
  * Integración hardware por cable con datáfonos de tarjetas (se digita la referencia del voucher).
  * Web services SOAP directos con SUNAT (simulados en la capa de servicios para la entrega académica).

---

## 4. Referencias y Contratos
* **Contrato de API:** [`specs/generales/api-contracts.md`](../generales/api-contracts.md) → `POST /api/v1/ordenes`, `GET /api/v1/comprobantes/{id}`
* **Design System:** [`specs/generales/design-system.md`](../generales/design-system.md)
* **Modelo de Base de Datos:** `RET_ORDENES`, `RET_ORDEN_DETALLE`, `RET_PAGOS`, `RET_COMPROBANTES`

---

## 5. Requerimientos Funcionales Detallados

### <a id="rf-13"></a>RF-13: Registro de Medios de Pago Presencial
* **Backend:**
  1. Valida el desglose de pago dentro de la transacción:
     * Si `medioPago == "EFECTIVO"`: valida que `montoRecibido >= totalPagar` y calcula `vuelto = montoRecibido - totalPagar`.
     * Si `medioPago == "TARJETA_POS"`: valida `referenciaOperacion` (no vacía, longitud >= 4 caracteres) y `vuelto = 0.00`.
     * Si el monto recibido es insuficiente: responde `400 Bad Request` indicando el faltante.
* **Frontend:**
  1. Modal de cobro (`PaymentModal`) con monto total destacado en Oswald `text-4xl font-bold`.
  2. Pestañas de método: *Efectivo, Tarjeta, Mixto*.
  3. Sección Efectivo con botones rápidos de billetes (`[S/ 10]`, `[S/ 20]`, `[S/ 50]`, `[S/ 100]`, `[Exacto]`).
  4. Recuadro de Vuelto reactivo en verde (*"Vuelto a entregar: S/ XX.XX"*). Si falta dinero, alerta en rojo *"Faltan S/ XX.XX"* y botón bloqueado.
  5. Sección Tarjeta con campo obligatorio *"N° de Referencia / Voucher"*.
  6. Botón *"Confirmar Pago"* habilitado solo cuando el método está 100% validado.
* **Criterios de Aceptación (RF-13):**
  - [ ] Cobro en efectivo calcula y muestra el vuelto exacto en tiempo real.
  - [ ] Monto recibido menor al total mantiene el botón bloqueado e indica la diferencia faltante.
  - [ ] Pago con tarjeta exige el ingreso del número de referencia del voucher.
  - [ ] Alternar entre efectivo y tarjeta limpia o recalcula los campos correspondientes.

---

### <a id="rf-14"></a>RF-14: Creación Oficial de la Orden Transaccional
* **Backend:**
  1. Expone `POST /api/v1/ordenes`:
     * Extrae `vendedorId` y `tiendaId` del token de sesión.
     * Inicia bloque transaccional `@Transactional`.
     * Valida que la terminal tenga un turno de caja abierto en estado `ABIERTO`.
     * Verifica y descuenta el stock en `RET_STOCK_TIENDA` para cada SKU. Si alguna prenda no tiene existencias suficientes, aborta con `409 Conflict` (`STOCK_INSUFICIENTE`).
     * Registra cabecera en `RET_ORDENES` (estado `PAGADA`) y líneas en `RET_ORDEN_DETALLE`.
     * Registra el pago en `RET_PAGOS`.
     * Retorna `201 Created` con el ID de orden y datos del pedido.
* **Frontend:**
  1. Al confirmar pago, muestra spinner en botón y bloquea la pantalla para evitar ventas duplicadas.
  2. Al recibir 201 Created: limpia el carrito en memoria y `localStorage` y avanza a la vista de comprobante.
  3. Ante error 409 Conflict: muestra modal de quiebre de stock sin debitar dinero y permite ajustar el carrito.
* **Criterios de Aceptación (RF-14):**
  - [ ] Venta exitosa retorna 201 Created con un ID de pedido único no nulo.
  - [ ] El stock físico de la tienda local para cada SKU se decrementa exactamente en las unidades vendidas.
  - [ ] Intento de venta sin turno de caja abierto o sin stock suficiente responde con error controlado y rollback completo.
  - [ ] La orden registra inmutablemente el vendedor y la tienda del turno activo.

---

### <a id="rf-15"></a>RF-15: Emisión y Despliegue de Comprobante de Pago Electrónico
* **Backend:**
  1. Valida reglas tributarias SUNAT (RN-01):
     * Si `tipo == "FACTURA"`: exige cliente con RUC de 11 dígitos y razón social.
     * Si `tipo == "BOLETA"` y `total >= 700.00`: exige obligatoriamente DNI y nombre (no permite anónimo).
  2. Si `emitirTicketRegalo == true`: genera estructura secundaria de cortesía sin precios visibles, con código de barras de canje y vigencia de 30 días.
  3. Asigna serie y correlativo autoincremental protegido contra concurrencia (`B001` para boletas, `F001` para facturas).
  4. Retorna la estructura completa del comprobante con fecha/hora y cadena de código QR fiscal.
* **Frontend:**
  1. Selector en pantalla de cobro: *"Boleta de Venta"* / *"Factura Electrónica"* y checkbox *"¿Es para regalo? (Ticket de Cambio)"*.
  2. Si el total >= S/ 700.00 y no hay DNI, muestra aviso tributario obligatorio bloqueando el avance.
  3. Pantalla de Éxito (`ReceiptPage` / `Receipt`):
     * Simulación de ticket térmico de 80 mm: logo, datos fiscales de la tienda, correlativo oficial, tabla de prendas, desglose de IGV, medio de pago y código QR.
     * Si se marcó ticket de regalo: pestaña para visualizar el ticket de cambio sin precios.
     * Botón *"Imprimir Ticket"* (`window.print()`).
     * Botón *"Nueva Venta"* para reiniciar el mostrador y atender al siguiente cliente.
* **Criterios de Aceptación (RF-15):**
  - [ ] Emisión de boleta genera serie B001 y correlativo secuencial único.
  - [ ] Venta mayor a S/ 700.00 exige DNI para poder emitir el comprobante.
  - [ ] Venta con factura exige RUC de 11 dígitos y razón social.
  - [ ] Opción de regalo genera ticket secundario sin importes monetarios.
  - [ ] Botón "Nueva Venta" restablece la terminal en blanco para el próximo cliente.

---

## 6. Precondiciones y Dependencias
* Turno de caja abierto para el cajero y terminal (F8).
* Existencia de series fiscales configuradas en la base de datos de Retail.
