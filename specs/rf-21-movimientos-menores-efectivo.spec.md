# Spec — RF-21: Registro de Movimientos Menores de Efectivo (v0.1)

### Responsable: Angie (DBA)
### Requerimiento Funcional: RF-21: Registro de Movimientos Menores de Efectivo
### Funcionalidad Padre: F8: Control de Turno y Cuadre de Caja
### Prioridad: Should have (Secundario en MVP)

---

## ¿Por qué? (problema)
En la rutina de mostrador ocurren transacciones de efectivo ajenas a las ventas de productos: egresos menores de caja chica (ej. pagar cinta de embalaje, rollos térmicos para la impresora de tickets o taxi de urgencia para traer stock de otra tienda) e ingresos extraordinarios (ej. inyección de más monedas para dar vuelto). Si estas salidas o entradas no quedan registradas, la caja se descuadrará irremediablemente en el arqueo final.

## ¿Para qué? (objetivo)
Permitir al cajero registrar movimientos de entrada o salida de efectivo no relacionados con pedidos de venta, indicando el tipo de movimiento, monto exacto, motivo justificado y persona que autoriza, manteniendo actualizado el saldo esperado de la gaveta de efectivo.

## ¿Hasta dónde? (alcance)
* **Incluido:** Formulario de registro de movimientos de caja chica, selección de tipo (`INGRESO_SENCILLO` o `SALIDA_GASTO`), validación de monto positivo (`monto > 0.00`), validación de no exceder el efectivo disponible en caja ante salidas, almacenamiento en `RET_MOVIMIENTO_CAJA` y reflejo en el saldo teórico del turno.
* **Excluido:** Contabilidad corporativa mayor (libros contables de la empresa) y conciliaciones bancarias.

## Referencias
* **Contrato:** [api-contracts.md](./api-contracts.md) — `POST /api/v1/retail/caja/movimientos`
* **Modelo:** `MovimientoCajaRequest` (`tipoMovimiento`, `monto`, `motivo`, `autorizadoPor`), `MovimientoCajaResponse` (`id`, `cajaSesionId`, `tipoMovimiento`, `monto`, `motivo`, `fechaHora`)

## ¿Qué debe hacer? (comportamiento)

### Backend (Microservicio Retail)
1. Expone `POST /api/v1/retail/caja/movimientos`:
   * Verifica que la terminal posea una sesión activa en estado `ABIERTA`.
   * Valida campos obligatorios: `tipoMovimiento` (`INGRESO_SENCILLO` | `SALIDA_GASTO`), `monto > 0.00`, `motivo` (mínimo 5 caracteres).
   * Si es `SALIDA_GASTO`: Calcula el efectivo actual en caja (saldo inicial + ventas efectivo + ingresos - egresos previos). Si `monto > efectivoActual`, responde `422 Unprocessable Entity` (*"Fondos insuficientes en gaveta para el egreso solicitado"*).
2. Inserta el registro en `RET_MOVIMIENTO_CAJA` vinculado a la sesión actual con `fecha_hora = NOW()`.
3. Retorna `201 Created` con el ID del movimiento y el saldo recalculado.

### Frontend
1. Botón de acceso rápido en el menú superior de caja: *"Movimiento de Caja (+/-)"*.
2. Modal emergente con selector:
   * Pestaña *"Ingreso de Efectivo"* (ej. inyección de sencillo).
   * Pestaña *"Salida / Gasto Menor"* (ej. insumos de tienda).
3. Campos requeridos:
   * Monto en soles (formato numérico decimal).
   * Motivo detallado (textarea con sugerencias rápidas: *"Compra rollos térmicos"*, *"Cambio por sencillo"*, *"Limpieza mostrador"*).
   * Campo opcional: *"Nombre de supervisor que autoriza"*.
4. Muestra en pie de modal el saldo de efectivo actual en gaveta para advertir si el egreso es viable.
5. Botón *"Registrar Movimiento"*: Envia la petición, muestra notificación de éxito *"Movimiento registrado correctamente"* y actualiza el contador local de caja.

## ¿Cómo verificamos? (criterios de aceptación)
- [ ] Registrar salida de S/ 15.00 por "Rollos de ticket" con saldo disponible de S/ 200.00 → Registra exitosamente y descuenta el saldo disponible a S/ 185.00.
- [ ] Intentar registrar salida de S/ 300.00 con saldo en caja de S/ 100.00 → Sistema bloquea la operación con mensaje de fondos insuficientes.
- [ ] Registrar ingreso de S/ 50.00 por "Sencillo de administración" → Incrementa el saldo teórico de caja.
- [ ] Enviar motivo vacío o monto menor o igual a cero → El formulario valida localmente e impide el envío.

## ¿Con qué condiciones? (precondiciones y dependencias)
* La caja debe estar en estado `ABIERTA`.
* Regla de Negocio RN-03: Trazabilidad completa de operaciones de caja.

## ¿Qué NO hará? (fuera de alcance)
* No genera comprobantes electrónicos tributarios de SUNAT (es un control interno de caja chica).
