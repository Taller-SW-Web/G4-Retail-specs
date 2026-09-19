# Spec — Generación de Pedido, Pago en Tienda y Emisión de Boleta (v0.1)

### Responsable: Miguel (DevOps / Tech Lead)
### Requerimientos Funcionales asociados: RF-13, RF-14, RF-15

---

## ¿Por qué? (problema)
El cierre de la venta es el momento más crítico de la tienda: involucra dinero físico o transacciones bancarias, el descuento definitivo de las existencias del catálogo y la obligación legal de entregar un comprobante de pago válido. Un fallo en este punto genera descuadres de caja, discrepancias de inventario o infracciones tributarias.

## ¿Para qué? (objetivo)
Permitir al cajero/vendedor procesar el pago presencial (efectivo, tarjeta o POS físico), registrar la orden oficial en el microservicio de *Ventas y Postventa*, solicitar el decremento de stock a *Productos y Ofertas*, y emitir y desplegar la Boleta de Venta o Factura Electrónica correspondiente.

## ¿Hasta dónde? (alcance)
* **Incluido:** Pantalla de cobro presencial (selección de método de pago, cálculo de vuelto en efectivo, registro de número de operación para tarjeta), envío de la orden oficial a *Ventas y Postventa*, consumo de stock en *Productos y Ofertas*, emisión de comprobante de pago electrónico con numeración fiscal y vista de impresión de ticket.
* **Excluido:** Integración directa con hardware de pasarela bancaria o terminales POS propietarias (se registra el voucher externamente), facturación electrónica ante webservices directos de SUNAT (lo orquesta Ventas y Facturación central) y anulaciones complejas o extornos posteriores (módulo de Postventa).

## Referencias
* **Contrato:** [specs/api-contracts.md](file:///c:/Users/Mihae/Programacion/Activos/modulo-retail/specs/api-contracts.md) — `POST /api/v1/ordenes/presenciales` e `POST /api/v1/inventario/consumir`
* **Modelo:** `PagoPresencial` (`medioPago`, `monto`, `montoRecibido`, `vuelto`, `referenciaOperacion`), `OrdenVenta` (`pedidoId`, `canal`, `vendedorId`, `clienteId`, `items`, `comprobante`)

## ¿Qué debe hacer? (comportamiento)

### Backend (Retail / Orquestación Transaccional de Venta)
1. Expone `POST /api/v1/retail/ventas/finalizar`:
   * Valida que el carrito tenga al menos un ítem y cliente asociado.
   * Valida la coherencia del pago: `monto == totalPagar`.
   * Si es efectivo: `montoRecibido >= totalPagar` y calcula `vuelto = montoRecibido - totalPagar`.
   * Si es tarjeta/POS físico: valida que venga `referenciaOperacion` no vacía.
2. Solicita el consumo/decremento de stock a *Productos y Ofertas* (`POST /api/v1/inventario/consumir`).
   * Si el producto se quedó sin stock mientras se cobraba, responde `409 Conflict` ("Stock insuficiente") y cancela el cobro.
3. Solicita la persistencia oficial de la orden y emisión de comprobante a *Ventas y Postventa* (`POST /api/v1/ordenes/presenciales`).
4. Retorna la confirmación con el `pedidoId`, serie/correlativo de la boleta/factura y detalle fiscal.

### Frontend
1. Modal o pantalla de Cobro:
   * Selector de Tipo de Comprobante: **Boleta de Venta** (default) o **Factura**.
     * Si selecciona Factura, exige RUC de 11 dígitos y razón social.
     * Si es Boleta y el total supera S/ 700.00, exige obligatoriamente DNI del cliente.
   * Selector de Medio de Pago:
     * **Efectivo:** Campo "Monto recibido". El sistema calcula automáticamente el vuelto en tiempo real.
     * **Tarjeta / POS:** Campo para ingresar el número de referencia del voucher físico emitido por la máquina POS.
2. Botón *"Confirmar Pago y Emitir Comprobante"* con estado de carga (*spinner*) para prevenir doble clic transaccional.
3. Pantalla de Éxito / Comprobante de Pago:
   * Muestra el comprobante con formato de ticket térmico comercial (logo de tienda deportiva, RUC empresa, serie-correlativo, datos del cliente, detalle de ítems, IGV, total y código QR de validación).
   * Botones de acción: *"Imprimir Ticket"* y *"Nueva Venta"* (que limpia el estado para el siguiente cliente).

## ¿Cómo verificamos? (criterios de aceptación)
- [ ] Pago en efectivo con monto mayor al total → Calcula y muestra el vuelto exacto.
- [ ] Pago en efectivo con monto menor al total → Botón de confirmación deshabilitado.
- [ ] Pago con tarjeta sin ingresar número de referencia del voucher → Bloqueo de confirmación.
- [ ] Venta mayor o igual a S/ 700 sin DNI de cliente → El sistema impide emitir boleta anónima cumpliendo normativa fiscal.
- [ ] Finalización exitosa → 201 Created, descuenta stock, persiste orden en Ventas y muestra ticket de boleta con serie y correlativo.
- [ ] Si el backend responde 409 Conflict (stock agotado) → Muestra alerta clara al cajero y cancela la transacción sin descontar dinero.
- [ ] Tras imprimir o pulsar "Nueva Venta", el carrito queda totalmente limpio para la siguiente operación.

## ¿Con qué condiciones? (precondiciones y dependencias)
* El cajero/vendedor debe estar autenticado con token válido.
* Depende de los microservicios de *Productos y Ofertas* (para decrementar stock) y *Ventas y Postventa* (para persistir orden y generar comprobante).
* Regla de negocio: El código de comprobante electrónico debe ser correlativo e irrepetible.

## ¿Qué NO hará? (fuera de alcance)
* No se conecta por bluetooth/USB a terminales POS bancarios (se opera por digitación de referencia de voucher).
* No procesa extornos de tarjetas ni devoluciones monetarias (le compete a Postventa).
