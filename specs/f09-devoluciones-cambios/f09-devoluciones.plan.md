# Plan de implementación — F9 (Semana 14)

1. **Consulta de compra (RF-23).** Consumir el registro local de ventas confirmadas de F5 por número de boleta y tienda. Validar el límite de siete días calendario.
2. **Inspección (RF-24).** Aplicar las reglas del cambio de talla, registrar empaque y vendedor y derivar los casos de garantía a Postventa.
3. **Cambio directo (RF-25).** Calcular el crédito de la prenda devuelta y el total de las nuevas. Registrar el cambio de mismo valor sin cobro, o cobrar la diferencia y emitir la boleta con el pedido en Ventas cuando es de mayor valor. Rechazar el cambio de menor valor. Todo en una transacción con reintentos idempotentes.
4. **Puerto de inventario.** Definir `InventarioPort` con el reintegro de la prenda devuelta y el consumo de las nuevas, con un mock detrás. El adaptador real de G6 se conecta después por configuración (§6 del contrato), cuando G6 autorice a `modulo-retail`.

La integración requiere el registro persistente de F5, el turno de F8 y la migración del cambio directo. Las firmas se mantienen en el [contrato de API](../generales/api-contracts.md#59-f9--cambio-directo-de-prenda-en-mostrador-semana-14). La emisión de vales de la Semana 11 se retira.
