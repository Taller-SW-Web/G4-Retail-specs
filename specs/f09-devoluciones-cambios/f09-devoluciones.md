# Spec — F9: Cambio directo de prenda en mostrador (Semana 14)

**Responsables:** Cristhian (desarrollo) y Guillermo (QA).
**Requisitos:** RF-23, RF-24 y RF-25.
**Prioridad:** Should have.

## 1. Objetivo y alcance

Validar una boleta emitida por el POS, inspeccionar la prenda que el cliente devuelve y entregarle en el mismo momento otra prenda a cambio. Si la nueva cuesta más, el cliente paga la diferencia. Es un **cambio directo**: Retail ya no emite vales de compra.

Fuera del alcance: el cambio por una prenda de menor valor, la devolución de dinero (es la devolución de Postventa, F3 de G5), las notas de crédito fiscales, el cambio en modo offline (F10) y la búsqueda por factura, DNI o ticket de regalo. Las fallas de fábrica se derivan a Postventa para revisión de garantía.

**Referencias:** [Contrato §5.9](../generales/api-contracts.md#59-f9--cambio-directo-de-prenda-en-mostrador-semana-14), [UI de F9](f09-devoluciones.ui.md), [emisión de comprobante de F5](../f05-orden-cobro/f05-orden-cobro.md#rf-15) y el acuerdo R6 con Ventas (G5): los cambios de mostrador son responsabilidad exclusiva de Retail.

> **Cambio respecto de la Semana 11.** El vale comercial (`RET_VALE_COMPRA`) se reemplaza por el cambio directo (decisión del PO, 25/11/2026). La tabla queda en desuso sin borrarse y el POS deja de emitir vales.

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

### <a id="rf-25"></a>RF-25: Cambio directo de prenda

- **Crédito del cambio.** El valor de la prenda devuelta es lo que el cliente pagó por esas unidades según `RET_VENTA`. Si el descuento de la compra no puede atribuirse a las unidades (X-P0-13), el cambio se rechaza con `MONTO_NO_DETERMINABLE`.
- **Prendas nuevas.** Retail calcula su total con el precio vigente, igual que el carrito de F4 y sin cupones. Las prendas nuevas deben estar disponibles en el catálogo (F2) y no estar en cuarentena (F12).
- **Mismo modelo.** Si la prenda nueva es el mismo producto que la devuelta (mismo `productoId`, otra talla o color) y en la misma cantidad, el cambio es de mismo valor sin comparar precios, aunque el precio vigente haya cambiado desde la compra.
- **Mismo valor.** En cualquier otro caso, si el total nuevo es igual al crédito, el cambio también es de mismo valor. Se registra sin cobro, sin boleta nueva y sin pedido nuevo en Ventas. El POS imprime una constancia de cambio con correlativo `CAMB-YYYY-XXXXXX` que referencia la boleta original.
- **Mayor valor.** Si el total nuevo supera al crédito, el cliente paga la diferencia en efectivo, con tarjeta o de forma mixta, con las reglas de cobro de F5. Retail emite una boleta por las prendas nuevas con su total completo. El crédito y la diferencia figuran como medios de pago. Ventas registra un pedido nuevo con la misma `Idempotency-Key` del cambio. El crédito viaja con el `metodoPago` configurable `retail.ventas.metodo-pago-credito` (provisional `CREDITO_CAMBIO`) hasta que G5 publique el definitivo.
- **Menor valor.** Si el total nuevo es menor que el crédito, el cambio se rechaza. La regla es cambiar solo por igual o mayor valor. No se emite vale ni se devuelve dinero en mostrador.
- **Caja.** El cambio exige un turno de caja `ABIERTA`. Solo la diferencia cobrada entra al arqueo (F8). El crédito no es efectivo.
- **Inventario.** Retail registra dos movimientos de stock: el reintegro de la prenda devuelta y el consumo de las nuevas. Los envía a Inventory a través de un puerto propio (`InventarioPort`). Mientras G6 no autorice a Retail, el puerto funciona con un mock. Un fallo de Inventory no revierte el cambio: el movimiento queda `PENDIENTE` y un job de Retail lo reintenta cada 5 minutos hasta `CONFIRMADO`.
- **Idempotencia y concurrencia.** La misma operación con la misma clave devuelve el resultado original y no consume unidades adicionales. Dos cambios simultáneos sobre la misma boleta no pueden superar las unidades compradas.

**Criterios de aceptación**

- [ ] Un cambio de talla del mismo modelo se registra sin cobro, sin boleta y sin pedido nuevo aunque el precio vigente sea distinto, y la constancia `CAMB-…` referencia la boleta original.
- [ ] Un cambio de mayor valor cobra exactamente la diferencia, emite una boleta por el total nuevo y crea el pedido en Ventas con la misma clave.
- [ ] Un cambio de menor valor se rechaza con `CAMBIO_MENOR_VALOR` y no registra nada.
- [ ] El arqueo del turno suma solo la diferencia cobrada.
- [ ] El cambio registra el reintegro de la prenda devuelta y el consumo de las nuevas en el puerto de inventario. Si el puerto falla, el cambio se confirma igual y los movimientos quedan `PENDIENTE`.
- [ ] Un reintento con la misma clave devuelve el cambio original. Dos solicitudes concurrentes no superan las unidades compradas.

## 3. Dependencias

- **F5:** la venta confirmada persistida en `RET_VENTA` y las reglas de cobro y comprobante.
- **F8:** el turno abierto y el arqueo.
- **Ventas (G5):** un valor de `metodoPago` para el crédito del cambio en el pedido de mayor valor. Hoy su enum solo admite `EFECTIVO`, `TARJETA_POS` y `MIXTO` (R3). Pendiente con G5 (§7.1 del contrato).
- **Productos (G6):** la autorización de `modulo-retail` para reintegrar y consumir stock. Pendiente con G6 (§7.1 del contrato).
- **Datos:** `RET_SOLICITUD_CAMBIO_MOSTRADOR` registra el cambio. La migración para guardar las prendas nuevas, la diferencia, la venta generada y el estado de los movimientos de stock la publica el DBA.
