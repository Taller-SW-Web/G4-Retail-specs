# Spec — RF-23: Validación de Comprobante y Plazos de Cambio Presencial (v0.1)

### Responsable: Cristhian (Backend Developer)
### Requerimiento Funcional: RF-23: Validación de Comprobante y Plazos de Cambio Presencial
### Funcionalidad Padre: F9: Gestión de Cambios y Devoluciones en Mostrador
### Prioridad: Must have (Condicionado a F9)

---

## ¿Por qué? (problema)
Los clientes acuden frecuentemente a las tiendas físicas solicitando cambio de talla de zapatillas, cambio de color de camiseta o cambio por defecto de fábrica. Si el vendedor no puede comprobar la autenticidad de la compra original, el tiempo transcurrido o si el producto ya fue cambiado previamente, se corre el riesgo de aceptar prendas de procedencia dudosa o fuera de la política de garantía de la tienda.

## ¿Para qué? (objetivo)
Permitir al vendedor en mostrador buscar y validar la compra original a través del número de boleta/factura, código de ticket de regalo o DNI del cliente, verificando contra el módulo de *Ventas y Postventa* que la orden exista, esté pagada, no haya sido anulada y se encuentre dentro del plazo legal y comercial de cambio (30 días naturales desde la compra).

## ¿Hasta dónde? (alcance)
* **Incluido:** Buscador de comprobante por serie/correlativo (ej. `B001-00045231`), por código de barras de Ticket de Regalo o por DNI del cliente; validación de la fecha de compra contra la regla de vigencia (máximo 30 días); verificación de que los ítems solicitados no hayan sido devueltos previamente; y despliegue del detalle de prendas aptas para cambio.
* **Excluido:** Inspección física de la prenda (cubierto en RF-24) y emisión del vale de canje (cubierto en RF-25).

## Referencias
* **Contrato:** [api-contracts.md](./api-contracts.md) — `GET /api/v1/ventas/comprobantes/validar-cambio`
* **Modelo:** `ValidacionCambioQuery` (`serieCorrelativo`, `codigoTicketRegalo`, `dniCliente`), `DetalleOrdenCambioResponse` (`pedidoId`, `fechaEmision`, `diasTranscurridos`, `plazoValido`, `items`: `[{sku, descripcion, talla, color, precioPagado, cantidadComprada, cantidadDisponibleCambio}]`)

## ¿Qué debe hacer? (comportamiento)

### Backend (Retail / Integración con Ventas)
1. Expone `GET /api/v1/retail/postventa/validar-comprobante`:
   * Recibe parámetros de búsqueda: `comprobante` o `codigoTicket` o `dni`.
   * Consulta al microservicio de *Ventas y Postventa*.
2. Evalúa las reglas de negocio:
   * Calcula `diasTranscurridos = diferenciaDias(NOW(), fechaEmision)`.
   * Si `diasTranscurridos > 30`, marca `plazoValido = false` y especifica el motivo: *"Plazo de cambio expirado (máximo 30 días calendario según política de tienda)"*.
   * Verifica el estado del pedido: debe ser `PAGADO` o `ENTREGADO`. Si el pedido está `CANCELADO` o `DEVUELTO_TOTAL`, rechaza con `422 Unprocessable Entity`.
3. Retorna la lista de productos comprados indicando cuántas unidades de cada SKU están todavía disponibles para cambio.

### Frontend
1. Módulo en el menú lateral: *"Cambios y Devoluciones en Mostrador"*.
2. Barra de búsqueda con lector de código de barras:
   * Campo para ingresar serie y correlativo (ej. `B001-00045231`) o escanear el código del Ticket de Regalo.
   * Campo alternativo para buscar por DNI del cliente.
3. Vista de validación:
   * Si el comprobante es válido y dentro del plazo:
     * Muestra tarjeta con datos de la compra: Fecha original, tienda de origen y cliente.
     * Etiqueta verde: *"Válido para cambio (Día 12 de 30)"*.
     * Lista de prendas compradas con casillas de verificación para seleccionar cuáles desea cambiar el cliente.
   * Si el plazo expiró:
     * Etiqueta roja: *"Plazo Expirado (Compra realizada hace 45 días)"*. Bloquea la selección de prendas.
   * Si el comprobante no existe:
     * Alerta: *"No se encontró ninguna compra con los datos ingresados"*.

## ¿Cómo verificamos? (criterios de aceptación)
- [ ] Búsqueda de boleta emitida hace 10 días → Sistema despliega los artículos comprados y permite seleccionarlos para cambio.
- [ ] Búsqueda de boleta emitida hace 35 días → Sistema muestra mensaje de plazo vencido y no permite continuar con el trámite.
- [ ] Escaneo del código de barras de un Ticket de Regalo → Carga la compra original asociada sin mostrar los precios al cliente.
- [ ] Búsqueda de un comprobante inexistente → Muestra error 404 de no encontrado.

## ¿Con qué condiciones? (precondiciones y dependencias)
* Conectividad con el microservicio de *Ventas y Postventa*.
* Regla de Negocio RN-01 y RN-03: Validación tributaria y trazabilidad de postventa.

## ¿Qué NO hará? (fuera de alcance)
* No autoriza excepciones gerenciales fuera de plazo (requeriría flujo especial de postventa central).
