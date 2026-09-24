# Spec — RF-18: Verificación y Validación de Retiro en Tienda (v0.1)

### Responsable: Maye (Arquitectura de Software)
### Requerimiento Funcional: RF-18: Verificación y Validación de Retiro en Tienda
### Funcionalidad Padre: F7: Entrega del Producto en Tienda Física / Pickup
### Prioridad: Must have (Crítico)

---

## ¿Por qué? (problema)
Los clientes que compran por el canal digital (web o chatbot) y eligen modalidad *Retiro en Tienda* (*Pickup*) acuden al local físico para reclamar su paquete. Si el personal de mostrador no cuenta con una bandeja filtrada por su propia tienda y no puede validar si el paquete realmente se encuentra en estado `LISTO_PARA_RECOJO` (o si aún está en tránsito desde el centro de distribución), se generan entregas indebidas o búsquedas infructuosas en el almacén de la tienda.

## ¿Para qué? (objetivo)
Permitir al personal de tienda visualizar la bandeja exclusiva de pedidos asignados para retiro en su sede física actual (`tiendaId`) y validar que una orden específica se encuentre efectivamente en estado `LISTO_PARA_RECOJO` tras ingresar el código de retiro o el documento del cliente antes de autorizar la entrega física.

## ¿Hasta dónde? (alcance)
* **Incluido:** Vista de bandeja de órdenes pendientes de entrega en la tienda en sesión (`GET /api/v1/despachos/tienda/{tiendaId}/pendientes-pickup`), buscador rápido dentro de la bandeja por DNI o código de pedido, verificación de la condición de estado `LISTO_PARA_RECOJO`, bloqueo preventivo si la orden está en tránsito o no pertenece a esa sede, y botón de acción *"Procesar Retiro"*.
* **Excluido:** Captura de datos de quien recoge y confirmación definitiva de entrega (cubierto en RF-19), y despacho de envíos motorizados a domicilio (competencia del módulo de *Despacho y Entrega*).

## Referencias
* **Contrato:** [api-contracts.md](./api-contracts.md) — `GET /api/v1/despachos/tienda/{tiendaId}/pendientes-pickup` (Sección 4)
* **Modelo:** `PedidoPickupPendiente` (`pedidoId`, `fechaLlegadaTienda`, `cliente`: `{nombres, documento}`, `estado`: `"LISTO_PARA_RECOJO"`, `cantidadPrendas`: `number`, `ubicacionPaqueteTienda`?: `string`)

## ¿Qué debe hacer? (comportamiento)

### Backend (Retail / Consulta de Despacho)
1. Expone `GET /api/v1/retail/pickup/pendientes`:
   * Obtiene el `tiendaId` del vendedor autenticado (ej. `TIENDA-MIRAFLORES`).
   * Consulta a *Despacho y Entrega* (`GET /api/v1/despachos/tienda/{tiendaId}/pendientes-pickup`).
2. Filtra estrictamente las órdenes que:
   * Tengan modalidad de entrega `RETIRO_EN_TIENDA`.
   * Estén asignadas a la tienda del operador.
   * Su estado logístico sea exactamente `LISTO_PARA_RECOJO`.
3. Retorna la lista de pedidos listos para entrega con sus datos identificatorios.

### Frontend
1. Pestaña en navegación principal: *"Entregas en Tienda (Pickup)"*:
   * Contador visual de paquetes pendientes por entregar en la sede (ej. badge `5 pendientes`).
2. Barra de búsqueda y filtros locales:
   * Filtro por fecha de arribo a tienda.
   * Buscador de texto reactivo por DNI del comprador o código de pedido (`pedidoId`).
3. Bandeja de pedidos pendientes:
   * Grilla o lista de tarjetas con:
     * Código de pedido.
     * Nombre del titular de la compra.
     * DNI del titular.
     * Cantidad de prendas/bultos a entregar.
     * Fecha en que el paquete quedó listo para recojo.
     * Ubicación física en la trastienda (ej. `Estante A - Casillero 14`).
4. Botón de acción: *"Procesar Retiro"* en cada tarjeta:
   * Si el pedido está en estado `LISTO_PARA_RECOJO`: Abre el modal de confirmación de entrega (RF-19).
   * Si un usuario busca una orden que pertenece a otra tienda o que aún figura `EN_PREPARACION` / `EN_CAMINO_A_TIENDA`:
     * Muestra alerta en color ámbar: *"El pedido se encuentra en camino o asignado a otra sede. No está disponible para entrega física en este local comercial"*.

## ¿Cómo verificamos? (criterios de aceptación)
- [ ] La bandeja solo muestra pedidos asignados a la tienda del vendedor autenticado.
- [ ] Pedidos con entrega a domicilio nunca aparecen en esta bandeja de mostrador.
- [ ] Búsqueda por DNI filtra y resalta la tarjeta de la orden lista para recojo en menos de 300 ms.
- [ ] Si una orden está en camino pero no ha sido recibida en tienda física, el sistema impide iniciar el retiro físico y muestra la advertencia correspondiente.
- [ ] El contador de pedidos pendientes se actualiza al cargar la bandeja.

## ¿Con qué condiciones? (precondiciones y dependencias)
* El vendedor debe poseer una tienda activa asignada en su token.
* Regla de Negocio RN-05: Un pedido con modalidad *Pickup* únicamente puede ser entregado al cliente si su estado figura como `LISTO_PARA_RECOJO`.

## ¿Qué NO hará? (fuera de alcance)
* No gestiona motorizados ni traslados interurbanos.
* No permite cambiar la tienda de retiro de la orden una vez que el cliente ya seleccionó su sede en la web.
