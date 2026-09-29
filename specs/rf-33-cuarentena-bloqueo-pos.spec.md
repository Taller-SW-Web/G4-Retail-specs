# Spec — RF-33: Puesta en Cuarentena y Bloqueo Temporal en POS (v0.1)

### Responsable: Guillermo (QA / Control de Calidad)
### Requerimiento Funcional: RF-33: Puesta en Cuarentena y Bloqueo Temporal en POS
### Funcionalidad Padre: F12: Gestión de Incidencias de Inventario y Mermas en Tienda
### Prioridad: Must have (Crítico)

---

## ¿Por qué? (problema)
Cuando una prenda sufre una avería o se pierde en mostrador, si el bloqueo no se refleja de inmediato en los terminales de la tienda, otro vendedor que esté atendiendo a otro cliente al mismo tiempo podría agregar esa misma unidad al carrito e intentar cobrarla. Esto genera frustración en el comprador cuando el vendedor va a embolsar el producto y nota que está roto o manchado, dañando gravemente la imagen de la tienda deportiva.

## ¿Para qué? (objetivo)
Asegurar que inmediatamente tras el registro de una incidencia (RF-32), la unidad afectada pase a estado **En Cuarentena / Bloqueada para Venta en Mostrador**: descontándose de forma provisional del stock disponible en tienda visible en el POS, impidiendo su selección en el catálogo y bloqueando su adición a nuevos carritos de venta.

## ¿Hasta dónde? (alcance)
* **Incluido:** Reducción inmediata en 1 unidad del `stockDisponible` local en memoria/caché de la tienda; etiquetado visual del SKU como *"Artículo en Cuarentena"* en la matriz de variantes; rechazo automático en el carrito POS si se intenta forzar la adición por código de barras; y bandeja interna *"Artículos en Cuarentena de la Tienda"* accesible por el jefe de tienda o cajero principal.
* **Excluido:** Bloqueo en canales web o chatbot (se gestiona al sincronizar la baja con Productos en RF-34).

## Referencias
* **Contrato:** [api-contracts.md](./api-contracts.md) — `GET /api/v1/retail/inventario/cuarentena`
* **Modelo:** `CuarentenaItem` (`incidenciaId`, `varianteSkuId`, `nombreProducto`, `tallaColor`, `motivo`, `fechaBloqueo`, `estado`: `"EN_CUARENTENA"`)

## ¿Qué debe hacer? (comportamiento)

### Backend (Microservicio Retail)
1. Al recibir la confirmación de la incidencia (RF-32):
   * Actualiza el contador local de stock vendible para esa tienda y SKU: `stock_disponible = stock_disponible - 1`.
   * Mantiene el registro en estado `EN_CUARENTENA`.
2. Expone `GET /api/v1/retail/inventario/cuarentena`:
   * Retorna la lista de todas las prendas actualmente retenidas en la tienda que no han sido devueltas al almacén central ni dadas de baja definitiva.

### Frontend
1. En la matriz de catálogo y variantes (RF-05):
   * Si todas las unidades de una talla pasan a cuarentena, la talla se deshabilita visualmente mostrando la etiqueta: `🚫 No disponible (En revisión física)`.
2. En el escaneo rápido de código de barras (RF-04 / RF-10):
   * Si el vendedor intenta pistolear la etiqueta de una prenda en cuarentena, el POS emite un sonido de advertencia y muestra modal de bloqueo:
     * Título rojo: *"PRODUCTO BLOQUEADO POR CUARENTENA"*.
     * Mensaje: *"Esta prenda tiene una incidencia activa (#INC-0089: Mancha en probador) y no puede ser vendida al público"*.
3. Bandeja *"Prendas en Cuarentena"* (en panel de administración de tienda):
   * Muestra la lista de prendas que deben estar físicamente en la caja de cuarentena del depósito.

## ¿Cómo verificamos? (criterios de aceptación)
- [ ] Reportar una prenda con stock de 1 unidad → La talla queda inhabilitada para la venta en el catálogo de inmediato.
- [ ] Intentar escanear el código de barras de la prenda en cuarentena → El sistema bloquea la adición al carrito con alerta explícita.
- [ ] La bandeja de cuarentena lista la prenda con su número de incidencia y motivo de retención.

## ¿Con qué condiciones? (precondiciones y dependencias)
* Incidencia reportada exitosamente bajo RF-32.
* Regla de Negocio RN-02: Garantía de no vender mercancía dañada o extraviada.

## ¿Qué NO hará? (fuera de alcance)
* No altera el stock patrimonial de la empresa sin la emisión del acta oficial (RF-34).
