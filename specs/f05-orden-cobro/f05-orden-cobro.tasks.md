# Tareas — F5: Registro de Venta Asistida y Emisión de Boleta

**Fuentes:** `f05-orden-cobro.md` (RF-13, RF-14, RF-15), `f05-orden-cobro.ui.md`, `specs/generales/api-contracts.md`.  
**Regla SDD (AGENTS.md):** Una tarea a la vez, cada tarea concluye con su test automatizado y commit.

---

## Backend (`G4-Retail-backend`)

### [ ] Tarea B1 (RF-13, RF-14): Cliente de Integración de Pedidos y DTOs de Venta
- **Archivos:** `client/VentasClient.java`, `dto/CrearPedidoRequest.java`, `dto/PedidoResponse.java`, `repository/CajaSesionRepository.java`.
- **Qué hace:** Define DTOs de comunicación hacia Ventas (`POST /api/v1/pedidos`) y valida que la sesión de caja local en `RET_CAJA_SESION` se encuentre `ABIERTA`.
- **Criterio que verifica:** "Estructura de integración y validación de turno para ventas en mostrador" (RF-14).
- **Test:** `VentasClientTest.java` — Valida serialización del payload con `canal: RETAIL`, `Idempotency-Key` y manejo de respuesta `PED-YYYY-NNNNN`.

### [ ] Tarea B2 (RF-14): Servicio Transaccional de Venta y Control de Stock
- **Archivos:** `service/VentaService.java`, `service/impl/VentaServiceImpl.java`, `dto/CobroMostradorRequest.java`, `dto/CobroMostradorResponse.java`.
- **Qué hace:** Ejecuta la orquestación dentro de `@Transactional`: valida turno de caja abierto en `RET_CAJA_SESION`, descuenta stock consumiendo Inventario y envía orden a Ventas para nacer en `PAGADO`.
- **Criterios que verifica:** "Venta descuenta stock de la tienda" y "Rollback ante quiebre de existencias con 409 Conflict" (RF-14).
- **Test:** `VentaServiceTest.java` — Verifica decremento de existencias y aborto transaccional si `stock < cantidad`.

### [ ] Tarea B3 (RF-15): Servicio de Emisión de Comprobantes Fiscales y Series
- **Archivos:** `service/ComprobanteService.java`, `service/impl/ComprobanteServiceImpl.java`, `dto/ComprobanteTicketDto.java`.
- **Qué hace:** Asigna correlativo atómico de tienda (`B001` o `F001`), calcula desglose de IGV (18%), valida reglas SUNAT (DNI obligatorio si >= S/ 700.00) y genera ticket de regalo opcional.
- **Criterios que verifica:** "Correlativo único sin duplicidad" y "Venta >= 700 exige DNI" (RF-15).
- **Test:** `ComprobanteServiceTest.java` — Comprueba numeración correlativa concurrente y generación de ticket de cambio.

### [ ] Tarea B4 (RF-13, RF-14, RF-15): Controlador REST de Orquestación de Venta en Mostrador
- **Archivos:** `controller/VentaMostradorController.java`.
- **Qué hace:** Expone `POST /api/v1/retail/ventas/cobrar` retornando 201 Created con pedido `PED-YYYY-NNNNN` y comprobante de ticket térmico.
- **Criterios que verifica:** Respuestas 201 Created, 400 Bad Request y 409 Conflict según el contrato.
- **Test:** `VentaMostradorControllerTest.java` (MockMvc) — Comprueba contratos de API completos.

---

## Frontend (`G4-Retail-frontend`)

### [ ] Tarea F1 (RF-13, RF-14): Tipos y Cliente API de Órdenes y Pagos
- **Archivos:** `types/orden.ts`, `api/ordenApi.ts`.
- **Qué hace:** Declara payload de orden, desglose de pagos y función `crearOrden()`.
- **Test:** `ordenApi.test.ts` — Comprueba serialización de datos y respuesta 201.

### [ ] Tarea F2 (RF-13): Componente `PaymentModal` y `DenominationCounter`
- **Archivos:** `components/organisms/PaymentModal.tsx`, `components/organisms/DenominationCounter.tsx`.
- **Qué hace:** Modal de selección de medio de pago, botones de billetes peruanos y cálculo reactivo de vuelto.
- **Criterios que verifica:** "Cálculo exacto de vuelto" y "Bloqueo de botón si el dinero recibido es insuficiente" (RF-13).
- **Test:** `PaymentModal.test.tsx` — Valida cálculo de vuelto y activación condicionada del botón de pago.

### [ ] Tarea F3 (RF-15): Componente `Receipt` y Pantalla `ReceiptPage` con Impresión
- **Archivos:** `components/organisms/Receipt.tsx`, `pages/ReceiptPage.tsx`.
- **Qué hace:** Formato de ticket térmico de 80 mm con datos SUNAT, pestaña de ticket de regalo, botón de imprimir y botón *"Nueva Venta"*.
- **Criterios que verifica:** "Renderizado de serie/correlativo" y "Botón Nueva Venta reinicia la terminal" (RF-15).
- **Test:** `Receipt.test.tsx` — Valida formato de ticket térmico y disparo del diálogo de impresión.
