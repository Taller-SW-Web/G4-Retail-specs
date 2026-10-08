# Tareas — F10: Modo Contingencia y Sincronización Offline

**Fuentes:** `f10-contingencia-offline.md` (RF-26, RF-27, RF-28), `f10-contingencia-offline.ui.md`, `specs/generales/api-contracts.md`.  
**Regla SDD (AGENTS.md):** Una tarea a la vez, cada tarea concluye con su test automatizado y commit.

---

## Backend (`G4-Retail-backend`)

### [ ] Tarea B1 (RF-26): Endpoint de Heartbeat `/health`
- **Archivos:** `controller/HealthController.java`.
- **Qué hace:** Endpoint liviano que responde 200 OK para monitoreo de red por parte del POS.
- **Test:** `HealthControllerTest.java` — Verifica respuesta rápida con timestamp.

### [ ] Tarea B2 (RF-28): Endpoint de Sincronización por Lote e Idempotencia
- **Archivos:** `model/ContingenciaLog.java`, `service/SincronizacionOfflineService.java`, `controller/ContingenciaController.java`.
- **Qué hace:** Procesa lotes de ventas offline, valida unicidad por `venta_local_uuid`, decrementa stock central y asigna serie oficial.
- **Criterio que verifica:** "Reintentos de red no duplican órdenes (idempotencia por UUID)" (RF-28).
- **Test:** `SincronizacionBatchTest.java` — Comprueba que enviar dos veces la misma venta no duplique registros.

---

## Frontend (`G4-Retail-frontend`)

### [ ] Tarea F1 (RF-26): Hook `useNetworkStatus` y Banner de Contingencia
- **Archivos:** `hooks/useNetworkStatus.ts`, `components/molecules/OfflineBanner.tsx`.
- **Qué hace:** Detecta eventos `offline`/`online`, sondea `/health` y conmuta la UI a modo restringido (solo efectivo).
- **Criterios que verifica:** "Desconexión activa contingencia en < 2 segundos" y "Bloqueo de tarjetas" (RF-26).
- **Test:** `useNetworkStatus.test.ts` — Simula evento de desconexión y valida cambio de estado.

### [ ] Tarea F2 (RF-27): Base de Datos Local en IndexedDB y Cifrado Hash
- **Archivos:** `lib/offlineStorage.ts`, `lib/hash.ts`.
- **Qué hace:** Inicializa `RetailOfflineDB`, almacena ventas con UUID y genera tickets de contingencia.
- **Criterios que verifica:** "Ventas se guardan en IndexedDB con estado PENDIENTE" y "Persistencia tras cerrar ventana" (RF-27).
- **Test:** `offlineStorage.test.ts` — Valida inserción transaccional y persistencia.

### [ ] Tarea F3 (RF-28): Cola de Sincronización en Background (`SyncQueue`)
- **Archivos:** `services/SyncQueueService.ts`.
- **Qué hace:** Lee ventas pendientes al volver internet, las envía al backend en lote y las marca como `RESINCRONIZADO`.
- **Criterio que verifica:** "Conectar la red envía ventas y actualiza registros a RESINCRONIZADO" (RF-28).
- **Test:** `syncQueue.test.ts` — Simula resincronización de lote de 2 ventas.
