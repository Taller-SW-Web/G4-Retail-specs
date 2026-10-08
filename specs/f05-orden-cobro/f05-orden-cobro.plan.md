# Plan de Implementación — F5: Registro de Venta Asistida y Emisión de Boleta

> Documento de regularización y decisiones de arquitectura para el cierre de venta y emisión de boletas.

---

## 1. Decisiones Técnicas Confirmadas
1. **Aticimidad Obligatoria:** Las operaciones de creación de orden, asignación de pagos, rebaja de stock y generación de comprobante corren dentro de la misma transacción de base de datos (`@Transactional`).
2. **Numeración Correlativa:** La serie y correlativo de comprobantes se generan utilizando una secuencia atómica con bloqueo a nivel de fila (`SELECT ... FOR UPDATE` sobre la tabla de series) para evitar colisiones en múltiples cajas simultáneas.
3. **Mocks de Integración Externa:** La notificación del pedido hacia el módulo central de Ventas (G5) se implementa mediante un cliente HTTP simulado con respuesta `200 OK` controlada.

## 2. Componentes e Integraciones
- **Backend:** `OrdenController`, `VentaService`, `OrdenRepository`, `ComprobanteRepository`.
- **Frontend:** `PaymentModal`, `DenominationCounter`, `ReceiptPage`.

## 3. Registro de Incidencias y Regularizaciones
- *(Pendiente de registro durante la ejecución del sprint)*.
