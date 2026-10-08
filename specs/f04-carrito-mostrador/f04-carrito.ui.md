# UI Spec — F4: Gestión del Carrito de Compras en Mostrador

**Pantalla:** Panel Lateral de Carrito POS  
**Ubicación:** Panel derecho de `/pos` (`PosLayout`)  
**Spec Funcional:** `f04-carrito.md`  
**Design System:** `specs/generales/design-system.md`  

---

## 1. Usuario Objetivo
Cajero/Vendedor atendiendo frente a la pantalla táctil o con teclado físico en mostrador.

## 2. Objetivo de la Pantalla
Visualizar los artículos escaneados, ajustar cantidades en tiempo real, ver subtotales e impuestos desglosados y avanzar al cobro con un clic o atajo.

## 3. Composición y Layout (`CartPanel`)
- **Cabecera de Carrito:**
  - Contador de ítems (ej. *"Carrito (3 prendas)"*).
  - Botón *"Pausar venta"* (`HeldCarts`) con indicador de carritos pendientes.
  - Botón *"Vaciar"* con confirmación modal.
- **Lista de Líneas de Carrito (`CartLine`):**
  - Miniatura de prenda + nombre en Oswald + talla/color.
  - Precio unitario.
  - Selector de cantidad (`QuantityStepper`) con botones circulares `+` / `-`.
  - Subtotal de la línea en negrita.
  - Botón de eliminar con icono de papelera.
- **Panel de Totales (`TotalsPanel`):**
  - Fila Subtotal (`text-sm text-text-secondary`).
  - Fila Descuento / Cupón (en verde `--color-semantic-success` si aplica).
  - Fila IGV (18%) (`text-sm text-text-secondary`).
  - Fila TOTAL destacado: tipografía Oswald `text-3xl font-bold text-text-primary`.
- **Botón de Acción de Cobro:**
  - Botón *"Cobrar (F5)"* variante `Confirm` (`accent-signal`), ancho completo, altura destacada.

## 4. Ciclo de Estados de la Interfaz

| Estado | Comportamiento Visual |
|---|---|
| **Carrito Vacío** | `EmptyState` centrado: icono de carrito vacío, mensaje *"No hay prendas escaneadas"* e indicación *"Usa el escáner de barras o el catálogo"*. Botón de Cobro deshabilitado. |
| **Con Artículos** | Lista con scroll interno si hay más de 4 prendas; totales recalculados instantáneamente. |
| **Modificando Cantidad** | Actualización reactiva instantánea del subtotal de la línea y del total general sin retraso. |
| **Alcanzado Límite Stock** | Botón `+` se deshabilita y se muestra tooltip flotante: *"Stock máximo disponible en tienda alcanzado"*. |

## 5. Tono Visual y Mapeo al Design System

| Elemento UI | Token / Clase del Design System |
|---|---|
| Panel Contenedor | `bg-white border-l border-border-default flex flex-col h-full p-4` |
| Línea de Producto | `border-b border-border-default py-3 flex items-center justify-between` |
| Stepper Cantidad | `border border-border-default rounded-lg flex items-center px-2 py-1` |
| Total a Pagar | `font-display text-3xl font-bold text-text-primary` (Oswald) |
| Botón Cobrar | `bg-accent-signal text-text-inverse hover:opacity-90 w-full py-4 text-lg font-bold rounded-xl` |
