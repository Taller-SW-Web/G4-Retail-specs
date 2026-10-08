# Tareas — F12: Gestión de Discrepancias y Mermas en Tienda

**Fuentes:** `f12-discrepancias.md`, `f12-discrepancias.ui.md`, `specs/generales/api-contracts.md`.  
**Regla SDD (AGENTS.md):** Una tarea a la vez, cada tarea concluye con su test automatizado y commit (`feat: ...`, `fix: ...`, `test: ...`).

---

## Backend (`G4-Retail-backend`)

### [RF-32] Reporte de Incidencias de Inventario
- [ ] **Tarea B1 (RF-32):** Crear entidad JPA `IncidenciaInventario` y tabla `RET_INCIDENCIA_INVENTARIO`.  
  *Test:* `IncidenciaInventarioRepositoryTest.java` (verifica persistencia con estado `EN_CUARENTENA`).
- [ ] **Tarea B2 (RF-32):** Implementar servicio y endpoint `POST /api/v1/retail/inventario/incidencias` con validaciones de motivo y vendedor autenticado.  
  *Test:* `IncidenciaInventarioServiceTest.java` (valida creación exitosa y rechazo ante campos obligatorios vacíos).

### [RF-33] Cuarentena y Bloqueo en POS
- [ ] **Tarea B3 (RF-33):** Implementar lógica de descuento de stock local vendible al registrar incidencia y endpoint `GET /api/v1/retail/inventario/cuarentena`.  
  *Test:* `CuarentenaServiceTest.java` (valida reducción de `stockDisponible` y listado de ítems retenidos).
- [ ] **Tarea B4 (RF-33):** Validación en backend al agregar ítem a carrito para rechazar variantes con SKU en cuarentena activa.  
  *Test:* `CartServiceCuarentenaTest.java` (verifica excepción al intentar añadir SKU bloqueado).

### [RF-34] Acta de Discrepancia y Notificación Externa
- [ ] **Tarea B5 (RF-34):** Crear entidad `ActaDiscrepancia`, generador de correlativo numérico (`ACTA-MERMA-YYYY-XXXX`) y endpoint `POST /api/v1/retail/inventario/actas-merma`.  
  *Test:* `ActaDiscrepanciaServiceTest.java` (verifica generación de acta y transición de estado a `DERIVADO_ALMACEN`).
- [ ] **Tarea B6 (RF-34):** Integrar cliente REST hacia módulo de Productos (`POST /api/v1/inventario/ajuste-discrepancia`) con manejo de fallos y reintentos.  
  *Test:* `ProductosInventarioClientTest.java` (mock de endpoint externo y verificación de payload).

---

## Frontend (`G4-Retail-frontend`)

### [RF-32] Reporte de Incidencias
- [ ] **Tarea F1 (RF-32):** Modal `DiscrepancyModal` para capturar prenda por código de barras/SKU, selector de falla y observaciones.  
  *Test:* `DiscrepancyModal.test.tsx` (verifica renderizado, validación de motivo y envío al endpoint).

### [RF-33] Visualización y Bloqueo en Terminal
- [ ] **Tarea F2 (RF-33):** Deshabilitar variante en catálogo e impedir adición al carrito emitiendo modal de advertencia de cuarentena.  
  *Test:* `CatalogQuarantineBlock.test.tsx` (simula escaneo de SKU en cuarentena y comprueba modal de alerta).
- [ ] **Tarea F3 (RF-33):** Pantalla/Bandeja de artículos en cuarentena de la tienda con detalle de motivo e incidencia.  
  *Test:* `QuarantineList.test.tsx` (verifica listado y badges de estado).

### [RF-34] Generación de Acta y Salida
- [ ] **Tarea F4 (RF-34):** Vista de liquidación de mermas con checkboxes para seleccionar prendas, selector de destino y modal de confirmación.  
  *Test:* `ActaGeneratorView.test.tsx` (verifica selección múltiple y validación de lista vacía).
- [ ] **Tarea F5 (RF-34):** Componente de vista e impresión de acta oficial con correlativo y firmas de supervisor.  
  *Test:* `ActaPrintPreview.test.tsx` (verifica formato de cabecera, tabla de ítems y botón de impresión).
