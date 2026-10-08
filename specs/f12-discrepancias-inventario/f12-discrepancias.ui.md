# UI Spec — F12: Gestión de Discrepancias y Prendas no Ubicadas

**Pantalla:** Reporte de Discrepancias y Cuarentena de Stock  
**Ruta:** `/discrepancias` o modal desde detalle de producto  
**Spec Funcional:** `f12-discrepancias.md`  
**Design System:** `specs/generales/design-system.md`  

---

## 1. Usuario Objetivo
Vendedor o supervisor de tienda ante una prenda defectuosa o faltante.

## 2. Composición y Layout
- Formulario de Incidencia:
  - Input de Código de Barras o SKU (con lectura por escáner).
  - Selector de Motivo: *Prenda rota / manchada, Falla de fábrica, No encontrada en perchero, Etiqueta ilegible*.
  - Cantidad afectada y campo de observaciones de texto.
  - Checkbox *"Poner inmediatamente en cuarentena (bloquear en POS)"*.
  - Botón *"Emitir Acta de Discrepancia"* (variante `Danger` si es daño grave o `Secondary`).
- Tabla de prendas actualmente en cuarentena en la tienda.

## 3. Tono Visual y Mapeo al Design System
- Alertas y confirmaciones en tonos de advertencia `--color-semantic-warning`.
