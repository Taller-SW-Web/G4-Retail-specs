# Spec — F9: Cambios de mostrador y vales de compra (Semana 11)

**Responsables:** Cristhian (desarrollo) y Guillermo (QA).
**Requisitos:** RF-23, RF-24 y RF-25.
**Prioridad:** Should have.

## 1. Objetivo y alcance

Validar una boleta emitida por el POS, inspeccionar las prendas seleccionadas y emitir un vale comercial térmico. El hito excluye el reintegro de stock por Retail, el canje en el POS, las notas de crédito fiscales y la búsqueda por factura, DNI o ticket de regalo. Los casos de falla de fábrica se derivan a Postventa para revisión de garantía.

**Referencias:** [Contrato §5.9](../generales/api-contracts.md#59-f9--cambios-de-prenda-en-mostrador-semana-11), [UI de F9](f09-devoluciones.ui.md) y [emisión de comprobante de F5](../f05-orden-cobro/f05-orden-cobro.md#rf-15).

## 2. Requerimientos funcionales

### <a id="rf-23"></a>RF-23: Validación de boleta y plazo

- Retail busca por número de boleta `B001` con ocho dígitos de correlativo en `RET_VENTA`, dentro de la tienda del perfil. La venta debe estar confirmada y contener la referencia del pedido central.
- El plazo comercial es de siete días calendario desde la compra en la zona horaria de la tienda. La solicitud es elegible en el día siete y se rechaza en el día ocho.
- El POS muestra las prendas de la compra y las unidades que aún pueden cambiarse. Si la boleta no existe o no es elegible, la interfaz muestra el motivo y bloquea la selección.

**Criterios de aceptación**

- [ ] Una boleta emitida por F5 se recupera tras reiniciar el backend y conserva el pedido, los importes y las cantidades compradas.
- [ ] Una compra confirmada permite seleccionar unidades en el día siete y bloquea la operación en el día ocho.
- [ ] La consulta rechaza una boleta inexistente y una venta no confirmada.

### <a id="rf-24"></a>RF-24: Inspección física de la prenda

- En un cambio de talla se exige que las etiquetas estén intactas y que la prenda no tenga signos de uso. Se registra el estado del empaque, el motivo y el vendedor responsable.
- Una falla de fábrica se identifica como caso de garantía para revisión de Postventa. El plazo comercial y las reglas del cambio de talla no deciden la cobertura de la garantía.

**Criterios de aceptación**

- [ ] La interfaz y la API bloquean un cambio de talla sin etiquetas intactas o con signos de uso.
- [ ] La inspección registra el estado del empaque y el identificador del vendedor autenticado.

### <a id="rf-25"></a>RF-25: Emisión de vale comercial

- Retail revalida la compra, el plazo y las unidades disponibles. Registra la solicitud y el vale en una sola transacción.
- El vale tiene código único `VALE-AAAA-NNNNN`, código de barras, importe y vigencia de 30 días desde la emisión. El importe corresponde al monto efectivamente pagado por las unidades cambiadas. Los casos que requieran un prorrateo sin resolver quedan fuera de la emisión automática.
- El POS presenta el vale en formato imprimible. La misma operación repetida con la misma clave devuelve el vale original.

**Criterios de aceptación**

- [ ] Un cambio aprobado crea un vale con el importe de las unidades elegidas, código de barras y vigencia de 30 días.
- [ ] Un reintento idempotente devuelve el vale original y no consume unidades adicionales. Dos solicitudes concurrentes no pueden superar las unidades compradas.

## 3. Dependencias

F5 debe persistir la venta confirmada antes de emitir el comprobante que consume F9. El registro de cambios usa `RET_SOLICITUD_CAMBIO_MOSTRADOR` y el vale usa `RET_VALE_COMPRA`. G5 conserva el pedido central.
