# Tareas — F6: Consulta y Seguimiento Histórico de Pedidos

**Fuentes:** `f06-trazabilidad.md` (RF-16, RF-17), `f06-trazabilidad.ui.md`, `specs/generales/api-contracts.md`.  
**Regla SDD (AGENTS.md):** Una tarea a la vez, cada tarea concluye con su test automatizado y commit.

---

## Backend (`G4-Retail-backend`)

### [ ] Tarea B1 (RF-16): Consultas Dinámicas y Paginación de Pedidos
- **Archivos:** `repository/OrdenRepository.java`, `dto/OrdenResumenDto.java`.
- **Qué hace:** Repositorio con consultas filtradas por `codigoPedido` o `documentoCliente` ordenadas cronológicamente.
- **Criterio que verifica:** "Búsqueda por código o DNI retorna lista cronológica" (RF-16).
- **Test:** `OrdenRepositoryQueryTest.java` — Valida ordenamiento descendente por fecha y filtros.

### [ ] Tarea B2 (RF-17): Servicio de Trazabilidad y Compilación de Historial
- **Archivos:** `service/TrazabilidadService.java`, `dto/DetalleOrdenTrazabilidadResponse.java`.
- **Qué hace:** Compila los eventos históricos de la orden en orden cronológico ascendente con timestamps normalizados.
- **Criterio que verifica:** "Línea de tiempo refleja cada cambio de estado con fecha y hora" (RF-17).
- **Test:** `TrazabilidadServiceTest.java` — Valida secuencia de estados y mapeo de prendas.

### [ ] Tarea B3 (RF-16, RF-17): Controlador REST de Pedidos
- **Archivos:** `controller/PedidoConsultaController.java`.
- **Qué hace:** Expone `GET /api/v1/pedidos` y `GET /api/v1/pedidos/{id}`.
- **Test:** `PedidoConsultaControllerTest.java` (MockMvc) — Comprueba respuestas 200 y 404.

---

## Frontend (`G4-Retail-frontend`)

### [ ] Tarea F1 (RF-16): Tipos y Cliente API de Pedidos
- **Archivos:** `types/trazabilidad.ts`, `api/pedidoApi.ts`.
- **Qué hace:** Declara tipos de historial y métodos de consulta por código o DNI.
- **Test:** `pedidoApi.test.ts` — Comprueba llamada con filtros y serialización.

### [ ] Tarea F2 (RF-16): Pantalla de Búsqueda y Tabla Histórica
- **Archivos:** `pages/OrderHistoryPage.tsx`, `components/organisms/OrderHistoryTable.tsx`.
- **Qué hace:** Buscador dual (código / DNI) y tabla de compras con botón *"Ver Detalle"*.
- **Criterio que verifica:** "Búsqueda por DNI lista órdenes ordenadas" (RF-16).
- **Test:** `OrderHistoryPage.test.tsx` — Valida renderizado de resultados y estado vacío.

### [ ] Tarea F3 (RF-17): Componente de Línea de Tiempo (`OrderTimeline`)
- **Archivos:** `components/organisms/OrderTimeline.tsx`, `components/organisms/OrderDetailDrawer.tsx`.
- **Qué hace:** Stepper interactivo de hitos completados y prendas con badges semánticos de estado.
- **Criterio que verifica:** "Badge y nodos adoptan color según estado" (RF-17).
- **Test:** `OrderTimeline.test.tsx` — Valida nodos completados con check verde y nodo en curso resaltado.
