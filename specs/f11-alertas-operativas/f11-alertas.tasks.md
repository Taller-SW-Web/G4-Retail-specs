# Tareas — F11: Alertas Operativas y Notificaciones en Tienda

**Fuentes:** `f11-alertas.md` (RF-29, RF-30, RF-31), `f11-alertas.ui.md`, `specs/generales/api-contracts.md`.  
**Regla SDD (AGENTS.md):** Una tarea a la vez, cada tarea concluye con su test automatizado y commit.

---

## Backend (`G4-Retail-backend`)

### [ ] Tarea B1 (RF-29): Servicio y Endpoint de Stock Crítico
- **Archivos:** `service/AlertaStockService.java`, `controller/AlertaController.java`.
- **Qué hace:** Filtra variantes con existencias locales `<= 2` para la tienda del vendedor y cruza con stock central.
- **Criterio que verifica:** "Variante con stock <= 2 aparece en semáforo de alertas" (RF-29).
- **Test:** `AlertaStockServiceTest.java` — Valida ordenamiento priorizando stock 0 y luego 1-2.

### [ ] Tarea B2 (RF-30, RF-31): Endpoints de Pickups del Día y Campañas Comerciales
- **Archivos:** `controller/AlertaController.java`, DTOs correspondientes.
- **Qué hace:** Expone listas de paquetes del día con anaquel físico y promociones activas con cupón.
- **Criterios que verifica:** "Filtro de pickups del día" (RF-30) y "Campañas vigentes para Retail" (RF-31).
- **Test:** `AlertaControllerTest.java` (MockMvc) — Comprueba contratos 200 con JSON.

---

## Frontend (`G4-Retail-frontend`)

### [ ] Tarea F1 (RF-29): Widget Semáforo de Stock Crítico
- **Archivos:** `components/organisms/CriticalStockWidget.tsx`.
- **Qué hace:** Panel colapsable con badges rojos/ámbares y existencias en almacén central.
- **Criterio que verifica:** "Badge rojo para 0 unidades y ámbar para últimas unidades" (RF-29).
- **Test:** `CriticalStockWidget.test.tsx` — Valida renderizado y botón de copiado de SKU.

### [ ] Tarea F2 (RF-30): Bandeja Rápida de Pickups con Anaquel
- **Archivos:** `components/organisms/PickupDayBoard.tsx`.
- **Qué hace:** Tarjetas con nombre, DNI, anaquel físico (`📍 Anaquel A-12`) y botón hacia entrega.
- **Criterio que verifica:** "Tarjeta muestra anaquel y filtro por DNI instantáneo" (RF-30).
- **Test:** `PickupDayBoard.test.tsx` — Valida filtrado en tiempo real.

### [ ] Tarea F3 (RF-31): Tira Superior de Campañas y Cupones
- **Archivos:** `components/molecules/PromoBanner.tsx`.
- **Qué hace:** Chips con promociones del día y clic para inyectar cupón directamente al carrito POS.
- **Criterio que verifica:** "Clic en campaña con cupón rellena campo de carrito POS" (RF-31).
- **Test:** `PromoBanner.test.tsx` — Valida inyección del cupón al store del carrito.
