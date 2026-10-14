# Plan de Implementación — F6: Consulta y Seguimiento Histórico de Pedidos

> Documento de regularización y decisiones de arquitectura para trazabilidad histórica.

---

## 1. Decisiones Técnicas Confirmadas
1. **Desacoplamiento de Microservicios:** La consulta histórica y trazabilidad se delega al Módulo de Ventas y Postventa (G5) mediante `GET /api/v1/pedidos?codigoPedido=&documentoCliente=` y `GET /api/v1/pedidos/{id}`.
2. **Historial de Estados Omnicanal:** Se consume el array de eventos de Ventas con el enum cerrado oficial (`CREADO`, `PAGADO`, `EN_PREPARACION`, `DESPACHADO`, `ENTREGADO`, `ANULADO`), mapeando la línea de tiempo en el frontend.

## 2. Registro de Incidencias y Regularizaciones
- *(Pendiente de registro durante la ejecución del sprint)*.
