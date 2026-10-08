# UI Spec — F9: Solicitud de Cambio de Prenda y Emisión de Vales

**Pantalla:** Gestión de Cambios y Vales de Devolución  
**Ruta:** `/devoluciones`  
**Spec Funcional:** `f09-devoluciones.md`  
**Design System:** `specs/generales/design-system.md`  

---

## 1. Usuario Objetivo
Cajero o supervisor de tienda atendiendo solicitudes de cambio de producto.

## 2. Composición y Layout
- Buscador por número de Boleta o Factura original (ej. `B001-0004521`).
- Desglose de prendas adquiridas en la boleta con casillas de selección (*Checkboxes*).
- Checklist de inspección física:
  - *Etiquetas originales presentes*.
  - *Prenda sin manchas ni signos de uso*.
  - *Empaque / caja original*.
- Selector de Destino: Reingreso a inventario / Enviar a revisión técnica.
- Botón *"Generar Vale de Compra"* y vista previa del vale imprimible con código de barras.

## 3. Estados de Interfaz
- **Plazo Vencido:** Advertencia en rojo si la fecha de compra supera los 30 días.
- **Aprobado:** Generación de vale con formato imprimible.
