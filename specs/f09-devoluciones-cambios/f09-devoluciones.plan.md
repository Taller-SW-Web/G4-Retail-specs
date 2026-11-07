# Plan de implementación — F9 (Semana 11)

1. **Consulta de compra (RF-23).** Consumir el registro local de ventas confirmadas de F5 por número de boleta y tienda. Validar el límite de siete días calendario.
2. **Inspección (RF-24).** Aplicar las reglas del cambio de talla, registrar empaque y vendedor y derivar los casos de garantía a Postventa.
3. **Vale comercial (RF-25).** Guardar la solicitud y el vale en una transacción, con vigencia de 30 días y reintentos idempotentes. Presentar el ticket imprimible.

La integración requiere el registro persistente de F5 y la migración de Cambios y Vales. Las firmas se mantienen en el [contrato de API](../generales/api-contracts.md#59-f9--cambios-de-prenda-en-mostrador-semana-11).
