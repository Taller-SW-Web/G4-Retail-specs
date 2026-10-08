# Plan de Implementación — F2: Consulta de Catálogo y Disponibilidad

> Documento de regularización y decisiones de arquitectura para el catálogo de productos y escáner.

---

## 1. Decisiones Técnicas Confirmadas
1. **Prioridad del Código de Barras:** El lector óptico USB/Bluetooth emula un teclado HID. El sistema intercepta estas pulsaciones a nivel global en la ventana para procesar el código sin que el cajero tenga que hacer clic previamente en un campo de texto.
2. **Índice Único en Variantes:** La columna `codigo_barras` en la tabla `RET_VARIANTES_PRODUCTO` tiene constraint de unicidad e índice B-tree para responder en < 50ms.
3. **Paginación y Filtros:** El endpoint de productos implementa `Pageable` de Spring con tamaño por defecto de 20 elementos para optimizar la carga inicial.

## 2. Componentes e Integraciones
- **Backend:**
  - `ProductoController`: endpoints `/productos` y `/productos/barcode/{codigo}`.
  - `CatalogoService`: consulta y cruce con inventario local.
- **Frontend:**
  - `useBarcodeScanner`: hook reactivo para captura óptica.
  - `ProductCard`, `ProductDetailModal` en `/pos`.

## 3. Registro de Incidencias y Regularizaciones
- *(Pendiente de registro durante la ejecución del sprint)*.
