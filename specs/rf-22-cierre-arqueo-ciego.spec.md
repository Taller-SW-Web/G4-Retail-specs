# Spec — RF-22: Cierre de Turno y Arqueo Ciego de Caja (Reporte X/Z) (v0.1)

### Responsable: Miguel (DevOps / Tech Lead)
### Requerimiento Funcional: RF-22: Cierre de Turno y Arqueo Ciego de Caja (Reporte X/Z)
### Funcionalidad Padre: F8: Control de Turno y Cuadre de Caja
### Prioridad: Must have (Crítico)

---

## ¿Por qué? (problema)
Al terminar el turno de trabajo, si el cajero ve en pantalla cuánto dinero "debería haber" antes de contar los billetes, se generan malas prácticas o manipulaciones para maquillar faltantes. Además, sin un proceso formal de cierre y emisión del reporte de arqueo (corte X/Z), la administración de la tienda deportiva no puede saber si el dinero físico coincide con las ventas registradas.

## ¿Para qué? (objetivo)
Implementar el proceso de **arqueo ciego de caja**: el cajero cuenta físicamente los billetes y monedas en la gaveta y declara el total sin que el sistema le revele el saldo teórico; una vez enviado, el sistema calcula automáticamente la diferencia (cuadre exacto, sobrante o faltante), cambia el estado de la sesión a `CERRADA` y genera el reporte formal de cierre de turno (Reporte Z) listo para impresión.

## ¿Hasta dónde? (alcance)
* **Incluido:** Modal de arqueo ciego con calculadora de denominaciones, captura del monto declarado, cálculo en backend del saldo teórico (`saldoInicial + ventasEfectivo + ingresosMenores - egresosMenores`), cálculo de la `diferencia_saldo`, actualización de `RET_CAJA_SESION` a `CERRADA`, reporte impreso de corte Z con desglose por medios de pago (efectivo vs tarjeta) y bloqueo de la terminal hasta una nueva apertura.
* **Excluido:** Depósito físico de valores en bancos y recojo de caudales.

## Referencias
* **Contrato:** [api-contracts.md](./api-contracts.md) — `POST /api/v1/retail/caja/cierre`
* **Modelo:** `CierreCajaRequest` (`montoDeclarado`, `desgloseBilletesMonedas`, `observaciones`), `CierreCajaResponse` (`sesionId`, `saldoInicial`, `ventasEfectivoTotal`, `ventasTarjetaTotal`, `saldoTeorico`, `saldoDeclarado`, `diferencia`, `estadoCuadre`, `fechaHoraCierre`)

## ¿Qué debe hacer? (comportamiento)

### Backend (Microservicio Retail)
1. Expone `POST /api/v1/retail/caja/cierre`:
   * Verifica sesión activa en estado `ABIERTA`.
   * Consulta las ventas concretadas en ese turno asociadas al terminal:
     * Suma de pagos en efectivo (`totalEfectivo`).
     * Suma de pagos en tarjeta POS (`totalTarjeta`).
   * Consulta los movimientos de caja chica de la sesión (`totalIngresos`, `totalEgresos`).
   * Calcula el `saldo_final_sistema = saldo_inicial + totalEfectivo + totalIngresos - totalEgresos`.
   * Calcula `diferencia_saldo = saldo_final_declarado - saldo_final_sistema`.
   * Asigna estado de sesión: `CERRADA` (si diferencia == 0) o `OBSERVADA` (si hay faltante o sobrante).
2. Persiste la fecha/hora de cierre, montos finales y observaciones en `RET_CAJA_SESION`.
3. Retorna el resumen consolidado del turno para la emisión del Reporte Z.

### Frontend
1. Botón en cabecera: *"Cerrar Turno de Caja"*.
2. Pantalla de Arqueo Ciego:
   * **No muestra** el saldo del sistema ni las ventas del día para evitar sesgos.
   * Provee interfaz amigable para ingresar el conteo físico de dinero:
     * Monedas: 0.10, 0.20, 0.50, 1.00, 2.00, 5.00 soles.
     * Billetes: 10, 20, 50, 100, 200 soles.
     * Muestra el *"Total Efectivo Recontado"* calculado reactivamente.
   * Campo opcional: *"Observaciones del Cajero"*.
3. Botón *"Confirmar y Cerrar Caja"*:
   * Solicita confirmación final (*"Esta acción cerrará su turno y no permitirá más ventas en este terminal"*).
4. Pantalla de Resultados y Reporte Z:
   * Muestra el resumen comparativo:
     * Total Efectivo Declarado vs Total Esperado.
     * Indicador visual:
       * Verde: *"Caja cuadrada con éxito (Diferencia S/ 0.00)"*.
       * Rojo: *"Faltante de S/ XX.XX"* o *"Sobrante de S/ XX.XX"*.
     * Resumen de ventas con tarjeta (vouchers POS).
   * Botón *"Imprimir Reporte Z"* (formato ticket para engrapar con el sobre de dinero).
   * Botón *"Cerrar Sesión / Salir"*.

## ¿Cómo verificamos? (criterios de aceptación)
- [ ] La pantalla de arqueo ciego no muestra en ningún momento el saldo esperado antes de enviar el conteo.
- [ ] Conteo físico coincide exactamente con ventas + fondo inicial → Diferencia calculada es 0.00 y estado queda `CERRADA`.
- [ ] Conteo físico es menor en S/ 10.00 al saldo del sistema → Reporta faltante de S/ -10.00 y marca sesión como `OBSERVADA`.
- [ ] Al cerrar la caja, la terminal bloquea el carrito POS y exige nueva apertura para operar.
- [ ] Clic en "Imprimir Reporte Z" genera el ticket de arqueo con fecha, hora, cajero y desglose financiero.

## ¿Con qué condiciones? (precondiciones y dependencias)
* La caja debe estar en estado `ABIERTA`.
* Todas las órdenes en proceso deben haberse completado o descartado.
* Regla de Negocio RN-03: Auditoría obligatoria de cierre de turno.

## ¿Qué NO hará? (fuera de alcance)
* No descuenta automáticamente sueldos de cajeros ante faltantes (eso es política administrativa de RRHH).
