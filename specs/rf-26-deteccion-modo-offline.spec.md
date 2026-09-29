# Spec — RF-26: Detección Automática y Conmutación a Modo Offline (v0.1)

### Responsable: Cristhian (Backend Developer)
### Requerimiento Funcional: RF-26: Detección Automática y Conmutación a Modo Offline
### Funcionalidad Padre: F10: Modo de Contingencia y Resiliencia Offline
### Prioridad: Must have (Crítico)

---

## ¿Por qué? (problema)
Las tiendas físicas sufren cortes imprevistos de servicio de internet, caídas de routers o microcortes de conectividad con la nube. Si la aplicación web de Retail se congela o muestra pantallas de error al perder la red, las cajas se detienen, los clientes no pueden pagar y se generan pérdidas directas de ventas y quejas en la fila de mostrador.

## ¿Para qué? (objetivo)
Implementar un mecanismo reactivo en la terminal de Retail que detecte la pérdida de conectividad a la red en tiempo real (mediante eventos nativos `window.addEventListener('offline')` y sondeos *heartbeat* periódicos hacia el backend), conmutando inmediatamente la aplicación a **Modo Contingencia Offline**: alertando visualmente al vendedor, restringiendo las operaciones exclusivamente a cobro en efectivo con catálogo en caché y preparando el almacenamiento local.

## ¿Hasta dónde? (alcance)
* **Incluido:** Detección de pérdida de red mediante APIs del navegador y verificación de respuesta de endpoints (`/health`); despliegue de banner superior persistente en color ámbar *"Modo Contingencia (Sin Conexión) — Ventas en cola local"*; inhabilitación de operaciones que requieran red externa (como cobros con tarjeta o consulta de clientes en SUNAT/Reniec); y habilitación de cobro en efectivo contra inventario local en caché.
* **Excluido:** Mantenimiento de enlaces satelitales o conmutación física de hardware de red.

## Referencias
* **Contrato:** [api-contracts.md](./api-contracts.md) — `GET /api/v1/retail/health` (Heartbeat)
* **Modelo:** `EstadoConectividad` (`online`: boolean, `ultimoHeartbeat`: timestamp, `colaPendienteCount`: int)

## ¿Qué debe hacer? (comportamiento)

### Frontend (Arquitectura de Contingencia)
1. Monitoreo reactivo de conectividad:
   * Escucha eventos nativos `online` y `offline` en el navegador.
   * Ejecuta un *heartbeat* ligero cada 15 segundos hacia el backend (`GET /health`). Si 2 peticiones consecutivas fallan o superan el timeout (3000 ms), activa el estado offline.
2. Al detectar desconexión:
   * Cambia el estado global de conectividad a `OFFLINE`.
   * Despliega en la parte superior de la pantalla un banner prominente:
     * Ícono de nube desconectada.
     * Texto: *"MODO CONTINGENCIA ACTIVO — Sin conexión a internet. La caja continúa operando en efectivo con catálogo local"*.
     * Contador de ventas pendientes de sincronización (ej. `0 en cola`).
3. Restricciones operativas en Modo Offline:
   * Deshabilita el medio de pago *"Tarjeta POS"* (no hay pasarela de validación).
   * Mantiene activo el medio de pago *"Efectivo"*.
   * Bloquea la consulta de clientes a padrones externos, permitiendo cliente genérico *"Cliente Mostrador"* o DNI manual sin autocompletado en línea.
4. Al detectar restablecimiento de red (`online` y heartbeat exitoso):
   * Cambia el banner a verde: *"Conexión restablecida — Sincronizando ventas pendientes..."*.
   * Dispara el proceso de sincronización automática (RF-28).

## ¿Cómo verificamos? (criterios de aceptación)
- [ ] Desconectar el cable de red o activar modo offline en DevTools → La interfaz muestra el banner de contingencia en menos de 2 segundos.
- [ ] En modo offline, el selector de medio de pago deshabilita "Tarjeta POS" y mantiene únicamente "Efectivo".
- [ ] La terminal permite continuar agregando productos al carrito desde la caché local sin mostrar pantallas de error.
- [ ] Reconectar la red → El banner cambia a verde e inicia la resincronización sin recargar la página.

## ¿Con qué condiciones? (precondiciones y dependencias)
* Cumplimiento del Requisito No Funcional RNF-02: Disponibilidad y resiliencia ante contingencias de red.
* La aplicación debe haber precargado el catálogo básico en memoria o caché en la apertura de sesión.

## ¿Qué NO hará? (fuera de alcance)
* No valida tarjetas bancarias fuera de línea ni autoriza transacciones de crédito sin conectividad.
