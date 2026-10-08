# UI Spec — F2: Catálogo y Lector de Código de Barras

**Pantalla:** Terminal POS — Explorador de Catálogo y Búsqueda  
**Ubicación:** Panel izquierdo de `/pos` (`PosLayout`)  
**Spec Funcional:** `f02-catalogo.md`  
**Design System:** `specs/generales/design-system.md`  

---

## 1. Usuario Objetivo
Vendedor/Cajero en mostrador. Necesita máxima fluidez: escanear artículos de forma continua sin tocar el ratón, o buscar rápidamente una prenda si la etiqueta está rota.

## 2. Objetivo de la Pantalla
Permitir la búsqueda visual y por escáner de productos deportivos, selección de tallas/colores y verificación de inventario local.

## 3. Composición y Layout
- **Barra de Herramientas Superior:**
  - `SearchBar`: Campo de búsqueda de texto/SKU con atajo visual `[F2]`.
  - Indicador de estado del escáner: icono de lector con badge *"Escáner activo"*.
  - Chips de categorías rápidas (`SegmentedControl`): *Todos, Calzado, Camisetas, Balones, Accesorios*.
- **Grilla de Artículos (`ProductCard`):**
  - Imagen en formato ratio 1:1, optimizada con fallback neutro si falla la carga.
  - Título del producto en Oswald Bold (`text-base`).
  - Precio formateado en Soles (`S/ 199.90`) y precio anterior tachado si tiene oferta activa.
  - Badges: `StockBadge` (verde si stock > 5, amarillo si stock <= 5, rojo si agotado).
  - Selector rápido de tallas (`Chip` de tallas `S · M · L · XL` o calzado `40 · 41 · 42`).
- **Modal de Detalle (`ProductDetailModal`):**
  - Vista ampliada para seleccionar color, talla y cantidad cuando el producto tiene múltiples variantes.

## 4. Ciclo de Estados de la Interfaz

| Estado | Comportamiento Visual |
|---|---|
| **Catálogo Inicial** | Grilla de 4 columnas en desktop mostrando los productos más vendidos de la tienda. |
| **Búsqueda en Curso** | Skeletons pulsantes (`rounded-xl bg-surface-cloud-subtle`) en lugar de las tarjetas. |
| **Sin Coincidencias** | `EmptyState` centrado: icono de lupa vacía y mensaje *"No se encontraron productos que coincidan con la búsqueda"*. |
| **Lectura de Barras Exitosa** | Efecto de destello verde en el panel de carrito y sonido sutil / notificación toast flotante: *"Producto agregado: Zapatillas Running..."*. |
| **Código no Registrado** | Toast de advertencia con sonido de alerta: *"Código de barras no reconocido. Verifique la etiqueta"*. |

## 5. Tono Visual y Mapeo al Design System

| Elemento UI | Token / Clase del Design System |
|---|---|
| Tarjeta de Producto | `bg-white border border-border-default rounded-xl p-4 shadow-sm hover:shadow-md transition` |
| Badge Stock Disponible | `bg-emerald-50 text-emerald-700 text-xs font-semibold px-2 py-0.5 rounded-full` |
| Badge Stock Crítico | `bg-amber-50 text-amber-700 text-xs font-semibold px-2 py-0.5 rounded-full` |
| Badge Oferta (-20%) | `bg-accent-volt text-text-primary text-xs font-bold px-2 py-0.5 rounded-full` |
| Atajo visual F2 | `font-mono text-xs text-text-secondary bg-surface-cloud px-1.5 py-0.5 rounded` |
