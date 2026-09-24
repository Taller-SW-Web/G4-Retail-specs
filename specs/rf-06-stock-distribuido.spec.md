# Spec — RF-06: Consulta de Stock Distribuido en Tiempo Real (v0.1)

### Responsable: Kevin (Frontend / UX)
### Requerimiento Funcional: RF-06: Consulta de Stock Distribuido en Tiempo Real
### Funcionalidad Padre: F2: Consulta del Catálogo y Disponibilidad de Productos
### Prioridad: Must have (Crítico)

---

## ¿Por qué? (problema)
En una tienda de retail deportivo, los clientes preguntan constantemente si hay stock físico inmediato para llevarse la prenda puesta, o si se puede pedir para entrega posterior si está agotada en el local. Si el sistema no diferencia con total certeza entre el stock físico de la tienda actual y las existencias en almacén central u otras sedes, el vendedor puede vender prendas inexistentes en mostrador, provocando reclamos y anulación de ventas.

## ¿Para qué? (objetivo)
Consultar en tiempo real al microservicio de *Productos y Ofertas* y presentar de manera visual y diferenciada la disponibilidad física en la tienda actual frente al stock en almacén central, utilizando un código semafórico de disponibilidad para guiar la decisión del vendedor en mostrador.

## ¿Hasta dónde? (alcance)
* **Incluido:** Discriminación de inventario por sede utilizando el `tiendaId` del vendedor, cálculo de niveles de disponibilidad, semáforo visual de stock (Verde, Ámbar, Gris/Rojo), badges informativos de *"Stock en Tienda"* vs *"Disponible en Almacén Central"*, y deshabilitación de venta presencial inmediata cuando `stockTienda == 0`.
* **Excluido:** Búsqueda inicial de catálogo (cubierto en RF-04), selector de variantes de talla/color (cubierto en RF-05), y decremento transaccional de unidades al pagar (cubierto en RF-14).

## Referencias
* **Contrato:** [api-contracts.md](./api-contracts.md) — `GET /api/v1/productos/catalogo` (Sección 2)
* **Modelo:** `StockDetalle` (`sku`, `tiendaId`, `stockTienda`, `stockAlmacenCentral`, `disponibleInmediato`: `boolean`)

## ¿Qué debe hacer? (comportamiento)

### Backend (Retail / Procesamiento de Stock)
1. Al recibir la consulta de catálogo, extrae el `tiendaId` del token del vendedor autenticado (ej. `TIENDA-MIRAFLORES`).
2. Consulta el inventario al microservicio de *Productos y Ofertas* enviando dicho identificador.
3. Para cada variante procesa los dos saldos de inventario:
   * `stockTienda`: Unidades físicas disponibles en la tienda actual.
   * `stockAlmacenCentral`: Unidades en centro de distribución principal.
4. Calcula el estado operativo de disponibilidad:
   * Si `stockTienda > 3` ➔ Estado `DISPONIBLE` (suficiente).
   * Si `stockTienda >= 1` y `stockTienda <= 3` ➔ Estado `ULTIMAS_UNIDADES` (crítico).
   * Si `stockTienda == 0` y `stockAlmacenCentral > 0` ➔ Estado `SOLO_ALMACEN_CENTRAL`.
   * Si ambos son `0` ➔ Estado `AGOTADO_TOTAL`.
5. Retorna la respuesta con los campos de stock clasificados.

### Frontend
1. En la ficha y matriz de variantes del producto, muestra indicadores visuales claros:
   * **Círculo Verde / Badge Verde:** Stock en tienda suficiente (`> 3 unidades disponibles`).
   * **Círculo Ámbar / Badge Ámbar:** *"¡Últimas X unidades en tienda!"* (`1 a 3 unidades`).
   * **Badge Gris / Azul suave:** *"Agotado en tienda — Disponible en Almacén Central (X unid.)"*.
   * **Badge Rojo:** *"Agotado en toda la cadena"*.
2. Comportamiento en la acción de mostrador:
   * Si `stockTienda > 0`: Habilita el botón *"Agregar para Venta Inmediata"*.
   * Si `stockTienda == 0` pero `stockAlmacenCentral > 0`: Muestra aviso informativo *"No disponible para venta presencial inmediata. Disponible solo para pedido web/entrega programada"*.
   * Si está totalmente agotado: Deshabilita cualquier acción de compra.
3. Actualiza el semáforo de forma instantánea al cambiar entre diferentes tallas o colores.

## ¿Cómo verificamos? (criterios de aceptación)
- [ ] Variante con 8 unidades en tienda local → Muestra badge verde y permite venta presencial inmediata.
- [ ] Variante con 2 unidades en tienda local → Muestra advertencia ámbar *"Últimas 2 unidades en tienda"*.
- [ ] Variante con 0 unidades en tienda y 20 en almacén central → Muestra *"Disponible solo en Almacén Central"* y previene agregarla como venta física inmediata de mostrador.
- [ ] Variante con 0 unidades totales → Muestra *"Agotado"* y botón totalmente inhabilitado.
- [ ] El `tiendaId` utilizado para consultar el stock coincide exactamente con la tienda del vendedor en sesión.

## ¿Con qué condiciones? (precondiciones y dependencias)
* El vendedor debe estar autenticado con su tienda asignada.
* Regla de Negocio RN-02: El Módulo Retail no es dueño del inventario ni puede modificar saldos localmente; la consulta debe ser en tiempo real a *Productos y Ofertas*.

## ¿Qué NO hará? (fuera de alcance)
* No ejecutará traslados entre tiendas ni órdenes de abastecimiento logístico.
* No reservará ni bloqueará unidades físicas durante la simple visualización (la reserva/consumo se hace al pagar).
