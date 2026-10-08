# UI Spec — F8: Apertura y Cierre de Turno de Caja con Arqueo Ciego

**Pantalla:** Apertura de Turno y Arqueo de Cierre (Corte Z)  
**Ruta:** Modal `/apertura-caja` y página `/cierre-caja`  
**Spec Funcional:** `f08-caja-turnos.md`  
**Design System:** `specs/generales/design-system.md`  

---

## 1. Usuario Objetivo
Cajero de terminal al iniciar y al finalizar su turno laboral frente a la gaveta de dinero.

## 2. Composición y Layout

### Modal de Apertura (`ShiftOpenModal`)
- Selector de terminal o caja asignada (ej. `CAJA-01`).
- Input de Fondo Fijo Inicial con teclado numérico virtual.
- Botón *"Abrir Turno de Caja"* (variante `Confirm`).

### Pantalla de Arqueo Ciego (`CashClosePage` / `ZReport`)
- Título: *"Cierre de Turno y Arqueo de Caja (Corte Z)"*.
- Tabla de desglose de conteo físico por denominaciones de billetes (`S/ 200`, `S/ 100`, `S/ 50`, `S/ 20`, `S/ 10`) y monedas (`S/ 5`, `S/ 2`, `S/ 1`, `S/ 0.50`).
- Total Físico Declarado calculado automáticamente según los billetes contados.
- **Regla estricta de UI:** En ningún momento antes del submit se muestra el monto teórico recaudado por ventas.
- Botón *"Confirmar Arqueo y Cerrar Turno"*.
- Tras enviar: se revela el reporte comparativo con Monto Esperado, Monto Declarado y Diferencia (Sobrante/Faltante en rojo o verde).

## 3. Tono Visual y Mapeo al Design System
- Input de denominaciones con diseño tabular limpio `bg-white border border-border-default rounded-xl`.
- Reporte final estilo ticket imprimible con resumen financiero.
