# Tareas — F9: Cambio Directo de Prenda en Mostrador

**Fuentes:** `f09-devoluciones.md` (RF-23, RF-24, RF-25), `f09-devoluciones.ui.md`, `specs/generales/api-contracts.md`.  
**Regla SDD (AGENTS.md):** Una tarea a la vez, cada tarea concluye con su test automatizado y commit.

---

## Backend (`G4-Retail-backend`)

### [x] Tarea B1 (RF-23): Servicio de Validación de Comprobante y Plazo de 7 Días
- **Archivos:** `service/ValidacionComprobanteService.java`, `dto/ValidacionCambioResponse.java`.
- **Qué hace:** Busca la boleta confirmada en el registro local de F5 y valida `diasTranscurridos <= 7`.
- **Criterio que verifica:** "Boleta con más de 7 días marca plazo expirado" (RF-23).
- **Test:** `ValidacionComprobanteTest.java` — Valida los días 7 y 8.

### [x] Tarea B2 (RF-24): Reglas de Inspección Física
- **Archivos:** `model/InspeccionPrenda.java`, `service/InspeccionService.java`, `controller/PostventaController.java`.
- **Qué hace:** Valida etiquetas y signos de uso para cambio de talla, registra empaque y vendedor y deriva la falla de fábrica a garantía.
- **Criterio que verifica:** "Checklist incompleto bloquea cambio ordinario de talla" (RF-24).
- **Test:** `InspeccionPrendaTest.java` — Valida reglas de aprobación técnica.

### [ ] Tarea B3 (RF-25): Servicio de Cambio Directo
- **Qué hace:** Calcula el crédito y el total nuevo. Registra el cambio de mismo valor sin cobro, cobra la diferencia y emite la boleta con el pedido en Ventas en el de mayor valor, y rechaza el de menor valor. Retira la emisión de vales.
- **Criterios que verifica:** los tres casos de valor, el arqueo con solo la diferencia, el reintento idempotente y el límite de unidades compradas (RF-25).
- **Test:** `CambioDirectoServiceTest.java` — mismo modelo con precio distinto, mismo valor, mayor valor, menor valor, turno cerrado, reintento y concurrencia.

### [ ] Tarea B4 (RF-25): Puerto de Inventario con Mock
- **Qué hace:** `InventarioPort` con la firma de §6 del contrato, su mock (perfil `mock`) y el job que reintenta los movimientos `PENDIENTE` cada 5 minutos. Un fallo deja los movimientos en `PENDIENTE` sin revertir el cambio. El adaptador real de G6 queda fuera de esta tarea.
- **Criterio que verifica:** "El cambio registra los dos movimientos de stock; si el puerto falla, quedan pendientes" (RF-25).
- **Test:** `CambioInventarioPortTest.java` — Verifica las llamadas al puerto, el estado `PENDIENTE` ante un fallo y el paso a `CONFIRMADO` en el reintento.

---

## Frontend (`G4-Retail-frontend`)

### [x] Tarea F1 (RF-23): Pantalla `ReturnsPage` y Buscador con Escáner
- **Archivos:** `pages/ReturnsPage.tsx`, `api/postventaApi.ts`.
- **Qué hace:** Buscador por número de boleta y tarjeta con prendas compradas seleccionables.
- **Test:** `ReturnsPage.test.tsx` — Valida carga de boleta y bloqueo ante comprobante vencido.

### [x] Tarea F2 (RF-24): Modal `ReturnInspectionForm` con Checklist
- **Archivos:** `components/organisms/ReturnInspectionForm.tsx`.
- **Qué hace:** Formulario interactivo de inspección (etiquetas, sin uso, caja original).
- **Criterio que verifica:** "Etiquetas desmarcadas bloquea aprobación en cambio de talla" (RF-24).
- **Test:** `ReturnInspectionForm.test.tsx` — Valida activación del botón de aprobación.

### [ ] Tarea F3 (RF-25): Selección de Prendas Nuevas y Cobro de la Diferencia
- **Qué hace:** Reemplaza `VoucherCard`. Elige las prendas nuevas, muestra crédito, total y diferencia, bloquea el menor valor, cobra la diferencia con el modal de F5 e imprime la constancia o la boleta.
- **Criterio que verifica:** "El POS cobra solo la diferencia y bloquea el cambio de menor valor" (RF-25).
- **Test:** `CambioDirecto.test.tsx` — mismo valor sin cobro, mayor valor con cobro y menor valor bloqueado.
