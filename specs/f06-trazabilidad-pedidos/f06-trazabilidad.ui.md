# UI Spec — F6: Consulta y Seguimiento Histórico de Pedidos

**Pantalla:** Consulta de Pedidos e Historial  
**Ruta:** `/pedidos`  
**Spec Funcional:** `f06-trazabilidad.md`  
**Design System:** `specs/generales/design-system.md`  

---

## 1. Usuario Objetivo
Vendedor o supervisor que atiende consultas presenciales de clientes sobre pedidos anteriores.

## 2. Composición y Layout
- Buscador superior con filtros: Código de pedido, DNI de cliente, Selector de fechas y Selector de Estado.
- Tabla/Lista de resultados con columnas: *Código, Fecha/Hora, Cliente, Total, Medio de Pago, Estado (Badge)*.
- Drawer lateral o Modal con el detalle de la orden y el componente de línea de tiempo (*Timeline*) con nodos coloreados según el estado actual.

## 3. Estados de Interfaz
- **Vacío:** Ilustración y texto invitando a ingresar un código de pedido o DNI.
- **Sin resultados:** Mensaje informativo *"No se encontraron órdenes con los criterios especificados"*.
- **Cargando:** Filas con skeletons pulsantes.

## 4. Tono Visual y Mapeo al Design System
- Badges de estado con variantes del Design System:
  - `ENTREGADO`: fondo verde suave, texto `--color-semantic-success`.
  - `LISTO_PICKUP`: fondo celeste suave, texto `--color-semantic-info`.
  - `ANULADO`: fondo rojo suave, texto `--color-semantic-error`.
