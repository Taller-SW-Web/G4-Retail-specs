# UI Spec — F11: Alertas Operativas y Notificaciones en Tienda

**Pantalla:** Popover de Notificaciones y Tablón Operativo  
**Ubicación:** Menú desplegable en `AppHeader`  
**Spec Funcional:** `f11-alertas.md`  
**Design System:** `specs/generales/design-system.md`  

---

## 1. Usuario Objetivo
Vendedor y supervisor de tienda.

## 2. Composición y Layout
- Botón de Campana (`ActionIcon`) con badge numérico en esquina superior derecha.
- Menú desplegable (*Dropdown*) dividido en pestañas: *Alertas de Stock, Pickups de Hoy, Campañas Activas*.
- Tarjetas compactas de notificación con icono de severidad (`Warning`, `Info`, `Success`), timestamp y botón de acción rápida (ej. *"Ver producto"*, *"Ver pedido"*).

## 3. Tono Visual y Mapeo al Design System
- Fondo `bg-white border border-border-default rounded-xl shadow-lg w-80`.
- Items no leídos con fondo sutil `bg-surface-cloud-subtle`.
