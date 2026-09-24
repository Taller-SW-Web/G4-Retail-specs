# Spec — RF-10: Gestión del Carrito POS en Mostrador (v0.1)

### Responsable: Mihael (Product Owner)
### Requerimiento Funcional: RF-10: Gestión del Carrito POS en Mostrador
### Funcionalidad Padre: F4: Registro de Venta Asistida y Aplicación de Ofertas/Promociones
### Prioridad: Must have (Crítico)

---

## ¿Por qué? (problema)
Durante la venta asistida en tienda, el cliente agrega prendas, pide cambiar cantidades o decide retirar artículos de la compra antes de pagar. Si el carrito de mostrador es rígido, no valida los topes de stock local físico o se pierde si el navegador se refresca, se genera frustración en el comprador y descuadres para el vendedor.

## ¿Para qué? (objetivo)
Permitir al vendedor armar y gestionar de forma reactiva la orden en mostrador mediante un carrito POS lateral permanente: agregando productos por su variante específica (SKU), incrementando o disminuyendo cantidades con validación estricta de stock disponible en tienda, eliminando ítems individuales o vaciando el carrito completo, con persistencia en el estado local del navegador.

## ¿Hasta dónde? (alcance)
* **Incluido:** Panel lateral de carrito POS visible, adición de variantes con verificación contra `stockTienda`, botones de incremento (`+`) y decremento (`-`) con bloqueo al llegar al stock máximo, eliminación de ítems con confirmación rápida, botón para vaciar el carrito, y persistencia en memoria/localStorage del navegador.
* **Excluido:** Aplicación y cálculo dinámico de promociones/cupones (cubierto en RF-11), cálculo de impuestos y desglose financiero (cubierto en RF-12), y reserva de stock transaccional en base de datos (se ejecuta en RF-14 al pagar).

## Referencias
* **Contrato:** [api-contracts.md](./api-contracts.md) — `GET /api/v1/productos/catalogo` (Sección 2)
* **Modelo:** `CarritoItem` (`sku`, `productoId`, `nombre`, `marca`, `talla`, `color`, `precioUnitario`, `cantidad`, `stockMaximoTienda`, `subtotalLinea`)

## ¿Qué debe hacer? (comportamiento)

### Backend (Retail / Soporte de Validación de Carrito)
1. Expone endpoint o función de validación de estructura de carrito:
   * Recibe la lista de ítems (`sku`, `cantidad`).
   * Valida que las cantidades sean números enteros mayores a cero (`cantidad > 0`).
2. Verifica contra el catálogo de *Productos y Ofertas* que cada SKU continúe existiendo y activo.

### Frontend
1. Muestra un panel lateral derecho permanente con el título *"Carrito de Venta Mostrador"*:
   * Contador de artículos totales en el encabezado (ej. `3 prendas`).
2. Al pulsar *"Agregar al Carrito"* desde la matriz de catálogo (RF-05):
   * Si el SKU no está en el carrito: lo agrega con `cantidad = 1`.
   * Si el SKU ya estaba en el carrito: incrementa su cantidad en 1, siempre que `cantidad + 1 <= stockTienda`.
3. Controles por cada ítem en el carrito:
   * Foto miniatura, nombre del producto, talla y color claramente identificados.
   * Precio unitario de lista.
   * Controles de cantidad: Botón `-`, input numérico editable y Botón `+`.
   * Si la cantidad es `1`, presionar `-` despliega opción de eliminar el ítem.
   * Si la cantidad alcanza el `stockTienda`, el botón `+` se deshabilita visualmente y muestra tooltip: *"Stock máximo disponible en tienda alcanzado"*.
   * Ícono de tacho de basura para remover el producto directamente.
4. Acción de vaciar carrito:
   * Botón *"Limpiar Carrito"* que solicita confirmación: *"¿Desea vaciar todos los productos del carrito actual?"*.
5. Persistencia:
   * El estado del carrito se almacena en el `localStorage` o `sessionStorage` del navegador para que no se pierda ante recargas involuntarias de la pestaña.

## ¿Cómo verificamos? (criterios de aceptación)
- [ ] Agregar un producto nuevo lo lista en el carrito con cantidad 1 y subtotal correcto.
- [ ] Agregar un producto que ya tiene stock máximo de 3 unidades en tienda: al llegar a 3 unidades, el botón `+` se desactiva y no permite subir a 4.
- [ ] Reducir la cantidad de 2 a 1 actualiza el subtotal de la línea de inmediato.
- [ ] Clic en el ícono de eliminar retira el producto y recalcula la cantidad total de artículos.
- [ ] Recargar la página del navegador (F5) conserva los productos agregados previamente en el carrito.
- [ ] Botón "Limpiar Carrito" vacía todos los artículos tras confirmar la acción.

## ¿Con qué condiciones? (precondiciones y dependencias)
* Debe haber al menos un producto seleccionado con variante válida.
* Regla de negocio: No se puede vender más unidades de las existentes físicamente en la tienda para venta presencial inmediata.

## ¿Qué NO hará? (fuera de alcance)
* No aparta físicamente prendas en el almacén mientras el cliente sigue en el pasillo de la tienda.
* No permite cantidades fraccionarias ni números negativos.
