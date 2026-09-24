# Spec — RF-17: Visualización de Estados y Trazabilidad del Pedido (v0.1)

### Responsable: Cristhian (Backend Developer)
### Requerimiento Funcional: RF-17: Visualización de Estados y Trazabilidad del Pedido
### Funcionalidad Padre: F6: Consulta y Seguimiento de Pedidos del Cliente
### Prioridad: Should have (Importante)

---

## ¿Por qué? (problema)
Cuando un cliente consulta en mostrador por el progreso de su orden, responderle simplemente que "está pendiente" no satisface su necesidad de información. El vendedor necesita ver exactamente en qué etapa del flujo logístico se encuentra la compra (si ya fue pagada, si el almacén central la está preparando, si ya llegó al local para recojo o si fue entregada o cancelada), con fecha y hora de cada transición.

## ¿Para qué? (objetivo)
Presentar en la interfaz de Retail una vista detallada del pedido seleccionado, que incluya una línea de tiempo gráfica e interactiva (*stepper* de trazabilidad) con los estados por los que ha transitado la orden, su estado actual destacado, los artículos deportivos adquiridos (con talla, cantidad y foto), y los datos de despacho o recojo en sede física.

## ¿Hasta dónde? (alcance)
* **Incluido:** Tarjeta de cabecera con metadatos del pedido (ID, fecha/hora de compra, canal de procedencia, sede física asignada si es retiro en tienda), componente visual de línea de tiempo con estados cronológicos (`REGISTRADO`, `PAGADO`, `EN_PREPARACION`, `LISTO_PARA_RECOJO`, `ENTREGADO`, `ANULADO`), badge de estado con código de color, y lista desglosada de productos de la orden.
* **Excluido:** Búsqueda previa de pedidos por código o DNI (cubierto en RF-16), confirmación física de entrega de paquetes (cubierto en RF-19), e ingreso de reclamos o quejas formales (módulo de Postventa).

## Referencias
* **Contrato:** [api-contracts.md](./api-contracts.md) — `GET /api/v1/ordenes/{id}` (Sección 3)
* **Modelo:** `DetalleOrdenTrazabilidad` (`pedidoId`, `fechaCreacion`, `canalOrigen`, `cliente`: `{nombres, documento, email, telefono}`, `estadoActual`, `modalidadEntrega`: `"TIENDA" | "DOMICILIO"`, `tiendaPickupId`?: `string`, `historialEstados`: `[{estado, fechaHora, descripcion}]`, `items`: `[{sku, nombre, talla, color, cantidad, precio}]`)

## ¿Qué debe hacer? (comportamiento)

### Backend (Retail / Transformación de Trazabilidad)
1. Al recibir la orden desde *Ventas y Postventa*:
   * Mapea el array de transiciones históricas `historialEstados` asegurando orden cronológico ascendente.
2. Identifica el estado actual de la orden entre los estados estándar del marketplace:
   * `REGISTRADO`: Orden creada pero pendiente de confirmación de pago.
   * `PAGADO`: Pago confirmado exitosamente.
   * `EN_PREPARACION`: Paquete en empaque en centro logístico o trastienda.
   * `LISTO_PARA_RECOJO`: Paquete disponible físicamente en la tienda para recojo por el cliente.
   * `ENTREGADO`: Paquete entregado físicamente al comprador.
   * `ANULADO`: Orden cancelada o rechazada.
3. Normaliza las fechas al huso horario local (UTC-5 / Lima, Perú) para su despliegue amigable.

### Frontend
1. Despliega la tarjeta del pedido seleccionado:
   * **Cabecera:** Código de Pedido en fuente monoespaciada grande (ej. `ORD-RET-2026-0091`), Canal de Origen (icono y etiqueta: *Web*, *Chatbot* o *Tienda*), y Modalidad (*Retiro en Tienda* o *Envío a Domicilio*).
   * **Badge de Estado Actual:**
     * Verde: `ENTREGADO`.
     * Azul/Púrpura: `LISTO_PARA_RECOJO` (con aviso *"Listo para entregar en mostrador"*).
     * Amarillo/Ámbar: `EN_PREPARACION` o `PAGADO`.
     * Rojo: `ANULADO`.
2. **Línea de Tiempo Visual (*Stepper* horizontal o vertical):**
   * Muestra cada hito con un ícono representativo:
     1. *Registrado* (ícono de carrito/documento con fecha y hora).
     2. *Pagado* (ícono de tarjeta/moneda con fecha y hora).
     3. *En Preparación* (ícono de caja/empaque logístico).
     4. *Listo para Recojo* (ícono de tienda comercial).
     5. *Entregado* (ícono de check verde de conformidad).
   * Los pasos ya completados se muestran con línea continua iluminada y check. El paso en curso parpadea o se resalta en azul. Los pasos futuros permanecen en gris tenue.
   * Si la orden fue cancelada, la barra se interrumpe y despliega un nodo rojo de *Anulación*.
3. **Detalle de Artículos Deportivos:**
   * Tabla con foto miniatura de la prenda, nombre oficial, variante (talla y color), cantidad adquirida y subtotal.
4. Si la orden tiene modalidad *"Retiro en Tienda"*:
   * Muestra la sede asignada (ej. `Sede: Miraflores - Av. Larco 450`) y si el paquete ya se encuentra en tienda física.

## ¿Cómo verificamos? (criterios de aceptación)
- [ ] Orden en estado `LISTO_PARA_RECOJO` muestra activos los pasos 1, 2, 3 y 4 con sus respectivas fechas y horas.
- [ ] Orden con estado `ANULADO` despliega el badge rojo y el motivo de cancelación sin romper la navegación.
- [ ] La lista de productos muestra fielmente las tallas, colores y cantidades compradas.
- [ ] La vista es totalmente responsiva y legible tanto en pantallas de mostrador como en tablets de vendedores.

## ¿Con qué condiciones? (precondiciones y dependencias)
* Regla de Negocio RN-03: Trazabilidad integral de estados del pedido provista por el microservicio de Ventas.

## ¿Qué NO hará? (fuera de alcance)
* No permite cambiar de estado la orden desde esta pantalla (la entrega física se realiza en RF-19).
* No permite editar los productos adquiridos en la orden.
