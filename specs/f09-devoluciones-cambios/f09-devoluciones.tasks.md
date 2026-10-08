# Tareas — F9: Solicitud de Cambio de Prenda y Emisión de Vales

**Fuentes:** `f09-devoluciones.md` (RF-23, RF-24, RF-25), `f09-devoluciones.ui.md`, `specs/generales/api-contracts.md`.  
**Regla SDD (AGENTS.md):** Una tarea a la vez, cada tarea concluye con su test automatizado y commit.

---

## Backend (`G4-Retail-backend`)

### [ ] Tarea B1 (RF-23): Servicio de Validación de Comprobante y Plazo de 30 Días
- **Archivos:** `service/ValidacionComprobanteService.java`, `dto/ValidacionCambioResponse.java`.
- **Qué hace:** Verifica que el comprobante exista, esté pagado y que `diasTranscurridos <= 30`.
- **Criterio que verifica:** "Boleta con más de 30 días marca plazo expirado" (RF-23).
- **Test:** `ValidacionComprobanteTest.java` — Valida comprobantes de 10 días vs 35 días.

### [ ] Tarea B2 (RF-24): Endpoint de Inspección Física y Destino de Stock
- **Archivos:** `model/InspeccionPrenda.java`, `service/InspeccionService.java`, `controller/PostventaController.java`.
- **Qué hace:** Valida checklist de etiquetas y limpieza, clasificando a `REINGRESO_INVENTARIO` o `MERMA_GARANTIA`.
- **Criterio que verifica:** "Checklist incompleto bloquea cambio ordinario de talla" (RF-24).
- **Test:** `InspeccionPrendaTest.java` — Valida reglas de aprobación técnica.

### [ ] Tarea B3 (RF-25): Servicio de Emisión de Vales de Compra y Devolución de Stock
- **Archivos:** `model/ValeCompra.java`, `service/ValeCompraService.java`, `repository/ValeCompraRepository.java`.
- **Qué hace:** Genera vale correlativo con vigencia de 90 días e incrementa el stock de tienda si fue apta.
- **Criterios que verifica:** "Generación de código único de vale" e "Incremento de stock en inventario" (RF-25).
- **Test:** `ValeCompraServiceTest.java` — Valida caducidad de 90 días e incremento de existencias.

---

## Frontend (`G4-Retail-frontend`)

### [ ] Tarea F1 (RF-23): Pantalla `ReturnsPage` y Buscador con Escáner
- **Archivos:** `pages/ReturnsPage.tsx`, `api/postventaApi.ts`.
- **Qué hace:** Buscador de boleta o ticket de regalo y tarjeta con prendas compradas seleccionables.
- **Test:** `ReturnsPage.test.tsx` — Valida carga de boleta y bloqueo ante comprobante vencido.

### [ ] Tarea F2 (RF-24): Modal `ReturnInspectionForm` con Checklist
- **Archivos:** `components/organisms/ReturnInspectionForm.tsx`.
- **Qué hace:** Formulario interactivo de inspección (etiquetas, sin uso, caja original).
- **Criterio que verifica:** "Etiquetas desmarcadas bloquea aprobación en cambio de talla" (RF-24).
- **Test:** `ReturnInspectionForm.test.tsx` — Valida activación del botón de aprobación.

### [ ] Tarea F3 (RF-25): Componente `VoucherCard` con Impresión Térmica
- **Archivos:** `components/organisms/VoucherCard.tsx`.
- **Qué hace:** Vista previa del vale de compra con código de barras y opción de canje inmediato al carrito.
- **Criterio que verifica:** "Canje inmediato abona saldo al carrito POS" (RF-25).
- **Test:** `VoucherCard.test.tsx` — Valida renderizado de código de canje y fecha límite.
