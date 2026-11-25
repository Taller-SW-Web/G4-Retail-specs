# Plan de Implementación — F7: Verificación y Entrega Física en Tienda (Pickup)

> Documento de regularización y decisiones de arquitectura para entrega presencial.

---

## 1. Decisiones Técnicas Confirmadas
1. **Validación de identidad (S11):** Ventas (G5) no emite código de retiro, así que el PIN pasa a ser opcional. El vendedor verifica el DNI del titular o, si recoge un tercero, la carta poder.
2. **Sincronización (S11):** La entrega se informa a Ventas (G5) con `POST /api/v1/pedidos/{pedidoId}/entrega-pickup`; Despacho (G2) no participa (contrato §4.4).

## 2. Registro de Incidencias y Regularizaciones
- *(Pendiente de registro durante la ejecución del sprint)*.
