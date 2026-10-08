# Spec — F8: Apertura y Cierre de Turno de Caja con Arqueo Ciego (v1.0)

### Responsable: Angie (DBA) & Cristhian (Backend Developer)
### Requerimientos Funcionales Incluidos: RF-20, RF-21, RF-22
### Prioridad: Must have (Apertura en Hito 3 / Cierre avanzado)

---

## 1. ¿Por qué? (Problema de Negocio)
El manejo de dinero físico en mostrador exige control financiero y auditoría rigurosa:
1. Si el cajero vende sin declarar previamente un fondo fijo inicial (sencillo para vueltos), es imposible cuadrar la caja al final del día.
2. Durante el día ocurren entradas y salidas de caja chica ajenas a las ventas (compra de rollos térmicos, inyección de sencillo). Si no se registran, la caja se descuadra irremediablemente.
3. Si al cerrar el turno el cajero ve cuánto dinero "debería haber", puede manipular el conteo para ocultar faltantes. El arqueo debe ser ciego e inmutable.

---

## 2. ¿Para qué? (Objetivo)
Gestionar el ciclo de vida completo del turno de caja (`ABIERTO`, `CERRADO`, `OBSERVADO`): registrar la apertura con fondo fijo inicial desbloqueando las operaciones de la terminal, permitir movimientos menores justificados de caja chica (ingresos/egresos), y ejecutar el **arqueo ciego de caja** (el cajero declara el dinero contado físicamente sin conocer el saldo del sistema), calculando automáticamente faltantes/sobrantes y emitiendo el Reporte de Corte Z.

---

## 3. ¿Hasta dónde? (Alcance)
* **Incluido:**
  * Modal obligatorio de apertura de turno (`POST /api/v1/caja/turnos/apertura`) con fondo fijo en soles (`saldoInicial >= 0.00`).
  * Validación de terminal única: no permite dos turnos abiertos simultáneos en la misma caja.
  * Registro de movimientos menores (`POST /api/v1/caja/turnos/{id}/movimientos`) con validación de no exceder el efectivo en caja ante egresos.
  * Arqueo ciego de cierre (`POST /api/v1/caja/turnos/{id}/cierre`) con calculadora por denominaciones de billetes y monedas.
  * Cálculo en backend del saldo teórico (`saldoInicial + ventasEfectivo + ingresosMenores - egresosMenores`) y de la `diferencia_saldo`.
  * Generación e impresión del Reporte Z de cierre y bloqueo de la terminal hasta una nueva apertura.
* **Excluido:**
  * Depósitos de valores a bóveda central o camión de caudales.

---

## 4. Referencias y Contratos
* **Contrato de API:** [`specs/generales/api-contracts.md`](../generales/api-contracts.md) → `POST /api/v1/caja/turnos/apertura`, `POST /api/v1/caja/turnos/{id}/cierre`
* **Design System:** [`specs/generales/design-system.md`](../generales/design-system.md)
* **Modelo de Base de Datos:** `RET_CAJA_TURNOS`, `RET_CAJA_MOVIMIENTOS`, `RET_CAJA_ARQUEOS`

---

## 5. Requerimientos Funcionales Detallados

### <a id="rf-20"></a>RF-20: Apertura de Turno con Fondo Fijo de Caja
* **Backend:**
  1. Expone `POST /api/v1/caja/turnos/apertura`:
     * Requiere token con rol `CAJERO` o `SUPERVISOR`.
     * Valida que la terminal enviada no tenga una sesión en estado `ABIERTO`. Si ya existe, responde `409 Conflict`.
     * Valida que `saldoInicial >= 0.00`.
     * Inserta registro en `RET_CAJA_TURNOS` con `estado = 'ABIERTO'` y fecha/hora actual.
     * Retorna `201 Created` con el ID del turno generado.
* **Frontend:**
  1. Al iniciar sesión, si la terminal no tiene turno activo, despliega modal bloqueante no descartable `ShiftOpenModal`.
  2. Input de Fondo Fijo Inicial con teclado virtual o sugerencias.
  3. Botón *"Confirmar Apertura"*: envía datos, cierra el modal y desbloquea el POS mostrando banner *"Turno Abierto — Caja 01 | [Nombre]"*.
* **Criterios de Aceptación (RF-20):**
  - [ ] Terminal sin turno abierto bloquea el POS exigiendo el modal de apertura.
  - [ ] Apertura con monto S/ 150.00 persiste el registro en estado `ABIERTO`.
  - [ ] Intentar abrir en terminal ya abierta responde 409 Conflict y notifica al usuario.
  - [ ] Monto negativo en el fondo inicial es bloqueado en frontend y rechazado en backend.

---

### <a id="rf-21"></a>RF-21: Registro de Movimientos Menores de Efectivo
* **Backend:**
  1. Expone `POST /api/v1/caja/turnos/{id}/movimientos`:
     * Valida `tipoMovimiento` (`INGRESO_SENCILLO` | `SALIDA_GASTO`), `monto > 0.00` y `motivo` (mínimo 5 caracteres).
     * Si es salida: calcula el efectivo actual en gaveta. Si `monto > efectivoActual`, responde `422 Unprocessable Entity` (*Fondos insuficientes*).
     * Registra en `RET_CAJA_MOVIMIENTOS` y recalcula el saldo teórico.
* **Frontend:**
  1. Modal *"Movimiento de Caja (+/-)"* con pestañas de Ingreso y Salida.
  2. Campos: Monto, Motivo detallado y supervisor que autoriza.
  3. Muestra en pie el saldo disponible en gaveta para advertir si el egreso es viable.
* **Criterios de Aceptación (RF-21):**
  - [ ] Salida de S/ 15.00 con saldo de S/ 200.00 registra con éxito y descuenta a S/ 185.00.
  - [ ] Salida mayor al efectivo disponible es bloqueada con mensaje de fondos insuficientes.
  - [ ] Ingreso de dinero incrementa el saldo teórico esperado.

---

### <a id="rf-22"></a>RF-22: Cierre de Turno y Arqueo Ciego de Caja (Reporte X/Z)
* **Backend:**
  1. Expone `POST /api/v1/caja/turnos/{id}/cierre`:
     * Suma pagos en efectivo de la sesión (`totalEfectivo`).
     * Suma movimientos (`totalIngresos - totalEgresos`).
     * Calcula `saldo_teorico = saldoInicial + totalEfectivo + totalIngresos - totalEgresos`.
     * Calcula `diferencia = saldoDeclarado - saldo_teorico`.
     * Actualiza sesión a `CERRADA` (o `OBSERVADA` si hay descuadre) con timestamp inmutable.
     * Retorna consolidado del turno para el Reporte Z.
* **Frontend:**
  1. Pantalla de Arqueo Ciego (`CashClosePage`):
     * **No muestra** el saldo del sistema ni las ventas del día para evitar sesgos.
     * Tabla de conteo por billetes y monedas sumando el *"Total Efectivo Recontado"*.
     * Campo de observaciones del cajero.
  2. Botón *"Confirmar y Cerrar Caja"* con diálogo de confirmación final.
  3. Pantalla de Resultados y Reporte Z (`ZReport`):
     * Revela el comparativo: Declarado vs Esperado y Diferencia (verde: cuadrada; rojo: descuadre).
     * Resumen de transacciones con tarjeta.
     * Botón *"Imprimir Reporte Z"* (formato ticket) y botón para cerrar sesión.
* **Criterios de Aceptación (RF-22):**
  - [ ] El conteo físico no revela el monto teórico del sistema antes del envío.
  - [ ] El backend calcula la diferencia exacta entre monto físico y teórico.
  - [ ] El cierre bloquea inmediatamente la terminal para nuevas ventas.
  - [ ] Genera el Reporte Z listo para imprimir y archivar.

---

## 6. Precondiciones y Dependencias
* Cajero autenticado con perfil `CAJERO` o `SUPERVISOR`.
