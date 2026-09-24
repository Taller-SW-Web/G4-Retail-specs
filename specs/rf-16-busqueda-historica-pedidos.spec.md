# Spec — RF-16: Búsqueda Histórica de Órdenes de Clientes (v0.1)

### Responsable: Cristhian (Backend Developer)
### Requerimiento Funcional: RF-16: Búsqueda Histórica de Órdenes de Clientes
### Funcionalidad Padre: F6: Consulta y Seguimiento de Pedidos del Cliente
### Prioridad: Should have (Importante)

---

## ¿Por qué? (problema)
Los compradores se acercan al mostrador de la tienda física para consultar sobre compras que realizaron en canales digitales (tienda virtual o chatbot) o en días anteriores. Si el personal de mostrador no tiene una herramienta ágil para buscar pedidos por el código de orden o por el DNI/RUC del cliente, no puede brindar información al cliente, generando insatisfacción y desconfianza en la marca.

## ¿Para qué? (objetivo)
Permitir al personal de mostrador buscar y listar órdenes de compra realizadas en cualquier canal comercial (Web, Chatbot o Retail), ya sea ingresando el código único de pedido (`pedidoId`) o el número de documento de identidad del comprador (DNI o RUC), consultando al microservicio de *Ventas y Postventa*.

## ¿Hasta dónde? (alcance)
* **Incluido:** Módulo "Seguimiento de Pedidos" en la navegación principal de Retail, formulario de búsqueda con selector de criterio (Por Código de Pedido o Por Documento de Identidad), consumo de endpoints `GET /api/v1/ordenes/{id}` y `GET /api/v1/ordenes?clienteDoc={doc}`, tabla o lista de pedidos encontrados ordenados cronológicamente, y selección de un pedido para ver su detalle.
* **Excluido:** Visualización de la línea de tiempo gráfica de estados (cubierto en RF-17), entrega física de paquetes pickup (cubierto en RF-18 y RF-19), y anulación o devolución de compras (competencia del módulo de Postventa).

## Referencias
* **Contrato:** [api-contracts.md](./api-contracts.md) — `GET /api/v1/ordenes/{id}` (Sección 3)
* **Modelo:** `BusquedaOrdenesParams` (`codigoPedido`?: `string`, `documentoCliente`?: `string`), `OrdenResumenItem` (`pedidoId`, `fechaCreacion`, `canalOrigen`, `cliente`: `{nombres, documento}`, `montoTotal`, `estadoActual`, `modalidadEntrega`)

## ¿Qué debe hacer? (comportamiento)

### Backend (Retail / Pasarela a Ventas y Postventa)
1. Expone `GET /api/v1/retail/pedidos/consultar`:
   * Recibe parámetros en query string: `codigoPedido` o `documentoCliente`.
   * Valida que al menos uno de los dos parámetros esté presente y no sea vacío; si ambos están vacíos, responde `400 Bad Request`.
2. Reenvía la solicitud al microservicio de *Ventas y Postventa*:
   * Si viene `codigoPedido`: consulta `GET /api/v1/ordenes/{codigoPedido}`.
   * Si viene `documentoCliente`: consulta `GET /api/v1/ordenes?clienteDoc={documentoCliente}`.
3. Si el microservicio responde con la orden o lista de órdenes (`200 OK`):
   * Retorna las órdenes ordenadas cronológicamente de la más reciente a la más antigua.
4. Si no existen órdenes registradas para los datos ingresados:
   * Retorna `404 Not Found` con mensaje amigable: `{"mensaje": "No se encontraron pedidos con los criterios ingresados"}`.

### Frontend
1. Acceso desde la barra de navegación principal mediante la pestaña *"Seguimiento de Pedidos"*.
2. Barra de búsqueda superior:
   * Selector tipo toggle o radio: *"Buscar por Código de Pedido"* o *"Buscar por DNI/RUC"*.
   * Campo de texto con placeholder adaptativo según la selección (ej. `"Ej. ORD-RET-2026-0091"` o `"Ingrese 8 dígitos de DNI"`).
   * Botón *"Buscar Pedido"* con soporte de tecla `Enter`.
3. Resultados de búsqueda:
   * Si la búsqueda fue por código de pedido exacto y existe: selecciona y abre inmediatamente la ficha del pedido.
   * Si la búsqueda fue por documento y el cliente tiene varias órdenes:
     * Muestra una lista/tabla con las órdenes encontradas: N° Pedido, Fecha de compra, Canal (Web, Chatbot, Tienda), Total (S/) y Estado actual (`PAGADO`, `LISTO_PARA_RECOJO`, etc.).
     * Botón *"Ver Detalle"* en cada fila para cargar la información profunda del pedido.
4. Si la búsqueda arroja `404`:
   * Muestra un panel informativo con ilustración o ícono de búsqueda vacía: *"No se encontró ninguna compra registrada con el código o documento ingresado"*.

## ¿Cómo verificamos? (criterios de aceptación)
- [ ] Búsqueda por código existente `ORD-RET-2026-0091` → Retorna 200 OK y carga la orden en menos de 1 segundo.
- [ ] Búsqueda por DNI de cliente recurrente con 3 pedidos → Lista las 3 órdenes ordenadas de la más reciente a la más antigua.
- [ ] Búsqueda sin ingresar ningún parámetro → El frontend bloquea la acción y solicita ingresar un código o documento.
- [ ] Búsqueda de código erróneo o inexistente → Responde 404 Not Found y muestra mensaje informativo sin romper la interfaz.
- [ ] La búsqueda reconoce órdenes originadas tanto en la tienda Web como en la tienda física Retail.

## ¿Con qué condiciones? (precondiciones y dependencias)
* El vendedor debe estar autenticado.
* El microservicio de *Ventas y Postventa* debe proveer la consulta multicanal de órdenes.
* Regla de negocio: El personal de mostrador tiene acceso de solo lectura a los pedidos de clientes de todos los canales.

## ¿Qué NO hará? (fuera de alcance)
* No permitirá modificar importes, artículos ni estados de pedidos desde este buscador.
* No descargará padrones masivos de pedidos de toda la corporación.
