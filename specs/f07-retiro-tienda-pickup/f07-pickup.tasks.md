# Tareas — F7: Verificación y Entrega Física en Tienda (Pickup)

**Fuentes:** `f07-pickup.md` (RF-18, RF-19), `f07-pickup.ui.md`, `specs/generales/api-contracts.md`.  
**Regla SDD (AGENTS.md):** Una tarea a la vez, cada tarea concluye con su test automatizado y commit.

---

## Backend (`G4-Retail-backend`)

### [ ] Tarea B1 (RF-18): Endpoint de Bandeja Pickup de la Tienda
- **Archivos:** `repository/PickupRepository.java`, `service/PickupService.java`, `controller/PickupController.java`.
- **Qué hace:** Filtra órdenes `RETIRO_EN_TIENDA` en estado `LISTO_PARA_RECOJO` según el `tiendaId` del vendedor.
- **Criterio que verifica:** "Bandeja solo muestra pedidos asignados a la tienda del operador" (RF-18).
- **Test:** `PickupRepositoryTest.java` — Valida filtrado por tienda y estado logístico.

### [ ] Tarea B2 (RF-19): Endpoint de Confirmación de Entrega Física
- **Archivos:** `dto/ConfirmarEntregaRequest.java`, `service/impl/PickupServiceImpl.java`.
- **Qué hace:** Valida DNI y nombres del receptor, actualiza estado a `ENTREGADO_EN_TIENDA` y genera constancia digital.
- **Criterio que verifica:** "Validación de receptor y transición oficial de estado" (RF-19).
- **Test:** `PickupServiceTest.java` — Verifica guardado de receptor y rechazo si DNI tiene formato inválido.

---

## Frontend (`G4-Retail-frontend`)

### [ ] Tarea F1 (RF-18): Store y Cliente API de Pickup
- **Archivos:** `store/pickup.ts`, `api/pickupApi.ts`.
- **Qué hace:** Gestiona la lista de pedidos en mostrador y métodos para consultar y entregar.
- **Test:** `pickupApi.test.ts` — Comprueba llamadas mock y actualización de estado.

### [ ] Tarea F2 (RF-18): Componente `PickupCard` y Bandeja de Tienda
- **Archivos:** `pages/PickupPage.tsx`, `components/organisms/PickupCard.tsx`.
- **Qué hace:** Lista reactiva de pedidos con casillero de trastienda y filtro instantáneo por DNI o código.
- **Criterio que verifica:** "Filtro por DNI resalta tarjeta de orden en < 300 ms" (RF-18).
- **Test:** `PickupPage.test.tsx` — Valida filtrado por DNI y contador de pedidos pendientes.

### [ ] Tarea F3 (RF-19): Modal `DeliveryModal` con Selector de Titular / Tercero
- **Archivos:** `components/organisms/DeliveryModal.tsx`.
- **Qué hace:** Formulario con autocompletado de titular o captura de tercero, checkbox legal y confirmación.
- **Criterios que verifica:** "Retiro por titular autocompleta datos" y "Checkbox obligatorio para habilitar botón" (RF-19).
- **Test:** `DeliveryModal.test.tsx` — Valida activación del botón solo con checkbox marcado y DNI válido.
