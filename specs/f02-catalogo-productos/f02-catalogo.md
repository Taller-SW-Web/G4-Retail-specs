# Spec — F2: Consulta de Catálogo y Disponibilidad de Productos (v1.0)

### Responsable: Cristhian (Backend Lead) & Kevin (Frontend Lead)
### Requerimientos Funcionales Incluidos: RF-04, RF-05, RF-06
### Prioridad: Must have (Crítico para Hito 3)

---

## 1. ¿Por qué? (Problema de Negocio)
En la atención física en tienda deportiva, los clientes solicitan productos de forma verbal muy diversa (por nombre genérico, marca, deporte) o bien portan artículos físicos con etiquetas de código de barras. Si la búsqueda es lenta, no soporta lector óptico de códigos de barras, no despliega con claridad las matrices de tallas y colores, o no distingue el stock físico inmediato de la tienda frente al almacén central:
1. Se generan colas y pérdidas de venta en mostrador.
2. Se corre el riesgo de vender prendas en la talla o color equivocado.
3. Se pueden vender artículos sin existencias físicas en la tienda, provocando cancelaciones y reclamos.

---

## 2. ¿Para qué? (Objetivo)
Permitir al personal de mostrador encontrar instantáneamente cualquier artículo deportivo en catálogo mediante texto predictivo, lectura automática de código SKU / barras (EAN-13 / Code128) mediante lector óptico HID, desplegar la matriz ergonómica de variantes (tallas y colores) y consultar en tiempo real el stock distribuido diferenciando existencias físicas en la tienda local (`stockTienda`) frente al centro de distribución (`stockAlmacenCentral`).

---

## 3. ¿Hasta dónde? (Alcance)
* **Incluido:**
  * Búsqueda por código de barras (`GET /api/v1/productos/barcode/{codigo}`).
  * Búsqueda multicriterio con filtros de texto, categoría, marca y disciplina (`GET /api/v1/productos`).
  * Modal/panel expandible de variantes de producto con botones táctiles de talla y color (RNF-05).
  * Semáforo de stock distribuido (verde: disponible, ámbar: últimas unidades, azul: almacén central, rojo: agotado).
  * Prevención de venta presencial inmediata si `stockTienda == 0`.
* **Excluido:**
  * Creación o edición de artículos y precios base (responsabilidad de *Productos y Ofertas* G6).
  * Descuento transaccional de unidades al pagar (responsabilidad de F5 / RF-14).

---

## 4. Referencias y Contratos
* **Contrato de API:** [`specs/generales/api-contracts.md`](../generales/api-contracts.md) → `GET /api/v1/productos`, `GET /api/v1/productos/barcode/{codigo}`
* **Design System:** [`specs/generales/design-system.md`](../generales/design-system.md)
* **Modelo de Base de Datos:** `RET_CATALOGO_CACHE`, `RET_VARIANTES_PRODUCTO`, `RET_STOCK_TIENDA`

---

## 5. Requerimientos Funcionales Detallados

### <a id="rf-04"></a>RF-04: Búsqueda Multicriterio de Artículos Deportivos
* **Backend:**
  1. Expone `GET /api/v1/productos` recibiendo query params: `q`, `categoria`, `disciplina`, `marca`, `tiendaId`, `page`, `size`.
  2. Expone `GET /api/v1/productos/barcode/{codigo}` con match exacto indexado por código de barras.
  3. Aplica debouncing y caché en memoria para garantizar respuesta en menos de 800 ms (cumplimiento RNF-01).
  4. Retorna resultados paginados en formato JSON normalizado.
* **Frontend:**
  1. Barra de búsqueda central en mostrador con foco automático (`autofocus`).
  2. Detección nativa de escáner de código de barras: captura ráfaga de teclas finalizada con `Enter` (\n) y agrega el producto al carrito de inmediato.
  3. Filtros rápidos por botones píldora (*chips*): *Todos, Fútbol, Running, Training, Outdoor, Básquet*.
  4. Búsqueda por texto libre con *debouncing* de 300 ms.
  5. Cuadrícula fluida de tarjetas de producto mostrando foto, nombre, marca y precio en Soles (`S/ 199.90`).
* **Criterios de Aceptación (RF-04):**
  - [ ] Búsqueda por SKU o código de barras exacto escaneado devuelve el producto en menos de 800 ms.
  - [ ] Búsqueda por texto parcial lista los artículos coincidentes en nombre o descripción.
  - [ ] Filtro por disciplina filtra reactivamente la grilla sin recargar la página.
  - [ ] Búsqueda sin coincidencias muestra `EmptyState` amigable sin romper la aplicación.

---

### <a id="rf-05"></a>RF-05: Visualización de Variantes (Talla y Color)
* **Backend:**
  1. Agrupa las variantes disponibles del producto:
     * Colores únicos del modelo (ej. `["Negro", "Azul Marino", "Blanco"]`).
     * Tallas disponibles según el color seleccionado (ej. `["S", "M", "L", "XL"]` o numéricas `["39", "40", "41", "42"]`).
  2. Mapea cada combinación única a su código SKU oficial (ej. `CAM-RUN-M-AZUL`) y su código de barras.
* **Frontend:**
  1. Panel modal o expandible (`ProductDetailModal`) al hacer clic en una tarjeta de producto.
  2. Selector de color con muestras cromáticas o etiquetas. Al cambiar de color se actualizan las fotos y las tallas disponibles.
  3. Selector de tallas con botones táctiles de al menos 44x44 px (ergonomía POS / RNF-05).
  4. Resalta la opción seleccionada con borde de alto contraste. Variantes sin existencia se visualizan atenuadas (*disabled*).
  5. Permite cerrar el modal con `Escape` o clic fuera del contenedor.
* **Criterios de Aceptación (RF-05):**
  - [ ] Producto con múltiples tallas y colores despliega correctamente ambas matrices.
  - [ ] Cambiar de color actualiza el SKU mostrado y las tallas correspondientes.
  - [ ] La selección de talla se realiza en un solo toque o clic.
  - [ ] El modal es navegable con mouse, pantalla táctil y teclado.

---

### <a id="rf-06"></a>RF-06: Consulta de Stock Distribuido en Tiempo Real
* **Backend:**
  1. Extrae el `tiendaId` del token del vendedor autenticado en sesión.
  2. Cruza el inventario de la variante: `stockTienda` (unidades físicas locales) y `stockAlmacenCentral`.
  3. Clasifica el estado operativo:
     * `stockTienda > 3` ➔ `DISPONIBLE` (verde).
     * `stockTienda >= 1` y `stockTienda <= 3` ➔ `ULTIMAS_UNIDADES` (ámbar).
     * `stockTienda == 0` y `stockAlmacenCentral > 0` ➔ `SOLO_ALMACEN_CENTRAL` (azul).
     * Ambos en `0` ➔ `AGOTADO_TOTAL` (rojo).
* **Frontend:**
  1. En la ficha y matriz de variantes, muestra badges semafóricos claros:
     * Badge verde: *"Stock en tienda (X unidades)"*.
     * Badge ámbar: *"¡Últimas X unidades en tienda!"*.
     * Badge azul: *"Agotado en tienda — Disponible en Almacén Central"*.
     * Badge rojo: *"Agotado en toda la cadena"*.
  2. Si `stockTienda > 0`: habilita botón de venta inmediata.
  3. Si `stockTienda == 0`: bloquea la venta presencial inmediata en mostrador.
* **Criterios de Aceptación (RF-06):**
  - [ ] Variante con existencias locales muestra badge verde y permite venta presencial.
  - [ ] Variante con stock crítico (1-3) muestra advertencia ámbar.
  - [ ] Variante con 0 en tienda y stock central previene agregar como venta física inmediata de mostrador.
  - [ ] Variante con stock 0 total inhabilita cualquier botón de compra.

---

## 6. Precondiciones y Dependencias
* Vendedor autenticado con tienda asignada en sesión.
* Regla RN-02: Retail no modifica stock unilateralmente; consulta existencias en tiempo real.
