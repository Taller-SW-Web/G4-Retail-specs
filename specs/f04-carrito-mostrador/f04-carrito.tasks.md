# Tareas — F4: Gestión del Carrito de Compras en Mostrador

**Fuentes:** `f04-carrito.md` (RF-10, RF-11, RF-12), `f04-carrito.ui.md`, `specs/generales/api-contracts.md`.  
**Regla SDD (AGENTS.md):** Una tarea a la vez, cada tarea concluye con su test automatizado y commit.

---

## Backend (`G4-Retail-backend`)

### [ ] Tarea B1 (RF-11, RF-12): Motor de Cálculo Financiero y Fórmulas SUNAT
- **Archivos:** `service/CarritoService.java`, `dto/CalculoCarritoRequest.java`, `dto/CalculoCarritoResponse.java`.
- **Qué hace:** Calcula base gravada (`total / 1.18`), desglose de IGV (18%), redondeos bancarios a 2 decimales y evaluación preliminar de totales.
- **Criterio que verifica:** "Fórmulas matemáticas de desglose tributario según SUNAT" (RF-12).
- **Test:** `CarritoServiceTest.java` — Verifica exactitud numérica a 2 decimales y consistencia imponible.

### [ ] Tarea B2 (RF-10, RF-11, RF-12): Endpoints de Cálculo y Suspensión de Carritos
- **Archivos:** `controller/CarritoController.java` (`POST /api/v1/retail/carritos/calcular` y `POST /api/v1/retail/carritos-espera`), `dto/CarritoEsperaDto.java`.
- **Qué hace:** Expone endpoint de vista previa de totales y persistencia de ventas pausadas para probadores.
- **Criterios que verifica:** "Respuesta con total y desglose de descuentos" (RF-11, RF-12) y "Suspensión de carritos" (RF-10).
- **Test:** `CarritoServiceTest.java` / `CarritoControllerTest.java` — Comprueba código 200 con JSON financiero y 201 en carritos en espera.

---

## Frontend (`G4-Retail-frontend`)

### [ ] Tarea F1 (RF-10, RF-12): Store del Carrito (`cartStore`) y Lógica de Totales
- **Archivos:** `store/cart.ts`, `lib/cart.ts`, `lib/cartStorage.ts`.
- **Qué hace:** Agrega ítems, valida topes de `stockTienda`, incrementa unidades en SKU repetido y gestiona persistencia en `localStorage`.
- **Criterios que verifica:** "Agregar producto repetido incrementa cantidad sin duplicar fila" y "Bloqueo al tope de stock" (RF-10).
- **Test:** `lib/cart.test.ts` / `lib/cartStorage.test.ts` — Valida incremento, tope de existencias y persistencia en recarga.

### [ ] Tarea F2 (RF-10): Componentes `CartLine`, `HeldCarts` y Suspensión de Venta
- **Archivos:** `components/organisms/carrito/CartLine.tsx`, `components/organisms/carrito/HeldCarts.tsx`.
- **Qué hace:** Renderiza controles de cantidad, eliminación de prendas y modal de carritos en espera (*Held Carts*).
- **Criterios que verifica:** "Pausar venta guarda carrito con alias y permite reanudarlo" (RF-10).
- **Test:** Valida stepper interactivo y guardado/recuperación de venta pausada.

### [ ] Tarea F3 (RF-11, RF-12): Componente `TotalsPanel` y Panel Principal `CartPanel`
- **Archivos:** `components/organisms/carrito/TotalsPanel.tsx`, `components/organisms/carrito/CartPanel.tsx`.
- **Qué hace:** Muestra Subtotal, Descuentos en verde, IGV (18%), Total en Oswald destacado y ensamble en el panel lateral de `/pos`.
- **Criterios que verifica:** "Resumen financiero cumple desglose SUNAT" (RF-12) y "Botón de cobro deshabilitado si carrito vacío" (RF-12).
- **Test:** Valida formateo monetario en Soles y habilitación condicionada del botón de cobro.
