# Spec — RF-04: Búsqueda Multicriterio de Artículos Deportivos (v0.1)

### Responsable: Kevin (Frontend / UX)
### Requerimiento Funcional: RF-04: Búsqueda Multicriterio de Artículos Deportivos
### Funcionalidad Padre: F2: Consulta del Catálogo y Disponibilidad de Productos
### Prioridad: Must have (Crítico)

---

## ¿Por qué? (problema)
En la atención física en tienda, el cliente solicita productos de forma verbal muy diversa (por nombre genérico, marca o deporte) o trae consigo una prenda física con código de barras. Si el vendedor tiene que navegar manualmente por menús lentos o no cuenta con soporte para lector de código de barras, se generan largas colas y pérdida de ventas por demoras en mostrador.

## ¿Para qué? (objetivo)
Permitir al vendedor encontrar instantáneamente cualquier artículo deportivo en catálogo mediante texto predictivo, lectura automática de código SKU / barras mediante lector óptico y filtrado directo por disciplina deportiva (fútbol, running, training, etc.), categoría, género y marca.

## ¿Hasta dónde? (alcance)
* **Incluido:** Barra de búsqueda central en mostrador con foco automático (`autofocus`), detección de evento `Enter` para escáneres de código de barras, filtros rápidos en botones píldora (*chips*) por disciplina deportiva y filtros desplegables por marca/género/categoría.
* **Excluido:** Visualización detallada de la matriz de tallas y colores (cubierto en RF-05), consulta de stock distribuido entre sedes (cubierto en RF-06), y administración de fichas de catálogo de productos (competencia exclusiva del microservicio de *Productos y Ofertas*).

## Referencias
* **Contrato:** [api-contracts.md](./api-contracts.md) — `GET /api/v1/productos/catalogo`
* **Modelo:** `BusquedaCatalogoQuery` (`query`, `categoria`, `disciplina`, `marca`, `talla`, `tiendaId`), `ResultadoCatalogoItem` (`productoId`, `nombre`, `marca`, `categoria`, `disciplina`, `precioBase`)

## ¿Qué debe hacer? (comportamiento)

### Backend (Retail / Pasarela hacia Productos)
1. Expone `GET /api/v1/retail/catalogo/buscar`:
   * Recibe parámetros en query string: `query`, `categoria`, `disciplina`, `marca`, `tiendaId`.
   * Valida la presencia de token Bearer en la cabecera.
2. Reenvía la consulta al microservicio de *Productos y Ofertas* (`GET /api/v1/productos/catalogo`).
3. Aplica debounce y caché en memoria (máximo 60 segundos) para búsquedas frecuentes, garantizando respuesta en menos de 800 ms (cumplimiento RNF-01).
4. Retorna la lista paginada o resumida de artículos coincidentes en formato JSON normalizado.

### Frontend
1. Mantiene el cursor en la caja de búsqueda mediante foco automático (`autofocus`) al ingresar a la pantalla principal.
2. Soporte nativo de lector de código de barras:
   * Al escanear una etiqueta física, el escáner emite la cadena del SKU seguida del carácter `Enter` (\n).
   * La interfaz captura el evento y ejecuta la búsqueda inmediata sin requerir clic del vendedor.
3. Barra de filtros rápidos por disciplina deportiva:
   * Botones destacados: *Todos*, *Fútbol*, *Running*, *Training*, *Outdoor*, *Básquet*.
   * Al seleccionar una disciplina, filtra reactivamente la grilla sin recargar la página.
4. Búsqueda por texto libre con *debouncing* de 300 ms para no saturar la red con cada pulsación.
5. Renderiza los resultados en una cuadrícula fluida de tarjetas de producto mostrando: foto referencial, nombre comercial, marca, disciplina y precio de lista.
6. Si la búsqueda no arroja resultados, muestra estado vacío amigable: *"No se encontraron productos con los criterios ingresados. Intente con otro término o retire los filtros"*.

## ¿Cómo verificamos? (criterios de aceptación)
- [ ] Búsqueda por SKU exacto escaneado devuelve el producto de forma inmediata en menos de 800 ms.
- [ ] Búsqueda por texto parcial (ej. "running") lista únicamente los productos que contienen dicha palabra en su nombre o descripción.
- [ ] Clic en el filtro de disciplina "Fútbol" muestra exclusivamente artículos de fútbol sin refrescar la página.
- [ ] Búsqueda de un término inexistente muestra el mensaje de catálogo vacío sin producir errores en consola.
- [ ] Limpiar el texto de búsqueda restablece el catálogo a la vista inicial completa.

## ¿Con qué condiciones? (precondiciones y dependencias)
* El vendedor debe poseer una sesión activa autenticada.
* El microservicio de *Productos y Ofertas* debe responder al endpoint de catálogo.
* Rendimiento exigido: Tiempo de respuesta menor a 800 ms bajo condiciones normales (RNF-01).

## ¿Qué NO hará? (fuera de alcance)
* No creará nuevos artículos deportivos ni editará precios desde Retail.
* No realizará búsquedas fonéticas complejas fuera del catálogo provisto por Productos y Ofertas.
