# Tareas — F6: Consulta y Seguimiento Histórico de Pedidos

**Fuentes:** `f06-trazabilidad.md` (RF-16, RF-17), `f06-trazabilidad.ui.md`, `specs/generales/api-contracts.md`.  
**Regla SDD (AGENTS.md):** Una tarea a la vez, cada tarea concluye con su test automatizado y commit.

**Corte de alcance (06/11/2026):** en el Hito 4 se implementan consulta por código y trazabilidad. La búsqueda histórica por DNI/RUC queda pendiente para el siguiente hito como **RF-16-DOC**, restringida por A10. Ver [alcance y checklist de coordinación](f06-trazabilidad.md#31-pendiente-para-la-planificación-del-siguiente-hito--rf-16-doc).

---

## Backend (`G4-Retail-backend`)

### [ ] Tarea B1 (RF-16): Consulta por Código de Pedido
- **Archivos:** adaptador HTTP de Ventas y `dto/OrdenResumenDto.java`.
- **Qué hace:** Consulta G5 con `GET /api/v1/pedidos/{pedidoId}` y `ventas:pedidos:consultar`, sin invocar el listado general restringido por A10.
- **Criterio que verifica:** "Búsqueda por código existente retorna 200 OK" y "Código erróneo responde 404" (RF-16).
- **Test:** prueba del adaptador HTTP con G5 simulado — Verifica ruta por código, autenticación y traducción de pedido inexistente.

### [ ] Tarea B2 (RF-17): Servicio de Trazabilidad y Compilación de Historial
- **Archivos:** `service/TrazabilidadService.java`, `dto/DetalleOrdenTrazabilidadResponse.java`.
- **Qué hace:** Compila los eventos históricos de la orden en orden cronológico ascendente con timestamps normalizados.
- **Criterio que verifica:** "Línea de tiempo refleja cada cambio de estado con fecha y hora" (RF-17).
- **Test:** `TrazabilidadServiceTest.java` — Valida secuencia de estados y mapeo de prendas.

### [ ] Tarea B3 (RF-16, RF-17): Controlador REST de Pedidos
- **Archivos:** `controller/PedidoConsultaController.java`.
- **Qué hace:** Expone `GET /api/v1/retail/pedidos?codigoPedido=` y `GET /api/v1/retail/pedidos/{pedidoId}` según §5.6 del contrato. El filtro por documento queda para B4.
- **Test:** `PedidoConsultaControllerTest.java` (MockMvc) — Comprueba respuestas 200 y 404.

---

## Frontend (`G4-Retail-frontend`)

### [ ] Tarea F1 (RF-16): Tipos y Cliente API de Pedidos
- **Archivos:** `types/trazabilidad.ts`, `api/pedidoApi.ts`.
- **Qué hace:** Declara tipos de historial y métodos de consulta por código. La consulta por documento queda para F4.
- **Test:** `pedidoApi.test.ts` — Comprueba llamada con filtros y serialización.

### [ ] Tarea F2 (RF-16): Pantalla de Búsqueda y Tabla Histórica
- **Archivos:** `pages/OrderHistoryPage.tsx`, `components/organisms/OrderHistoryTable.tsx`.
- **Qué hace:** Buscador por código y acceso al detalle. El buscador por DNI/RUC y su tabla histórica quedan para F4.
- **Criterio que verifica:** "Búsqueda por código existente carga la orden" y "Código erróneo muestra EmptyState" (RF-16).
- **Test:** `OrderHistoryPage.test.tsx` — Valida renderizado de resultados y estado vacío.

### [ ] Tarea F3 (RF-17): Componente de Línea de Tiempo (`OrderTimeline`)
- **Archivos:** `components/organisms/OrderTimeline.tsx`, `components/organisms/OrderDetailDrawer.tsx`.
- **Qué hace:** Stepper interactivo de hitos completados y prendas con badges semánticos de estado.
- **Criterio que verifica:** "Badge y nodos adoptan color según estado" (RF-17).
- **Test:** `OrderTimeline.test.tsx` — Valida nodos completados con check verde y nodo en curso resaltado.

---

## Siguiente hito — RF-16-DOC (pendiente; no implementado)

### [ ] Tarea B4 (RF-16-DOC): Búsqueda Histórica por DNI/RUC Autorizada por G5
- **Bloqueante:** acuerdo de acceso con G5 bajo A10 y actualización de §5.6 del contrato. Coordinar con G7 solo si se requiere un permiso nuevo.
- **Qué hace:** Implementa el adaptador y el filtro `documentoCliente` conforme a la ruta, datos visibles, límites y autorización acordados; no reutiliza credenciales de `ADMIN_VENTAS`.
- **Criterio que verifica:** búsqueda por DNI/RUC con múltiples pedidos devuelve la lista cronológica dentro del acceso acordado.
- **Test previo a la implementación:** pruebas con G5 simulado para resultados cronológicos, sin resultados, autorización denegada y límites acordados.

### [ ] Tarea F4 (RF-16-DOC): Buscador por Documento y Tabla Histórica
- **Bloqueante:** contrato aprobado y tarea B4.
- **Qué hace:** Habilita el selector por DNI/RUC y la tabla histórica con acceso al detalle, conforme al contrato aprobado.
- **Test previo a la implementación:** búsqueda por documento, orden de resultados y estados vacío y de acceso denegado.
