# UI Spec — F10: Modo Contingencia y Sincronización Offline

**Pantalla:** Banner de Conectividad e Indicador de Sincronización  
**Ubicación:** Barra superior en `/pos` (`AppHeader`)  
**Spec Funcional:** `f10-contingencia-offline.md`  
**Design System:** `specs/generales/design-system.md`  

---

## 1. Usuario Objetivo
Cajero operando en mostrador durante una interrupción de internet.

## 2. Composición y Layout
- **Banner de Contingencia:** Barra horizontal superior en color amarillo `--color-semantic-warning` (`#FFF9DB` con borde `#F08C00`):
  - Icono de WiFi desconectado.
  - Texto: *"Modo sin conexión activo — Operando con base de datos local. Pagos limitados a efectivo"*.
- **Contador de Ventas Pendientes:** Badge flotante en cabecera: *"3 ventas por sincronizar"*.
- **Modal de Estado de Red:** Muestra progreso de sincronización en barra de porcentaje cuando la red se restablece.

## 3. Restricciones de UI
- En modo offline, el botón de pago con *Tarjeta* se deshabilita visualmente con un tooltip explicativo.
