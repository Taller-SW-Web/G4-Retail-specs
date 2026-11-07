# UI Spec — F6: Consulta y Seguimiento Histórico de Pedidos

**Pantalla:** Consulta de Pedidos e Historial  
**Ruta:** `/pedidos`  
**Spec Funcional:** `f06-trazabilidad.md`  
**Design System:** `specs/generales/design-system.md`  

---

## 1. Usuario Objetivo
Vendedor o supervisor que atiende consultas presenciales de clientes sobre pedidos anteriores.

## 2. Composición y Layout
- **Hito 4 / Semana 11:** buscador por código de pedido y acceso al detalle y línea de tiempo.
- **Siguiente hito (RF-16-DOC):** búsqueda histórica por DNI/RUC y tabla de pedidos, pendiente del acceso acordado con G5 bajo A10. No presentar esta búsqueda como disponible en el hito actual. Ver [alcance funcional](f06-trazabilidad.md#31-pendiente-para-la-planificación-del-siguiente-hito--rf-16-doc).
- Tabla/Lista de resultados con columnas: *Código, Fecha/Hora, Cliente, Total, Medio de Pago, Estado (Badge)*.
- Drawer lateral o Modal con el detalle de la orden y el componente de línea de tiempo (*Timeline*) con nodos coloreados según el estado actual.

## 3. Estados de Interfaz
- **Vacío (hito actual):** Ilustración y texto invitando a ingresar un código de pedido.
- **Sin resultados:** Mensaje informativo *"No se encontraron órdenes con los criterios especificados"*.
- **Cargando:** Filas con skeletons pulsantes.

## 4. Tono Visual y Mapeo al Design System
- Badges de estado con variantes del Design System:
  - `ENTREGADO`: fondo verde suave, texto `--color-semantic-success`.
  - `LISTO_PICKUP`: fondo celeste suave, texto `--color-semantic-info`.
  - `ANULADO`: fondo rojo suave, texto `--color-semantic-error`.
