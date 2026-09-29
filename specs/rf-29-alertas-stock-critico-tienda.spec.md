# Spec — RF-29: Panel de Alertas de Stock Crítico y Quiebre en Tienda (v0.1)

### Responsable: Kevin (Frontend / UX)
### Requerimiento Funcional: RF-29: Panel de Alertas de Stock Crítico y Quiebre en Tienda
### Funcionalidad Padre: F11: Torre de Control Operativa de Turno
### Prioridad: Should have (Importante)

---

## ¿Por qué? (problema)
En la venta de calzado e indumentaria deportiva de alta rotación (ej. zapatillas de running o camisetas de fútbol de la selección), las tallas más populares (como 40, 41, M o L) se agotan rápidamente. Si el vendedor no tiene visibilidad inmediata de los artículos que están en quiebre o a punto de agotarse en su tienda física, promete productos a clientes en el mostrador para luego descubrir con frustración en el almacén que ya no quedan unidades disponibles.

## ¿Para qué? (objetivo)
Proveer al personal de mostrador de un widget interactivo de **Alertas de Stock Crítico en Tienda**: mostrando en tiempo real los artículos deportivos de la tienda que cuentan con stock bajo (menor o igual a 2 unidades) o en quiebre inminente (0 unidades), permitiendo al vendedor anticiparse, no prometer tallas agotadas o consultar inmediatamente el stock en el almacén central.

## ¿Hasta dónde? (alcance)
* **Incluido:** Panel lateral colapsable o tarjeta destacada en la pantalla de inicio del POS; consulta al endpoint de stock filtrado por `sucursalTiendaId` con umbral configurable (`stockTienda <= 2`); semáforo visual (rojo para 0 unidades, ámbar para 1 o 2 unidades); filtro rápido por categoría (Calzado, Camisetas, Accesorios); y botón directo *"Ver en Almacén Central"* para ofrecer despacho a domicilio si no hay stock físico local.
* **Excluido:** Órdenes de compra a proveedores mayoristas (competencia de logística central).

## Referencias
* **Contrato:** [api-contracts.md](./api-contracts.md) — `GET /api/v1/productos/stock/critico?tiendaId={id}`
* **Modelo:** `AlertaStockCriticoItem` (`sku`, `nombreProducto`, `marca`, `talla`, `color`, `stockLocal`, `stockAlmacenCentral`, `nivelAlerta`: `"AGOTADO" | "CRITICO"`)

## ¿Qué debe hacer? (comportamiento)

### Backend (Retail / Agregación de Stock)
1. Expone `GET /api/v1/retail/control/stock-critico`:
   * Toma el `tiendaId` asociado al vendedor en su token JWT.
   * Consulta a *Productos y Ofertas* los artículos de la tienda con `stock_disponible <= 2`.
   * Ordena los resultados priorizando artículos con stock 0 y luego stock 1 o 2.
2. Retorna la lista en formato JSON con información de stock local vs almacén central.

### Frontend
1. En la vista principal del mostrador:
   * Widget *"Semáforo de Stock de Tienda"* accesible mediante botón con badge numérico en la esquina superior (ej. badge rojo con `3` artículos en quiebre).
2. Al expandir el panel:
   * Lista visual de tarjetas compactas:
     * Foto miniatura de la prenda/calzado.
     * Nombre y SKU variante (ej. *"Zapatillas Nike Pegasus 40 - Talla 41"*).
     * Etiqueta roja parpadeante: *"AGOTADO EN TIENDA"* (0 unidades) o ámbar *"ÚLTIMAS 2 UNIDADES"*.
     * Indicador secundario: *"Almacén Central: 45 disponibles"*.
3. Acciones rápidas desde la tarjeta:
   * Botón *"Consultar otra Sede"*: Despliega modal con disponibilidad en tiendas cercanas.
   * Clic en la tarjeta copia el SKU al buscador del POS para mayor conveniencia.
4. Auto-actualización ligera: Refresca el estado cada 5 minutos o tras concretar una venta en esa terminal.

## ¿Cómo verificamos? (criterios de aceptación)
- [ ] Vender la penúltima unidad de una zapatilla (queda 1) → Aparece en el panel con semáforo ámbar "Últimas unidades".
- [ ] Vender la última unidad (queda 0) → Cambia automáticamente a semáforo rojo "Agotado en tienda".
- [ ] El widget muestra si hay existencias disponibles en el almacén central para orientar la venta.
- [ ] Clic en el botón del panel permite colapsarlo para no restar espacio a la grilla de productos.

## ¿Con qué condiciones? (precondiciones y dependencias)
* Conexión con el microservicio de *Productos y Ofertas*.
* Regla de Negocio RN-02: Control estricto de existencias físicas en punto de venta.

## ¿Qué NO hará? (fuera de alcance)
* No genera órdenes de reposición automática entre camiones de reparto (función de logística).
