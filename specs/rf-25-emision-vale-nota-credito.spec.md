# Spec — RF-25: Emisión de Vale de Compra / Nota de Crédito Presencial (v0.1)

### Responsable: Cristhian (Backend Developer)
### Requerimiento Funcional: RF-25: Emisión de Vale de Compra / Nota de Crédito Presencial
### Funcionalidad Padre: F9: Gestión de Cambios y Devoluciones en Mostrador
### Prioridad: Should have (Secundario si F9 entra)

---

## ¿Por qué? (problema)
Una vez que el cliente entrega la prenda deportiva y esta supera la inspección física, se debe formalizar la compensación económica: el cliente puede querer llevarse inmediatamente otra talla de la tienda física o requerir un saldo a favor (Vale de Compra / Nota de Crédito) para gastarlo en otro momento. Si no se emite un comprobante formal con saldo inmutable y código de barras, se generan fraudes por doble canje o confusión en caja.

## ¿Para qué? (objetivo)
Permitir al vendedor culminar el proceso de cambio en mostrador ofreciendo dos caminos: (1) **Canje Inmediato:** Cargar el saldo a favor directamente como medio de pago en el carrito POS para que el cliente se lleve la nueva talla al instante; o (2) **Emisión de Vale de Compra / Nota de Crédito:** Generar un documento impreso térmico con código único alfanumérico, código de barras y vigencia de 90 días, sincronizándolo con el microservicio de *Ventas y Postventa*.

## ¿Hasta dónde? (alcance)
* **Incluido:** Cálculo del monto neto acreditable (igual al precio efectivamente pagado por el cliente, descontando promociones previas), opción de canje inmediato contra el carrito activo de mostrador, opción de emisión de Vale de Tienda / Nota de Crédito con código correlativo, sincronización con *Ventas y Postventa*, y reporte de devolución de stock a *Productos y Ofertas*.
* **Excluido:** Devolución de dinero en efectivo en mano (según política de tienda deportiva los cambios son por prendas o vales, o gestionados mediante extorno bancario en postventa central).

## Referencias
* **Contrato:** [api-contracts.md](./api-contracts.md) — `POST /api/v1/ventas/postventa/generar-nota-credito`
* **Modelo:** `ResolucionCambioRequest` (`pedidoIdOrigen`, `skuDevuelto`, `montoAcreditar`, `modalidad`: `"CANJE_INMEDIATO" | "EMISION_VALE"`, `clienteId`), `ResolucionCambioResponse` (`codigoVale`, `montoSaldo`, `fechaVencimiento`, `qrCanje`)

## ¿Qué debe hacer? (comportamiento)

### Backend (Retail / Coordinación con Ventas)
1. Expone `POST /api/v1/retail/postventa/completar-cambio`:
   * Verifica la sesión activa de caja en la terminal.
   * Solicita al microservicio de *Ventas y Postventa* la anulación parcial del ítem en la orden origen y la creación del Vale/Nota de Crédito.
   * Si la prenda fue marcada como apta (`REINGRESO_INVENTARIO`): Envía notificación a *Productos y Ofertas* (`POST /api/v1/inventario/incrementar-stock`) sumando 1 unidad al stock de la tienda.
2. Registra la transacción en `RET_SOLICITUD_CAMBIO_MOSTRADOR`.
3. Retorna los datos del vale generado con código único de canje.

### Frontend
1. Pantalla de Resolución de Cambio:
   * Muestra el resumen financiero:
     * Prenda devuelta: *"Camiseta Perú 2026 Talla M"*.
     * Monto a favor del cliente: `S/ 199.90`.
2. Selector de modalidad de compensación:
   * Opción A: *"Canje Inmediato en Tienda"*:
     * Inyecta automáticamente los `S/ 199.90` como saldo a favor en el panel del Carrito POS.
     * El vendedor escanea la nueva talla deseada (ej. Talla L) y solo cobra la diferencia si el nuevo artículo es más caro.
   * Opción B: *"Emitir Vale de Compra (Nota de Crédito)"*:
     * Genera un comprobante térmico con código único de barras.
3. Botón *"Finalizar Cambio e Imprimir Vale"*:
   * Emite el ticket térmico con:
     * Título: `VALE DE COMPRA / NOTA DE CRÉDITO TIENDA`.
     * Código de canje: `NC-RET-2026-00412`.
     * Nombre y DNI del titular.
     * Monto acreditado: `S/ 199.90`.
     * Leyenda: *"Válido para canje en cualquier tienda física hasta [Fecha +90 días]"*.
     * Código de barras 1D y QR para lectura en escáner de caja.

## ¿Cómo verificamos? (criterios de aceptación)
- [ ] Selección de "Canje Inmediato" abona el monto exacto al carrito POS para la nueva compra.
- [ ] Selección de "Emitir Vale" genera el código único de vale con 90 días de vigencia legal.
- [ ] El ticket impreso del vale contiene código de barras escaneable y datos del titular.
- [ ] El stock del producto devuelto en buen estado se incrementa automáticamente en el inventario de la tienda.

## ¿Con qué condiciones? (precondiciones y dependencias)
* Prenda debidamente inspeccionada y aprobada (RF-24).
* Regla de Negocio RN-01 y RN-03: Normativa de comprobantes de pago y notas de crédito.

## ¿Qué NO hará? (fuera de alcance)
* No realiza transferencias interbancarias ni extornos a tarjetas de crédito en mostrador (gestión en postventa web).
