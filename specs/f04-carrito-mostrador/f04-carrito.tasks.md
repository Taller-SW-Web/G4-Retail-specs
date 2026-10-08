# Tareas — F4: Gestión del Carrito de Compras en Mostrador

**Fuentes:** `f04-carrito.md` (RF-10, RF-11, RF-12), `f04-carrito.ui.md`, `specs/generales/api-contracts.md`.  
**Regla SDD (AGENTS.md):** Una tarea a la vez, cada tarea concluye con su test automatizado y commit.

---

## Backend (`G4-Retail-backend`)

### [ ] Tarea B1 (RF-11, RF-12): Motor de Cálculo Financiero y Fórmulas SUNAT
- **Archivos:** `service/CalculoFinancieroService.java`, `dto/CalculoOrdenRequest.java`, `dto/CalculoOrdenResponse.java`.
- **Qué hace:** Calcula base gravada (`total / 1.18`), desglose de IGV (18%), redondeos bancarios y validación de promociones.
- **Criterio que verifica:** "Fórmulas matemáticas de desglose tributario según SUNAT" (RF-12).
- **Test:** `CalculoFinancieroServiceTest.java` — Verifica exactitud numérica a 2 decimales y consistencia imponible.

### [ ] Tarea B2 (RF-10, RF-11): Endpoint de Cálculo y Validación de Totales
- **Archivos:** `controller/OrdenController.java` (`POST /api/v1/ordenes/calcular`).
- **Qué hace:** Recibe ítems y cupón, valida cantidades positivas y devuelve balance financiero completo.
- **Criterios que verifica:** "Respuesta con total y desglose de descuentos" (RF-11, RF-12).
- **Test:** `OrdenControllerCalculoTest.java` (MockMvc) — Comprueba código 200 con JSON financiero.

---

## Frontend (`G4-Retail-frontend`)

### [ ] Tarea F1 (RF-10, RF-12): Store del Carrito (`cartStore`) y Lógica de Totales
- **Archivos:** `store/cart.ts`, `lib/totals.ts`.
- **Qué hace:** Agrega ítems, valida topes de `stockTienda`, incrementa unidades en SKU repetido y gestiona persistencia en `localStorage`.
- **Criterios que verifica:** "Agregar producto repetido incrementa cantidad sin duplicar fila" y "Bloqueo al tope de stock" (RF-10).
- **Test:** `cartStore.test.ts` / `totals.test.ts` — Valida incremento, tope de existencias y persistencia en recarga.

### [ ] Tarea F2 (RF-10): Componentes `CartLine`, `QuantityStepper` y Suspensión de Venta
- **Archivos:** `components/organisms/CartLine.tsx`, `components/molecules/QuantityStepper.tsx`, `components/organisms/HeldCarts.tsx`.
- **Qué hace:** Renderiza controles de cantidad, eliminación de prendas y modal de carritos en espera (*Held Carts*).
- **Criterios que verifica:** "Pausar venta guarda carrito con alias y permite reanudarlo" (RF-10).
- **Test:** `CartLine.test.tsx` / `HeldCarts.test.tsx` — Valida stepper interactivo y guardado/recuperación de venta pausada.

### [ ] Tarea F3 (RF-11, RF-12): Componente `TotalsPanel` y Bloque de Cupones
- **Archivos:** `components/organisms/TotalsPanel.tsx`, `components/organisms/CartPanel.tsx`.
- **Qué hace:** Muestra Subtotal, Descuentos en verde, IGV (18%), Total en Oswald destacado y campo para aplicar cupones.
- **Criterios que verifica:** "Cupón válido aplica descuento y recalcula totales" (RF-11) y "Botón de cobro deshabilitado si carrito vacío" (RF-12).
- **Test:** `TotalsPanel.test.tsx` — Valida formateo monetario en Soles y habilitación condicionada del botón de cobro.
