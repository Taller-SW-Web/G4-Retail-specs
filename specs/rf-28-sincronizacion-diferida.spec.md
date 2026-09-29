# Spec — RF-28: Sincronización Diferida y Conciliación Automática (v0.1)

### Responsable: Cristhian (Backend Developer)
### Requerimiento Funcional: RF-28: Sincronización Diferida y Conciliación Automática
### Funcionalidad Padre: F10: Modo de Contingencia y Resiliencia Offline
### Prioridad: Must have (Crítico)

---

## ¿Por qué? (problema)
Una vez que el internet o la red vuelven a estar operativos en la tienda, las ventas acumuladas en la base de datos local del navegador deben enviarse a los microservicios centrales (*Ventas y Postventa* y *Productos y Ofertas*). Si este proceso no se hace de forma secuencial, atómica y con control de duplicidad, se pueden generar ventas duplicadas, inconsistencias de stock en el inventario central o pérdida de órdenes que no llegaron a registrarse.

## ¿Para qué? (objetivo)
Implementar un servicio en background de sincronización y conciliación automática que, al detectar red estable, lea las órdenes en estado `PENDIENTE` de IndexedDB, las envíe secuencialmente al backend mediante un endpoint de conciliación en lote (`POST /api/v1/retail/contingencia/sincronizar`), asigne las boletas oficiales definitivas, actualice el stock central y cambie el estado local a `RESINCRONIZADO`.

## ¿Hasta dónde? (alcance)
* **Incluido:** Cola de despacho asíncrona FIFO (primero en entrar, primero en salir), validación de idempotencia en backend mediante `ventaLocalUuid`, reintentos exponenciales ante fallas de red intermitentes, asignación de numeración correlativa electrónica oficial de SUNAT para reemplazar la serie de contingencia, decremento definitivo de stock central y reporte consolidado de sincronización exitosa al vendedor.
* **Excluido:** Resolución manual de discrepancias graves (cubierto en bitácora de auditoría).

## Referencias
* **Contrato:** [api-contracts.md](./api-contracts.md) — `POST /api/v1/retail/contingencia/sincronizar`
* **Modelo:** `SincronizacionLoteRequest` (`lote`: `[VentaOfflineSchema]`), `SincronizacionLoteResponse` (`totalProcesados`, `exitosos`, `errores`, `ordenesMapeadas`: `[{idLocal, pedidoIdOficial, comprobanteOficial}]`)

## ¿Qué debe hacer? (comportamiento)

### Backend (Retail / Conciliación y Despacho)
1. Expone `POST /api/v1/retail/contingencia/sincronizar`:
   * Recibe el arreglo de ventas offline acumuladas.
   * Por cada venta:
     * Verifica en `RET_CONTINGENCIA_OFFLINE_LOG` si el `venta_local_uuid` ya fue procesado previamente (garantía estricta de idempotencia para evitar cobros dobles).
     * Si no ha sido procesada:
       * Llama a *Ventas y Postventa* (`POST /api/v1/ordenes/presenciales`) enviando `canal: "RETAIL_OFFLINE_SYNC"` y la fecha original de emisión física.
       * Llama a *Productos y Ofertas* (`POST /api/v1/inventario/consumir`) para restar definitivamente las prendas del inventario central.
       * Registra el mapeo en `RET_CONTINGENCIA_OFFLINE_LOG` con `estado = 'RESINCRONIZADO'`.
2. Responde `200 OK` con el resumen del lote y los códigos de comprobantes oficiales generados.

### Frontend
1. Al restablecerse la red:
   * El servicio de sincronización lee todos los registros con `estado == 'PENDIENTE'` en IndexedDB.
   * Muestra un indicador visual en el banner: *"Sincronizando 3 ventas pendientes... (Progreso: 1/3)"*.
2. Envía el lote al backend de Retail.
3. Al recibir la confirmación exitosa de cada orden:
   * Actualiza el registro local en IndexedDB a `estado = 'RESINCRONIZADO'`.
   * Registra el número de comprobante oficial devuelto por el servidor central.
4. Cuando la cola llega a 0 pendientes:
   * El banner cambia a verde con notificación toast: *"Todas las ventas offline se sincronizaron con éxito en los servidores centrales"*.
   * Tras 5 segundos, el banner se oculta y la interfaz regresa a modo online normal.

## ¿Cómo verificamos? (criterios de aceptación)
- [ ] Con 2 ventas almacenadas en IndexedDB, al conectar la red el sistema las envía automáticamente sin intervención del usuario.
- [ ] El backend registra las órdenes en Ventas y descuenta el stock en Productos con la fecha/hora original en que ocurrieron.
- [ ] Enviar dos veces el mismo lote por falla de conexión no duplica las órdenes (idempotencia verificada por UUID).
- [ ] Los registros en IndexedDB quedan marcados como `RESINCRONIZADO`.
- [ ] El banner desaparece al culminar el 100% de la sincronización.

## ¿Con qué condiciones? (precondiciones y dependencias)
* Red restablecida y backend de Retail accesible.
* Regla de Negocio RN-02 y RN-03: Consistencia eventual de stock y auditoría de ventas.

## ¿Qué NO hará? (fuera de alcance)
* No modifica ventas offline que ya hayan sido firmadas con su hash local.
