# Spec — Consulta de Catálogo y Disponibilidad de Productos (v0.1)

### Responsable: Kevin (Frontend / UX)
### Requerimientos Funcionales asociados: RF-04, RF-05, RF-06

---

## ¿Por qué? (problema)
En la venta presencial en tienda deportiva, el cliente solicita consultar tallas, colores o alternativas de prendas de forma inmediata. Si el vendedor no tiene visibilidad en tiempo real del stock de la tienda y del almacén central, se generan ventas de artículos agotados o demoras que frustran la experiencia del comprador.

## ¿Para qué? (objetivo)
Proveer al vendedor una interfaz de búsqueda ultra rápida y filtros ágiles en mostrador para consultar prendas, calzado y accesorios deportivos, visualizando con certeza la disponibilidad de stock por talla/color en su tienda y en la red de almacenes.

## ¿Hasta dónde? (alcance)
* **Incluido:** Barra de búsqueda multicriterio (código SKU, nombre), selector de filtros (categoría deportiva, género, marca), vista de tarjetas de productos con galería de variantes (tallas/colores) y discriminación de stock local vs almacén central.
* **Excluido:** Creación de nuevos productos, edición de fichas técnicas, cambio de precios y ajustes manuales de inventario (competencia de *Productos y Ofertas*).

## Referencias
* **Contrato:** [specs/api-contracts.md](file:///c:/Users/Mihae/Programacion/Activos/modulo-retail/specs/api-contracts.md) — `GET /api/v1/productos/catalogo`
* **Modelo:** `ProductoCatalogo` (`productoId`, `nombre`, `marca`, `categoria`, `disciplina`, `precioBase`, `variantes`: `[{sku, talla, color, stockTienda, stockAlmacenCentral}]`)

## ¿Qué debe hacer? (comportamiento)

### Backend (Retail / Consumo de Productos)
1. Expone `GET /api/v1/retail/catalogo` reenviando parámetros de filtrado y el `tiendaId` del vendedor autenticado hacia *Productos y Ofertas*.
2. Valida que la solicitud incluya la cabecera `Authorization: Bearer <token>`.
3. Normaliza la respuesta para consolidar el stock disponible local de la tienda actual frente al stock global.
4. Aplica caché temporal en memoria (máximo 60 segundos) para búsquedas frecuentes, garantizando respuesta en menos de 800 ms.

### Frontend
1. Buscador prioritario con foco automático (`autofocus`) y soporte de lectura directa por escáner de código de barras (enter automático).
2. Botones de filtro rápido por disciplina deportiva: *Fútbol, Running, Training, Outdoor, Básquet*.
3. Renderizado de grilla con tarjetas de producto con foto, nombre, marca y precio.
4. Al hacer clic o presionar espacio en un producto, despliega la matriz interactiva de variantes:
   * Selector de tallas (ej. S, M, L, XL o 38 a 44).
   * Semáforo de stock: Verde (stock suficiente en tienda local > 3), Ámbar (últimas 1-3 unidades), Gris (agotado en tienda local pero disponible en almacén central).
5. Botón de acción rápida: *"Agregar al Carrito"* (solo activo si hay stock en tienda local).

## ¿Cómo verificamos? (criterios de aceptación)
- [ ] Búsqueda por SKU exacto devuelve directamente el producto con sus variantes en menos de 800 ms.
- [ ] Búsqueda por texto ("camiseta running") filtra correctamente por coincidencia parcial.
- [ ] Filtrar por categoría deportiva actualiza la grilla sin recargar la página.
- [ ] Si una variante no tiene stock en la tienda local (`stockTienda == 0`), el botón de agregar al carrito queda deshabilitado para venta presencial inmediata y se muestra la etiqueta *"Disponible solo en Almacén Central"*.
- [ ] Si se consulta sin token JWT válido, responde 401 Unauthorized.
- [ ] Si no hay coincidencias en la búsqueda, muestra mensaje amigable: *"No se encontraron productos para los criterios ingresados"*.

## ¿Con qué condiciones? (precondiciones y dependencias)
* El vendedor debe tener una sesión activa con `tiendaId` asignado.
* El microservicio de *Productos y Ofertas* debe exponer el endpoint de catálogo y stock en tiempo real.
* Regla de negocio: El stock mostrado debe actualizarse de forma transparente ante cada venta concretada.

## ¿Qué NO hará? (fuera de alcance)
* No permite editar precios ni características de los productos.
* No realiza transferencias entre tiendas en esta versión.
* No procesa imágenes en el servidor de Retail (las imágenes provienen de URLs provistas por el catálogo central).
