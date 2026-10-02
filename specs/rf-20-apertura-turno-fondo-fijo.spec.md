# Spec — RF-20: Apertura de Turno con Fondo Fijo de Caja (v0.1)

### Responsable: Angie (DBA)
### Requerimiento Funcional: RF-20: Apertura de Turno con Fondo Fijo de Caja
### Funcionalidad Padre: F8: Control de Turno y Cuadre de Caja
### Prioridad: Must have (Crítico)

---

## ¿Por qué? (problema)
Al iniciar la jornada en tienda física, el cajero recibe un monto en efectivo (sencillo en monedas y billetes) para poder dar vuelto a los clientes. Si el sistema permite realizar ventas sin registrar previamente este fondo inicial ni asociar la terminal al cajero en turno, es imposible cuadrar la caja al final del día ni auditar faltantes o sobrantes de dinero físico.

## ¿Para qué? (objetivo)
Permitir al cajero/vendedor autenticado abrir formalmente el turno operativo en una terminal POS de mostrador específica, declarando el monto del fondo fijo inicial en soles (con desglose de denominaciones opcional), validando que no exista un turno previo abierto en esa terminal y habilitando las funciones de cobro en efectivo.

## ¿Hasta dónde? (alcance)
* **Incluido:** Modal bloqueante de apertura de caja al iniciar sesión si no hay turno activo, registro de fecha/hora de apertura, código de terminal POS, `vendedorId`, monto de fondo inicial en soles (`saldoInicialEfectivo >= 0.00`), generación del registro de sesión en la base de datos de Retail y desbloqueo de la interfaz de ventas.
* **Excluido:** Conteo de ventas (cubierto en RF-13 y RF-22), arqueo de cierre (cubierto en RF-22) y asignación de permisos de cajero (gestionado por el microservicio de *Seguridad y Usuarios*).

## Referencias
* **Contrato:** [api-contracts.md](./api-contracts.md) — `POST /api/v1/retail/caja/apertura`
* **Modelo:** `AperturaCajaRequest` (`terminalPos`, `saldoInicial`, `desgloseDenominaciones`), `CajaSesionResponse` (`sesionId`, `vendedorId`, `terminalPos`, `estado`, `fechaHoraApertura`, `saldoInicial`)

## ¿Qué debe hacer? (comportamiento)

### Backend (Microservicio Retail)
1. Expone `POST /api/v1/retail/caja/apertura`:
   * Requiere token Bearer con rol `vendedor` o `cajero`.
   * Valida que la terminal POS enviada no tenga una sesión con `estado == 'ABIERTA'`.
   * Si ya existe un turno abierto en esa terminal, responde `409 Conflict` (*"La terminal ya cuenta con un turno abierto. Debe cerrarlo antes de iniciar uno nuevo"*).
   * Valida que `saldoInicialEfectivo` sea un número no negativo (`>= 0.00`).
2. Inserta el registro en la tabla `RET_CAJA_SESION` con `estado = 'ABIERTA'`, `fecha_hora_apertura = NOW()` y el `vendedor_id` extraído del token JWT.
3. Retorna `201 Created` con el `sesionId` generado.

### Frontend
1. Al iniciar sesión en la terminal de retail:
   * Consulta el estado de turno de la terminal (`GET /api/v1/retail/caja/estado-actual`).
   * Si el estado es `CERRADA`, despliega modal obligatorio no descartable: *"Apertura de Turno de Caja"*.
2. El modal solicita:
   * Campo *"Fondo Fijo Inicial (S/)"* (con valor numérico obligatorio, ej. S/ 200.00).
   * Calculadora rápida de denominaciones (opcional: conteo de monedas de 1, 2, 5 soles y billetes de 10, 20, 50, 100 soles).
   * Confirmación del cajero responsable y fecha/hora del sistema.
3. Botón *"Confirmar Apertura"*:
   * Valida que el monto sea válido.
   * Envía la petición al backend.
   * Al recibir éxito, cierra el modal, muestra banner de estado *"Turno Abierto — Caja 01 | Cajero: [Nombre]"* y habilita las operaciones del POS.

## ¿Cómo verificamos? (criterios de aceptación)
- [ ] Inicio de sesión en terminal sin turno abierto → Despliega obligatoriamente el modal de apertura impidiendo realizar ventas.
- [ ] Apertura con monto S/ 150.00 → Guarda el registro con estado `ABIERTA`, saldo inicial 150.00 y fecha/hora exacta.
- [ ] Intentar abrir caja en una terminal que ya tiene turno abierto → Retorna 409 Conflict y el frontend notifica que ya está abierta.
- [ ] Ingresar monto negativo en el fondo inicial → Frontend valida y bloquea el botón con advertencia *"El monto no puede ser negativo"*.

## ¿Con qué condiciones? (precondiciones y dependencias)
* El usuario debe estar autenticado con rol `vendedor` o `cajero`.
* Regla de Negocio RN-03: Auditoría y trazabilidad obligatoria de operaciones monetarias presenciales.

## ¿Qué NO hará? (fuera de alcance)
* No modifica saldos de cuentas bancarias ni billeteras electrónicas.
* No permite abrir múltiples turnos simultáneos en la misma terminal física.
