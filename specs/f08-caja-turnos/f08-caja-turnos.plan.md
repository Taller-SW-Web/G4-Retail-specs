# Plan de Implementación — F8: Apertura y Cierre de Turno de Caja con Arqueo Ciego

> Documento de regularización y decisiones de arquitectura para gestión de caja y corte Z.

---

## 1. Decisiones Técnicas Confirmadas
1. **Regla de Integridad:** La base de datos tiene un constraint parcial único sobre `(caja_id, estado)` impidiendo que existan dos turnos con estado `ABIERTO` en la misma caja al mismo tiempo.
2. **Cálculo Ciego en Servidor:** El servidor es el único que conoce el saldo esperado a partir de la sumatoria de pagos en efectivo (`RET_PAGOS`) menos salidas de caja. El cliente solo envía el valor físico contado.

## 2. Registro de Incidencias y Regularizaciones
- *(Pendiente de registro durante la ejecución del sprint)*.
