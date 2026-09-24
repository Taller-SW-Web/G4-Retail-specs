# Spec — RF-05: Visualización de Variantes (Talla y Color) (v0.1)

### Responsable: Kevin (Frontend / UX)
### Requerimiento Funcional: RF-05: Visualización de Variantes (Talla y Color)
### Funcionalidad Padre: F2: Consulta del Catálogo y Disponibilidad de Productos
### Prioridad: Must have (Crítico)

---

## ¿Por qué? (problema)
En artículos deportivos (ropa, zapatillas e indumentaria), un mismo modelo de producto existe en múltiples variantes de tallas (S, M, L, XL o tallas de calzado 38 a 44) y combinaciones de color. Si el vendedor no puede visualizar y seleccionar con claridad la combinación exacta que el cliente desea comprar, se corre el riesgo de agregar una variante equivocada al pedido.

## ¿Para qué? (objetivo)
Permitir al vendedor, al hacer clic o interactuar con un producto del catálogo, desplegar una matriz interactiva y ergonómica de variantes organizada por tallas y colores, mostrando la imagen asociada, el precio y el estado visual de cada opción para facilitar su elección rápida.

## ¿Hasta dónde? (alcance)
* **Incluido:** Vista modal o panel expandible con la ficha técnica del producto, selector interactivo de color (muestras cromáticas o nombres de color), selector de talla en botones táctiles de fácil pulsación, actualización dinámica del SKU seleccionado y botón de acción para confirmar la variante.
* **Excluido:** Búsqueda y filtrado global de catálogo (cubierto en RF-04), lógica de discriminación de stock físico vs almacén central (cubierto en RF-06), y agregado del producto al carrito POS (cubierto en RF-10).

## Referencias
* **Contrato:** [api-contracts.md](./api-contracts.md) — `GET /api/v1/productos/catalogo` (Sección 2)
* **Modelo:** `ProductoVariante` (`sku`, `talla`, `color`, `precioUnitario`, `stockTienda`, `stockAlmacenCentral`)

## ¿Qué debe hacer? (comportamiento)

### Backend (Retail / Formateo de Variantes)
1. Al recibir la respuesta del microservicio de *Productos y Ofertas*, procesa el array de variantes de cada producto.
2. Agrupa las variantes disponibles por atributo clave:
   * Colores disponibles únicos del modelo (ej. `["Negro", "Azul Marino", "Blanco"]`).
   * Tallas disponibles según el color seleccionado (ej. `["S", "M", "L", "XL"]` o numéricas `["39", "40", "41", "42"]`).
3. Mapea cada combinación única a su código SKU oficial (ej. `CAM-RUN-M-AZUL`).
4. Retorna la estructura jerárquica para facilitar el renderizado reactivo en frontend.

### Frontend
1. Al hacer clic sobre una tarjeta de producto en la grilla:
   * Abre un panel flotante o modal de detalle con transición suave sin bloquear la vista general.
2. Muestra cabecera del producto: imagen principal en alta resolución, nombre, marca y precio base.
3. Selector de Color:
   * Despliega botones circulares o etiquetas con el nombre de cada color disponible.
   * Al seleccionar un color, actualiza la galería de imágenes y habilita las tallas asociadas a ese color.
4. Selector de Tallas:
   * Botones de gran tamaño adaptados a pantallas táctiles (optimización para terminales de mostrador).
   * La talla seleccionada se resalta con borde de alto contraste.
   * Si una talla no tiene existencias, se visualiza con estilo atenuado (*disabled*) y línea tachada o aviso contextual.
5. Muestra en tiempo real el SKU exacto correspondiente a la combinación seleccionada.
6. Permite cerrar el modal con la tecla `Escape` o clic fuera del contenedor.

## ¿Cómo verificamos? (criterios de aceptación)
- [ ] Al seleccionar un producto con 4 tallas y 2 colores, el panel despliega correctamente ambas opciones.
- [ ] Cambiar de color "Azul" a "Negro" actualiza el SKU mostrado y las tallas correspondientes.
- [ ] La selección de talla se realiza en un solo toque o clic.
- [ ] La variante elegida muestra su precio unitario actualizado (en caso de prendas con precio diferenciado por talla).
- [ ] El modal es navegable tanto con mouse, pantalla táctil como con teclado (teclas de flechas y Enter).

## ¿Con qué condiciones? (precondiciones y dependencias)
* Cada artículo debe contar con al menos una variante activa en la base de datos de Productos.
* Ergonomía POS: Botones de selección de al menos 44x44 píxeles para usabilidad táctil en mostrador (RNF-05).

## ¿Qué NO hará? (fuera de alcance)
* No creará nuevas tallas ni asociará nuevos colores al catálogo desde la terminal Retail.
* No descargará imágenes pesadas en el servidor de Retail (se consumen por URL externa del CDN).
