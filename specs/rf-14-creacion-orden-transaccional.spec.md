# Spec — RF-14: Creación Oficial de la Orden Transaccional (v0.1)

### Responsable: Miguel (DevOps / Tech Lead)
### Requerimiento Funcional: RF-14: Creación Oficial de la Orden Transaccional
### Funcionalidad Padre: F5: Generación de Pedido, Pago en Tienda y Creación de Boleta
### Prioridad: Must have (Crítico)

---

## ¿Por qué? (problema)
El cierre de la venta es el punto de mayor exigencia transaccional: una orden en mostrador no solo debe registrarse localmente, sino que debe coordinarse con el inventario central para debitar las existencias físicas y registrarse en el sistema de ventas corporativo. Si falla la concurrencia o se venden prendas que otro canal acaba de consumir, se producen quiebres de stock o ventas fantasmas.

## ¿Para qué? (objetivo)
Orquestar la transacción atómica de venta presencial: solicitar a *Productos y Ofertas* el decremento oficial del stock de tienda (`POST /api/v1/inventario/consumir`), y registrar en *Ventas y Postventa* la orden oficial con canal `"RETAIL"`, el ID del vendedor, los datos del cliente, los artículos y el registro de pago (`POST /api/v1/ordenes/presenciales`), asegurando consistencia transaccional.

## ¿Hasta dónde? (alcance)
* **Incluido:** Endpoint de orquestación transaccional `POST /api/v1/retail/ventas/finalizar`, decremento definitivo de stock en inventario, persistencia de orden en Ventas, manejo de error de conflicto de concurrencia (`409 Conflict`), y generación de identificador de pedido (`pedidoId`).
* **Excluido:** Captura del medio de pago en UI (cubierto en RF-13), renderizado y formateo de la boleta impresa (cubierto en RF-15), y anulación o devolución posterior (responsabilidad del módulo de Postventa).

## Referencias
* **Contrato:** [api-contracts.md](./api-contracts.md) — `POST /api/v1/inventario/consumir` y `POST /api/v1/ordenes/presenciales`
* **Modelo:** `OrdenRetailRequest` (`canal`: `"RETAIL"`, `tiendaId`, `vendedorId`, `clienteId`, `items`: `[{sku, cantidad, precioFinal}]`, `pago`: `PagoPresencial`, `comprobante`: `DatosComprobante`), `OrdenCreadaResponse` (`pedidoId`, `estado`: `"PAGADO"`, `fechaCreacion`)

## ¿Qué debe hacer? (comportamiento)

### Backend (Retail / Orquestador de Venta)
1. Expone `POST /api/v1/retail/ventas/finalizar`:
   * Extrae `vendedorId` y `tiendaId` del token JWT de sesión.
   * Valida integridad: el carrito contiene al menos 1 ítem, el cliente está asignado y el pago cubre el total exacto.
2. **Paso 1: Consumo de Stock en Inventario:**
   * Invoca `POST /api/v1/inventario/consumir` en *Productos y Ofertas* con la lista de SKUs y cantidades para la tienda actual.
   * Si *Productos y Ofertas* responde `409 Conflict` (alguno de los productos se quedó sin stock físico en ese instante):
     * Aborta la transacción inmediatamente.
     * Retorna `409 Conflict` al frontend indicando el SKU agotado sin debitar nada.
3. **Paso 2: Persistencia Oficial de la Orden:**
   * Invoca `POST /api/v1/ordenes/presenciales` en el microservicio de *Ventas y Postventa*.
   * Envía: canal `"RETAIL"`, datos de auditoría (`vendedorId`, `tiendaId`, timestamp), cliente, items y detalle del pago.
   * *Ventas y Postventa* registra la orden en estado `PAGADO` y asigna el `pedidoId` (ej. `ORD-RET-2026-0091`).
4. Retorna respuesta consolidada `201 Created` con el `pedidoId` y los datos del comprobante generado.

### Frontend
1. Al pulsar *"Confirmar Pago y Finalizar"*:
   * Cambia el botón a estado inactivo con animación de procesamiento (*spinner*).
   * Deshabilita la interacción en la pantalla para prevenir clics dobles que dupliquen la venta.
2. Si el backend responde `201 Created`:
   * Notifica éxito con animación visual.
   * Limpia el carrito de compras en memoria y almacenamiento local.
   * Transiciona automáticamente a la pantalla de comprobante (RF-15).
3. Si el backend responde `409 Conflict` (quiebre de stock en tienda):
   * Muestra modal de alerta destacada: *"No se pudo completar la venta: La prenda [Nombre/SKU] se quedó sin existencias disponibles en tienda física"*.
   * Cancela el proceso de cobro sin descontar dinero y permite al vendedor actualizar el carrito.

## ¿Cómo verificamos? (criterios de aceptación)
- [ ] Finalización exitosa con stock suficiente → Retorna 201 Created con un `pedidoId` único no nulo.
- [ ] Se verifica en Productos y Ofertas que el stock de tienda física del SKU se decrementó en la cantidad vendida.
- [ ] Se verifica en Ventas y Postventa que la orden quedó registrada con canal "RETAIL" y estado "PAGADO".
- [ ] Intento de venta de producto con stock insuficiente en el momento de confirmación → Retorna 409 Conflict y no persiste la orden.
- [ ] La petición incluye inmutablemente el ID del vendedor y la tienda del turno activo.

## ¿Con qué condiciones? (precondiciones y dependencias)
* Regla de Negocio RN-02: Soberanía de stock en Productos y Ofertas; aborto con 409 ante quiebre de stock.
* Regla de Negocio RN-03: Trazabilidad inmutable con `vendedor_id`, `tienda_id` y timestamp.
* Disponibilidad de los microservicios de Productos y Ventas.

## ¿Qué NO hará? (fuera de alcance)
* No genera reversiones automáticas de tarjetas bancarias si falla la persistencia (se previene con validación previa de stock).
* No procesa órdenes con canal ajeno a `"RETAIL"`.
