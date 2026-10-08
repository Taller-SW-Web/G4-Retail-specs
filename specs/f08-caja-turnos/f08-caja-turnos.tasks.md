# Tareas — F8: Apertura y Cierre de Turno de Caja con Arqueo Ciego

**Fuentes:** `f08-caja-turnos.md` (RF-20, RF-21, RF-22), `f08-caja-turnos.ui.md`, `specs/generales/api-contracts.md`.  
**Regla SDD (AGENTS.md):** Una tarea a la vez, cada tarea concluye con su test automatizado y commit.

---

## Backend (`G4-Retail-backend`)

### [ ] Tarea B1 (RF-20): Entidad `CajaTurno` y Endpoint de Apertura con Fondo Fijo
- **Archivos:** `model/CajaTurno.java`, `repository/CajaTurnoRepository.java`, `controller/CajaController.java`.
- **Qué hace:** Inserta turno en estado `ABIERTO` y previene doble apertura con 409 Conflict.
- **Criterio que verifica:** "Apertura con fondo fijo y validación de terminal única" (RF-20).
- **Test:** `AperturaCajaTest.java` — Valida estado `ABIERTO` y bloqueo ante turno simultáneo.

### [ ] Tarea B2 (RF-21): Registro de Movimientos Menores de Efectivo
- **Archivos:** `model/CajaMovimiento.java`, `service/CajaMovimientoService.java`, `controller/CajaController.java`.
- **Qué hace:** Registra ingresos/egresos y valida que no se retiren más fondos de los disponibles en gaveta.
- **Criterio que verifica:** "Salida mayor a efectivo disponible rechaza con 422" (RF-21).
- **Test:** `CajaMovimientoTest.java` — Valida control de saldo disponible y actualización de montos.

### [ ] Tarea B3 (RF-22): Servicio de Cierre y Arqueo Ciego
- **Archivos:** `service/CajaCierreService.java`, `dto/CierreCajaRequest.java`, `dto/ReporteZCierreResponse.java`.
- **Qué hace:** Suma pagos en efectivo de la sesión, calcula saldo teórico, calcula diferencia ciega y cambia estado a `CERRADA`.
- **Criterio que verifica:** "Cálculo ciego de diferencia y generación de Reporte Z" (RF-22).
- **Test:** `CierreCajaServiceTest.java` — Comprueba cálculo exacto de sobrante/faltante y cierre de turno.

---

## Frontend (`G4-Retail-frontend`)

### [ ] Tarea F1 (RF-20): Modal de Apertura de Turno (`ShiftOpenModal`)
- **Archivos:** `components/organisms/ShiftOpenModal.tsx`, `store/caja.ts`.
- **Qué hace:** Modal bloqueante al iniciar sesión que captura el fondo fijo y desbloquea el POS.
- **Criterio que verifica:** "Terminal sin turno abierto bloquea el POS exigiendo apertura" (RF-20).
- **Test:** `ShiftOpenModal.test.tsx` — Valida validación numérica no negativa y submit exitoso.

### [ ] Tarea F2 (RF-21): Modal de Movimientos Menores
- **Archivos:** `components/organisms/CashMovementModal.tsx`.
- **Qué hace:** Formulario para registrar ingresos de sencillo o gastos menores con motivo.
- **Test:** `CashMovementModal.test.tsx` — Valida selector de tipo y validación de montos.

### [ ] Tarea F3 (RF-22): Pantalla de Arqueo Ciego y Reporte Z
- **Archivos:** `pages/CashClosePage.tsx`, `components/organisms/ZReport.tsx`.
- **Qué hace:** Calculadora de billetes/monedas sin mostrar saldo del sistema, confirmación y vista previa de Reporte Z.
- **Criterios que verifica:** "Conteo no revela saldo teórico antes de enviar" y "Cierre bloquea terminal" (RF-22).
- **Test:** `CashClosePage.test.tsx` — Valida suma reactiva de denominaciones y visualización del reporte final.
