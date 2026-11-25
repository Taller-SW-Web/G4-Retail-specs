# Plan de Implementación — F6: Consulta y Seguimiento Histórico de Pedidos

> Documento de regularización y decisiones de arquitectura para trazabilidad histórica.

---

## 1. Decisiones Técnicas Confirmadas
1. **Desacoplamiento de Microservicios:** Retail expone las rutas de §5.6 del contrato y delega la consulta por código a G5 mediante `GET /api/v1/pedidos/{pedidoId}`, con `ventas:pedidos:consultar`. La búsqueda histórica por documento queda para el siguiente hito (RF-16-DOC).
2. **Historial de Estados Omnicanal:** Se consume el array de eventos de Ventas con el enum cerrado oficial (`CREADO`, `PAGADO`, `EN_PREPARACION`, `DESPACHADO`, `ENTREGADO`, `ANULADO`), mapeando la línea de tiempo en el frontend.

## 2. Registro de Incidencias y Regularizaciones
- **06/11/2026 · A10 / RF-16-DOC:** G5 confirmó al PO que el listado `GET /api/v1/pedidos?buscar={DNI_o_RUC}` está restringido a `ADMIN_VENTAS`, sin acceso para tokens de servicio de canal. El PO difiere la búsqueda histórica por DNI/RUC al siguiente hito; la consulta por código y RF-17 siguen en el alcance actual.
- **Replanificación obligatoria:** retomar el checklist de [RF-16-DOC en la spec funcional](f06-trazabilidad.md#31-pendiente-para-la-planificación-del-siguiente-hito--rf-16-doc) y las tareas B4/F4. Mihael coordina primero con G5 el alcance compatible con A10. G7 interviene si el acuerdo requiere un permiso nuevo. No se solicita el rol `ADMIN_VENTAS` para Retail.
- El filtro por DNI de F7 se mantiene limitado a los recojos pendientes de la tienda; no resuelve RF-16-DOC.
