# Tareas — F2: Consulta de Catálogo y Disponibilidad de Productos

**Fuentes:** `f02-catalogo.md` (RF-04, RF-05, RF-06), `f02-catalogo.ui.md`, `specs/generales/api-contracts.md`.  
**Regla SDD (AGENTS.md):** Una tarea a la vez, cada tarea concluye con su test automatizado y commit.

---

## Backend (`G4-Retail-backend`)

### [ ] Tarea B1 (RF-04): Entidades y Repositorio de Productos con Índice de Código de Barras
- **Archivos:** `model/Producto.java`, `model/VarianteProducto.java`, `repository/ProductoRepository.java`.
- **Qué hace:** Mapea el catálogo y tabla de variantes con código de barras indexado único para match en < 50ms.
- **Criterio que verifica:** "Búsqueda por SKU o código de barras exacto devuelve el producto" (RF-04).
- **Test:** `ProductoRepositoryTest.java` — Verifica búsqueda por código de barras e insensible por nombre.

### [ ] Tarea B2 (RF-05, RF-06): Servicio de Variantes y Stock Distribuido por Tienda
- **Archivos:** `service/CatalogoService.java`, `service/impl/CatalogoServiceImpl.java`, `dto/ProductoDetalleResponse.java`.
- **Qué hace:** Agrupa variantes por color/talla y calcula niveles de stock (`stockTienda` vs `stockAlmacenCentral`) según el `tiendaId` en sesión.
- **Criterios que verifica:** "Mapeo de combinaciones talla/color" (RF-05) y "Clasificación de estados de stock semafórico" (RF-06).
- **Test:** `CatalogoServiceTest.java` — Verifica discriminación de stock local vs almacén central y lanzamiento de 404 ante producto inexistente.

### [ ] Tarea B3 (RF-04, RF-06): Controlador REST de Catálogo y Paginación
- **Archivos:** `controller/ProductoController.java`.
- **Qué hace:** Expone `GET /api/v1/productos` (con filtros `q`, `categoria`, `disciplina`) y `GET /api/v1/productos/barcode/{codigo}`.
- **Criterios que verifica:** Respuesta 200 con listado paginado en < 800 ms y 404 ante código no registrado (RF-04).
- **Test:** `ProductoControllerTest.java` (MockMvc) — Comprueba contratos HTTP 200 y 404.

---

## Frontend (`G4-Retail-frontend`)

### [ ] Tarea F1 (RF-04): Tipos y Cliente API de Catálogo
- **Archivos:** `types/producto.ts`, `api/productoApi.ts`.
- **Qué hace:** Declara tipos `Producto`, `VarianteProducto` y funciones `obtenerProductos()`, `buscarPorCodigoBarras()`.
- **Criterio que verifica:** Conexión con contrato de backend y mapeo de datos JSON.
- **Test:** `productoApi.test.ts` — Prueba unitaria con respuesta mock.

### [ ] Tarea F2 (RF-04): Hook Escáner de Código de Barras (`useBarcodeScanner`)
- **Archivos:** `hooks/useBarcodeScanner.ts`.
- **Qué hace:** Escucha global de eventos de teclado capturando ráfagas de caracteres en menos de 50ms terminadas en `Enter`.
- **Criterio que verifica:** "Detección nativa de escáner de código de barras" (RF-04).
- **Test:** `useBarcodeScanner.test.ts` — Simula ráfaga de teclas y comprueba disparo del callback de escaneo.

### [ ] Tarea F3 (RF-04): Componentes `SearchBar` y Catálogo con Filtros Rápidos
- **Archivos:** `components/molecules/SearchBar.tsx`, `components/organisms/CatalogFilters.tsx`.
- **Qué hace:** Barra de búsqueda con debouncing de 300ms y chips de disciplinas deportivas.
- **Criterios que verifica:** "Búsqueda por texto parcial" y "Filtro por disciplina sin recargar la página" (RF-04).
- **Test:** `SearchBar.test.tsx` — Valida emisión de evento con debouncing.

### [ ] Tarea F4 (RF-05, RF-06): Componentes `ProductCard` y `ProductDetailModal` con Semáforo de Stock
- **Archivos:** `components/organisms/ProductCard.tsx`, `components/organisms/ProductDetailModal.tsx`, `components/molecules/StockBadge.tsx`.
- **Qué hace:** Renderiza la ficha del artículo, matriz de selección de talla y color (botones >= 44px) y badges semafóricos de stock en tienda.
- **Criterios que verifica:** "Selección de talla en un solo toque" (RF-05) y "Variante con 0 en tienda bloquea venta física inmediata" (RF-06).
- **Test:** `ProductDetailModal.test.tsx` — Valida actualización de SKU al cambiar color/talla y bloqueo de botón ante stock local agotado.
