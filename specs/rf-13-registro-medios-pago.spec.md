# Spec — RF-13: Registro de Medios de Pago Presencial (v0.1)

### Responsable: Miguel (DevOps / Tech Lead)
### Requerimiento Funcional: RF-13: Registro de Medios de Pago Presencial
### Funcionalidad Padre: F5: Generación de Pedido, Pago en Tienda y Creación de Boleta
### Prioridad: Must have (Crítico)

---

## ¿Por qué? (problema)
En la tienda física, los clientes pagan mediante diferentes modalidades: dinero en efectivo, tarjetas de débito o crédito procesadas en un equipo POS físico (Izipay, Niubiz, etc.) o transferencias/billeteras digitales. Si el cajero debe calcular manualmente el vuelto o no queda registrado el código de voucher de la transacción con tarjeta, se producen descuadres de caja al cierre de turno y disputas operativas.

## ¿Para qué? (objetivo)
Permitir al cajero o vendedor en la terminal de cobro seleccionar el medio de pago presencial empleado por el cliente, calculando automáticamente el vuelto en tiempo real cuando es en efectivo y exigiendo la captura del código de referencia u operación cuando es mediante tarjeta o POS físico.

## ¿Hasta dónde? (alcance)
* **Incluido:** Modal o vista de cobro, selector de medio de pago (`EFECTIVO`, `TARJETA_POS`, `PAGO_MIXTO`), cálculo reactivo de vuelto (`montoRecibido - totalPagar`), validación de monto recibido suficiente, y campo obligatorio de referencia de operación para pagos con tarjeta.
* **Excluido:** Integración por cable/Bluetooth con hardware de datáfonos propietarios (se registra el voucher digitado manualmente), orquestación transaccional con la orden oficial (cubierto en RF-14), y emisión física del ticket (cubierto en RF-15).

## Referencias
* **Contrato:** [api-contracts.md](./api-contracts.md) — `POST /api/v1/ordenes/presenciales` (Sección 3)
* **Modelo:** `PagoPresencial` (`medioPago`: `"EFECTIVO" | "TARJETA_POS" | "MIXTO"`, `monto`: `number`, `montoRecibido`: `number`, `vuelto`: `number`, `referenciaOperacion`?: `string`)

## ¿Qué debe hacer? (comportamiento)

### Backend (Retail / Validación de Pagos)
1. Expone función o endpoint de validación de pago dentro del flujo transaccional:
   * Si `medioPago == "EFECTIVO"`:
     * Valida que `montoRecibido >= montoTotal`.
     * Calcula `vuelto = montoRecibido - montoTotal`.
   * Si `medioPago == "TARJETA_POS"`:
     * Valida que `referenciaOperacion` no sea nulo ni esté vacío (longitud mínima 4 caracteres alfanuméricos).
     * `vuelto = 0.00`.
   * Si el monto es insuficiente, rechaza con `400 Bad Request` indicando el saldo faltante.

### Frontend
1. Al pulsar *"Proceder al Cobro"* en el carrito (RF-12), se abre la pantalla modal de cobro:
   * Muestra el resumen del monto total a cobrar: `TOTAL A PAGAR: S/ XXX.XX`.
2. Pestañas o botones de selección de medio de pago:
   * **Opción A: Efectivo:**
     * Campo *"Monto recibido"* (con botones rápidos de billetes sugeridos: S/ 50, S/ 100, S/ 200 o Exacto).
     * Al tipear el monto, muestra inmediatamente en color verde: *"Vuelto a entregar: S/ XX.XX"*.
     * Si el monto recibido es menor al total a pagar:
       * Muestra mensaje en rojo: *"Monto insuficiente (Faltan S/ XX.XX)"*.
       * El botón de confirmación permanece bloqueado.
   * **Opción B: Tarjeta / POS Físico:**
     * Instrucción: *"Pase la tarjeta en el POS físico e ingrese los datos del voucher"*.
     * Campo obligatorio: *"N° de Referencia / Operación"* (ej. `OP-983120`).
     * El botón de confirmación permanece bloqueado si este campo está vacío.
3. El botón *"Confirmar Pago"* solo se habilita cuando la validación del método elegido es 100% satisfactoria.

## ¿Cómo verificamos? (criterios de aceptación)
- [ ] Cobro de S/ 120.00 con billete de S/ 200.00 en efectivo → Calcula y muestra un vuelto exacto de S/ 80.00 en pantalla.
- [ ] Cobro de S/ 120.00 con monto ingresado de S/ 100.00 en efectivo → Botón bloqueado con aviso *"Faltan S/ 20.00"*.
- [ ] Cobro con tarjeta sin escribir el número de voucher → El botón de confirmar pago no se activa.
- [ ] Cobro con tarjeta ingresando referencia `OP-12345` → Botón de pago habilitado para procesar.
- [ ] El cambio de método de pago entre efectivo y tarjeta limpia o recalcula adecuadamente los campos correspondientes.

## ¿Con qué condiciones? (precondiciones y dependencias)
* El cajero debe estar autenticado con rol `cajero` o `vendedor`.
* El carrito debe poseer importe mayor a cero.

## ¿Qué NO hará? (fuera de alcance)
* No se conectará por drivers de bajo nivel a puertos seriales de terminales POS.
* No retendrá saldos a crédito ni cuentas corrientes de clientes.
