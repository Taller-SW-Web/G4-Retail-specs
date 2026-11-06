# Tareas — F9: Solicitud de Cambio de Prenda y Emisión de Vales

**Fuentes:** `f09-devoluciones.md` (RF-23, RF-24, RF-25), `f09-devoluciones.ui.md`, `specs/generales/api-contracts.md`.  
**Regla SDD (AGENTS.md):** Una tarea a la vez, cada tarea concluye con su test automatizado y commit.

---

## Backend (`G4-Retail-backend`)

### [ ] Tarea B1 (RF-23): Servicio de Validación de Comprobante y Plazo de 7 Días
- **Archivos:** `service/ValidacionComprobanteService.java`, `dto/ValidacionCambioResponse.java`.
- **Qué hace:** Busca la boleta confirmada en el registro local de F5 y valida `diasTranscurridos <= 7`.
- **Criterio que verifica:** "Boleta con más de 7 días marca plazo expirado" (RF-23).
- **Test:** `ValidacionComprobanteTest.java` — Valida los días 7 y 8.

### [ ] Tarea B2 (RF-24): Reglas de Inspección Física
- **Archivos:** `model/InspeccionPrenda.java`, `service/InspeccionService.java`, `controller/PostventaController.java`.
- **Qué hace:** Valida etiquetas y signos de uso para cambio de talla, registra empaque y vendedor y deriva la falla de fábrica a garantía.
- **Criterio que verifica:** "Checklist incompleto bloquea cambio ordinario de talla" (RF-24).
- **Test:** `InspeccionPrendaTest.java` — Valida reglas de aprobación técnica.

### [ ] Tarea B3 (RF-25): Servicio de Emisión de Vales de Compra
- **Archivos:** `model/ValeCompra.java`, `service/ValeCompraService.java`, `repository/ValeCompraRepository.java`.
- **Qué hace:** Emite un vale con vigencia de 30 días, en la misma transacción que registra el cambio.
- **Criterios que verifica:** "Código único de vale, reintento idempotente y límite de unidades compradas" (RF-25).
- **Test:** `ValeCompraServiceTest.java` — Valida vigencia de 30 días, repetición de la operación y disponibilidad de unidades.

---

## Frontend (`G4-Retail-frontend`)

### [ ] Tarea F1 (RF-23): Pantalla `ReturnsPage` y Buscador con Escáner
- **Archivos:** `pages/ReturnsPage.tsx`, `api/postventaApi.ts`.
- **Qué hace:** Buscador por número de boleta y tarjeta con prendas compradas seleccionables.
- **Test:** `ReturnsPage.test.tsx` — Valida carga de boleta y bloqueo ante comprobante vencido.

### [ ] Tarea F2 (RF-24): Modal `ReturnInspectionForm` con Checklist
- **Archivos:** `components/organisms/ReturnInspectionForm.tsx`.
- **Qué hace:** Formulario interactivo de inspección (etiquetas, sin uso, caja original).
- **Criterio que verifica:** "Etiquetas desmarcadas bloquea aprobación en cambio de talla" (RF-24).
- **Test:** `ReturnInspectionForm.test.tsx` — Valida activación del botón de aprobación.

### [ ] Tarea F3 (RF-25): Componente `VoucherCard` con Impresión Térmica
- **Archivos:** `components/organisms/VoucherCard.tsx`.
- **Qué hace:** Vista imprimible del vale emitido con su código de barras, monto y vencimiento.
- **Criterio que verifica:** "El vale emitido muestra código, importe y vencimiento" (RF-25).
- **Test:** `VoucherCard.test.tsx` — Valida renderizado de código de canje y fecha límite.
