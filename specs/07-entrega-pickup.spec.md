# Spec — Entrega del Producto en Tienda Física (Pickup) (v0.1)

### Responsable: Maye (Arquitectura de Software)
### Requerimientos Funcionales asociados: RF-18, RF-19

---

## ¿Por qué? (problema)
Muchos clientes compran en línea (web o chatbot) y eligen retirar sus prendas en la tienda física (*Pickup*). Si el personal de tienda entrega el paquete sin registrarlo formalmente en el sistema, la orden queda eternamente como "pendiente", no hay evidencia de quién retiró el pedido y se generan reclamos de entregas no efectuadas.

## ¿Para qué? (objetivo)
Permitir al personal de tienda validar que un pedido esté en el local listo para ser retirado, verificar la identidad de quien recoge la mercadería y registrar la entrega física con actualización en tiempo real en los módulos de *Despacho y Entrega* y *Ventas y Postventa*.

## ¿Hasta dónde? (alcance)
* **Incluido:** Bandeja de pedidos con retiro en la tienda actual, buscador por código de pedido o documento, validación de estado `LISTO_PARA_RECOJO`, captura de datos de la persona que retira (DNI y nombre) y registro de la confirmación de entrega en tienda.
* **Excluido:** Asignación de rutas a motorizados, gestión de envíos a domicilio (responsabilidad de *Despacho y Entrega*) y devoluciones o cambios posteriores en mostrador (le corresponde a Postventa).

## Referencias
* **Contrato:** [specs/api-contracts.md](file:///c:/Users/Mihae/Programacion/Activos/modulo-retail/specs/api-contracts.md) — `GET /api/v1/despachos/tienda/{tiendaId}/pendientes-pickup` y `POST /api/v1/despachos/confirmar-entrega-tienda`
* **Modelo:** `EntregaTienda` (`pedidoId`, `tiendaId`, `dniRecoge`, `nombreRecoge`, `encargadoEntregaId`, `fechaHoraEntrega`)

## ¿Qué debe hacer? (comportamiento)

### Backend (Retail / Coordinación con Despacho y Ventas)
1. Expone `GET /api/v1/retail/pickup/pendientes`:
   * Consulta a *Despacho y Entrega* los pedidos asignados a la tienda del usuario en sesión que se encuentren en estado `LISTO_PARA_RECOJO`.
2. Expone `POST /api/v1/retail/pickup/confirmar`:
   * Recibe: `pedidoId`, `dniRecoge` y `nombreRecoge`.
   * Valida que el `dniRecoge` tenga 8 dígitos numéricos y el nombre no esté vacío.
   * Notifica a *Despacho y Entrega* para registrar la entrega física.
   * Notifica a *Ventas y Postventa* para actualizar el estado oficial de la orden a `ENTREGADO_EN_TIENDA`.
   * Retorna `200 OK` con constancia digital de entrega.

### Frontend
1. Módulo "Entregas en Tienda (Pickup)" en la navegación principal.
2. Bandeja de órdenes listas para recojo con filtros por fecha y buscador rápido por DNI/código.
3. Botón de acción en cada orden: *"Procesar Retiro"*.
4. Modal de verificación de entrega:
   * Muestra resumen de la orden: comprador titular, artículos y prendas a entregar.
   * Opción: "¿Quién retira?": *Titular de la compra* (autocompleta con datos del comprador) o *Tercero autorizado*.
   * Si es tercero autorizado: campos obligatorios para DNI y Nombres completos de quien recoge.
   * Checkbox de confirmación: *"Confirmo que he verificado físicamente el paquete y el documento del receptor"*.
5. Botón *"Registrar Entrega Física"* (bloqueado hasta marcar el checkbox de verificación).
6. Al confirmar, emite mensaje de éxito y retira la orden de la bandeja de pendientes.

## ¿Cómo verificamos? (criterios de aceptación)
- [ ] La bandeja solo lista pedidos cuya modalidad de entrega sea retiro en tienda y cuyo estado sea `LISTO_PARA_RECOJO`.
- [ ] Pedido que aún está en preparación o en camino a la tienda no permite registrar entrega física y muestra advertencia *"El pedido aún no ha llegado a tienda"*.
- [ ] Intentar confirmar la entrega sin DNI de quien recoge → El frontend bloquea la confirmación.
- [ ] Confirmación exitosa con datos completos → 200 OK, actualiza el estado a `ENTREGADO_EN_TIENDA` en Ventas y Despacho y la orden desaparece de la lista de pendientes.
- [ ] Se registra la trazabilidad: ID del vendedor que atendió la entrega, fecha y hora exacta.

## ¿Con qué condiciones? (precondiciones y dependencias)
* El pedido debe haber sido previamente pagado y preparado por el centro logístico/tienda.
* Depende de los microservicios de *Despacho y Entrega* y *Ventas y Postventa*.
* Regla de negocio: No se puede entregar ningún artículo deportivo de forma parcial si la orden contempla múltiples ítems.

## ¿Qué NO hará? (fuera de alcance)
* No gestiona motorizados ni despachos a domicilio.
* No permite cambiar el punto de recojo a otra tienda desde esta vista.
