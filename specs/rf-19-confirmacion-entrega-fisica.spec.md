# Spec — RF-19: Registro de Confirmación de Entrega Física (v0.1)

### Responsable: Maye (Arquitectura de Software)
### Requerimiento Funcional: RF-19: Registro de Confirmación de Entrega Física
### Funcionalidad Padre: F7: Entrega del Producto en Tienda Física / Pickup
### Prioridad: Must have (Crítico)

---

## ¿Por qué? (problema)
En la entrega presencial de paquetes retirados en mostrador, el paquete puede ser recogido por el propio titular de la compra o por un tercero debidamente autorizado (familiar, mensajero). Si el personal de tienda entrega la bolsa sin validar la identidad física del receptor ni registrar formalmente la constancia de entrega con fecha, hora y responsable, se generan reclamos de compras no entregadas y pérdidas de mercadería sin responsable asignado.

## ¿Para qué? (objetivo)
Permitir al personal de mostrador registrar la conformidad de entrega física del paquete deportivo, capturando los datos de quien retira (titular o tercero autorizado), registrando el checklist de verificación y notificando a *Despacho y Entrega* y *Ventas y Postventa* para actualizar el estado oficial de la orden a `ENTREGADO_EN_TIENDA` con trazabilidad completa.

## ¿Hasta dónde? (alcance)
* **Incluido:** Modal de confirmación de entrega física, selector de parentesco/relación (*Titular de la compra* o *Tercero autorizado*), campos obligatorios de DNI y Nombres de quien retira, checkbox legal de verificación física del paquete, consumo de `POST /api/v1/despachos/confirmar-entrega-tienda`, remoción automática del pedido de la bandeja de pendientes y generación de comprobante digital de retiro.
* **Excluido:** Validación inicial del estado listo para recojo (cubierto en RF-18), y gestión de cambios de talla o devoluciones posteriores a la entrega (competencia del módulo de Postventa).

## Referencias
* **Contrato:** [api-contracts.md](./api-contracts.md) — `POST /api/v1/despachos/confirmar-entrega-tienda` (Sección 4)
* **Modelo:** `ConfirmarEntregaRequest` (`pedidoId`, `dniRecoge`, `nombreRecoge`, `encargadoEntregaId`, `esTerceroAutorizado`: `boolean`), `EntregaConfirmadaResponse` (`status`: `"ENTREGADO_EN_TIENDA"`, `fechaHora`: `string`, `constanciaId`: `string`)

## ¿Qué debe hacer? (comportamiento)

### Backend (Retail / Coordinación de Entrega)
1. Expone `POST /api/v1/retail/pickup/confirmar`:
   * Recibe: `pedidoId`, `dniRecoge`, `nombreRecoge` y bandera `esTerceroAutorizado`.
   * Inyecta `encargadoEntregaId` (ID del vendedor logueado) y `tiendaId`.
   * Valida estrictamente: `dniRecoge` de 8 dígitos y `nombreRecoge` no vacío.
2. Invoca a *Despacho y Entrega* (`POST /api/v1/despachos/confirmar-entrega-tienda`).
   * Si el microservicio valida que la orden está lista, actualiza el registro de despacho físico.
3. Notifica a *Ventas y Postventa* para actualizar el ciclo de vida de la orden general a `ENTREGADO_EN_TIENDA`.
4. Retorna respuesta `200 OK` con constancia digital de entrega (fecha/hora y número de constancia).

### Frontend
1. Al pulsar *"Procesar Retiro"* desde la bandeja de pendientes (RF-18), abre el modal *"Confirmación de Entrega en Tienda"*:
   * Resumen del pedido: Código, Nombre del comprador y lista de artículos/prendas contenidas en el paquete (con foto y talla para verificación física).
2. Selector: *"¿Quién retira la mercadería?"*:
   * **Opción 1: Titular de la compra:**
     * Autocompleta automáticamente los campos con el DNI y Nombres del titular registrado en la compra.
   * **Opción 2: Tercero Autorizado:**
     * Limpia los campos y exige que el vendedor digite el DNI y los Nombres completos de la persona que se encuentra físicamente en el mostrador.
3. Declaración de verificación de paquete:
   * Checkbox obligatorio:
     `[ ] Confirmo que he verificado físicamente el contenido del paquete, el buen estado de las prendas deportivas y el documento de identidad de la persona receptora.`
4. Botón de acción: *"Confirmar y Registrar Entrega"*:
   * Permanece deshabilitado hasta que el checkbox esté marcado y los campos de DNI/Nombre sean válidos.
5. Al pulsar confirmar:
   * Muestra animación de procesamiento.
   * Al recibir `200 OK`:
     * Cierra el modal.
     * Muestra notificación de éxito (*toast*): *"Entrega registrada con éxito. Pedido ORD-RET-2026-0091 finalizado"*.
     * Retira la orden de la bandeja de pendientes de la tienda de forma reactiva.
     * Ofrece opción de imprimir o descargar la constancia de entrega digital.

## ¿Cómo verificamos? (criterios de aceptación)
- [ ] Retiro por el titular autocompleta su DNI y nombres en el formulario modal.
- [ ] Retiro por tercero autorizado permite escribir un nuevo DNI y nombre, validando que el DNI tenga 8 dígitos.
- [ ] Si el checkbox de verificación física no está marcado, el botón de confirmar permanece inactivo.
- [ ] Confirmar la entrega física → Retorna 200 OK, actualiza el estado a `ENTREGADO_EN_TIENDA` y remueve la orden de la bandeja.
- [ ] Se comprueba en el sistema que quedó registrado el ID del vendedor que entregó el producto, la fecha y la hora exacta (cumplimiento RN-03).

## ¿Con qué condiciones? (precondiciones y dependencias)
* Regla de Negocio RN-03: Trazabilidad inmutable de la entrega (vendedor_id, tienda_id, timestamp).
* Regla de Negocio RN-05: El pedido debe estar en estado `LISTO_PARA_RECOJO`.
* No se permiten entregas parciales de prendas: toda la orden se entrega en un único acto.

## ¿Qué NO hará? (fuera de alcance)
* No procesa devoluciones de dinero ni cambios de mercadería en este acto (se derivan al módulo de Postventa).
* No solicita firma manuscrita biométrica avanzada (se convalida con documento físico y checklist del cajero).
