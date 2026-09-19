# Spec — Consulta y Seguimiento de Pedidos del Cliente (v0.1)

### Responsable: Cristhian (Backend Developer)
### Requerimientos Funcionales asociados: RF-16, RF-17

---

## ¿Por qué? (problema)
Los clientes acuden con frecuencia al mostrador de la tienda física para consultar sobre el estado de pedidos que realizaron por la web o el chatbot (ej. si su camiseta deportiva ya está lista para recoger o en qué estado de preparación se encuentra). Sin un módulo de consulta en Retail, el vendedor no puede dar respuesta rápida ni veraz.

## ¿Para qué? (objetivo)
Permitir al personal de mostrador buscar cualquier orden asociada a un cliente mediante su código de pedido o documento de identidad, y visualizar su línea de tiempo, estado actual y canal de procedencia.

## ¿Hasta dónde? (alcance)
* **Incluido:** Formulario de búsqueda por código de orden (`pedidoId`) o documento del cliente (DNI/RUC), visualización de la tarjeta de detalle de la orden con línea de tiempo gráfica de estados y detalle de los productos adquiridos.
* **Excluido:** Modificación del estado del pedido desde esta pantalla (la anulación pertenece a Postventa y la entrega a Despacho/Pickup) y cancelación de pedidos.

## Referencias
* **Contrato:** [specs/api-contracts.md](file:///c:/Users/Mihae/Programacion/Activos/modulo-retail/specs/api-contracts.md) — `GET /api/v1/ordenes/{id}` y `GET /api/v1/ordenes?clienteDoc={dni}`
* **Modelo:** `DetalleOrden` (`pedidoId`, `fechaCreacion`, `canalOrigen`, `cliente`: `{nombres, doc}`, `estadoActual`, `modalidadEntrega`, `historialEstados`: `[{estado, fechaHora}]`, `items`: `[{sku, nombre, cantidad, precio}]`)

## ¿Qué debe hacer? (comportamiento)

### Backend (Retail / Consumo de Ventas y Postventa)
1. Expone `GET /api/v1/retail/pedidos/consultar`:
   * Parámetros de consulta: `codigoPedido` o `documentoCliente`.
   * Valida que al menos uno de los dos parámetros esté presente.
2. Invoca al microservicio de *Ventas y Postventa*.
3. Si la orden existe, mapea y retorna el modelo de `DetalleOrden`.
4. Si no se encuentran pedidos, responde `404 Not Found` con mensaje amigable.

### Frontend
1. Pestaña o módulo "Seguimiento de Pedidos" en la barra de navegación de Retail.
2. Campo de búsqueda con toggle para elegir: *"Buscar por Código de Pedido"* o *"Buscar por DNI/RUC"*.
3. Visualización del resultado:
   * Encabezado de la orden: Código, Fecha, Canal de Origen (Marketplace Web, Chatbot o Tienda Física) y Modalidad de Entrega (Retiro en Tienda o Envío a Domicilio).
   * Línea de tiempo visual (*stepper* o barra de progreso) indicando estados:
     `REGISTRADO` ➔ `PAGADO` ➔ `EN_PREPARACION` ➔ `LISTO_PARA_RECOJO` ➔ `ENTREGADO` (o badge rojo si figura `ANULADO`).
   * Lista desglosada de artículos con foto referencial, talla y cantidad.
   * Si el pedido es para retiro en tienda, muestra la sede de recojo asignada y el estado del paquete.

## ¿Cómo verificamos? (criterios de aceptación)
- [ ] Búsqueda por código de orden válido → 200 OK y despliega el detalle completo con su línea de tiempo.
- [ ] Búsqueda por documento de cliente con varias órdenes → 200 OK y lista las órdenes ordenadas cronológicamente de la más reciente a la más antigua.
- [ ] Búsqueda sin parámetros → El frontend previene la búsqueda y pide ingresar un criterio.
- [ ] Búsqueda de código inexistente → 404 Not Found y muestra *"No se encontró ningún pedido con los datos ingresados"*.
- [ ] Si la orden está cancelada o rechazada, se resalta en estado de alerta sin romper la visualización de la línea de tiempo.

## ¿Con qué condiciones? (precondiciones y dependencias)
* El vendedor debe estar autenticado con token válido.
* Depende de que *Ventas y Postventa* tenga expuesta la API de consulta de órdenes.
* Regla de negocio: El vendedor tiene permisos de lectura informativa sobre todas las órdenes del cliente sin distinción de canal.

## ¿Qué NO hará? (fuera de alcance)
* No permite cambiar estados de pedidos ni forzar entregas desde esta vista de consulta.
* No permite registrar quejas ni reclamos formales (le corresponde al módulo de Postventa).
