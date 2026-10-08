# Tareas — F5: Registro de Venta Asistida y Emisión de Boleta

**Fuentes:** `f05-orden-cobro.md` (RF-13, RF-14, RF-15), `f05-orden-cobro.ui.md`, `specs/generales/api-contracts.md`.  
**Regla SDD (AGENTS.md):** Una tarea a la vez, cada tarea concluye con su test automatizado y commit.

---

## Backend (`G4-Retail-backend`)

### [ ] Tarea B1 (RF-13, RF-14): Entidades JPA y Repositorios de Orden, Detalle y Pago
- **Archivos:** `model/Orden.java`, `model/OrdenDetalle.java`, `model/Pago.java`, repositorios JPA correspondientes.
- **Qué hace:** Mapeo de tablas `RET_ORDENES`, `RET_ORDEN_DETALLE`, `RET_PAGOS` con relaciones `@ManyToOne` y `@OneToMany` en cascada.
- **Criterio que verifica:** "Estructura de persistencia relacional para ventas en mostrador" (RF-14).
- **Test:** `OrdenRepositoryTest.java` — Valida guardado en cascada de cabecera, líneas y método de pago.

### [ ] Tarea B2 (RF-14): Servicio Transaccional de Venta y Control de Stock
- **Archivos:** `service/VentaService.java`, `service/impl/VentaServiceImpl.java`, `dto/CrearOrdenRequest.java`, `dto/OrdenResponse.java`.
- **Qué hace:** Ejecuta la venta dentro de `@Transactional`: valida turno de caja abierto, descuenta stock de variantes y realiza rollback si falla el inventario.
- **Criterios que verifica:** "Venta descuenta stock de la tienda" y "Rollback ante quiebre de existencias con 409 Conflict" (RF-14).
- **Test:** `VentaServiceTest.java` — Verifica decremento de existencias y aborto transaccional si `stock < cantidad`.

### [ ] Tarea B3 (RF-15): Servicio de Emisión de Comprobantes Fiscales y Series
- **Archivos:** `model/Comprobante.java`, `service/ComprobanteService.java`, `service/impl/ComprobanteServiceImpl.java`.
- **Qué hace:** Asigna correlativo atómico (`B001` o `F001`), valida reglas SUNAT (DNI obligatorio si >= S/ 700.00) y genera ticket de regalo opcional.
- **Criterios que verifica:** "Correlativo único sin duplicidad" y "Venta >= 700 exige DNI" (RF-15).
- **Test:** `ComprobanteServiceTest.java` — Comprueba numeración correlativa concurrente y generación de ticket de cambio.

### [ ] Tarea B4 (RF-13, RF-14, RF-15): Controlador REST de Órdenes y Comprobantes
- **Archivos:** `controller/OrdenController.java`, `controller/ComprobanteController.java`.
- **Qué hace:** Expone `POST /api/v1/ordenes` y `GET /api/v1/comprobantes/{id}` retornando 201 Created con orden y comprobante.
- **Criterios que verifica:** Respuestas 201 Created, 400 Bad Request y 409 Conflict según el contrato.
- **Test:** `OrdenControllerTest.java` (MockMvc) — Comprueba contratos de API completos.

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
