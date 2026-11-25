# Spec — F10: Modo Contingencia y Sincronización Offline (v1.0)

### Responsable: Miguel (Tech Lead), apoyo de implementación de Mihael
### Requerimientos Funcionales Incluidos: RF-26, RF-27, RF-28
### Prioridad: Should have

---

## 1. ¿Por qué? (Problema de Negocio)
Las tiendas físicas sufren cortes imprevistos de internet o latencia severa en la nube:
1. Si la aplicación web POS se congela o muestra errores al perder la red, las cajas se detienen, los clientes no pueden pagar y se generan pérdidas económicas en la fila de mostrador.
2. Si las ventas offline se guardan en memoria volátil o `localStorage` frágil, se pierden al refrescar el navegador o apagar la terminal, provocando descalces de dinero físico.
3. Al volver el internet, si la sincronización no es atómica e idempotente, se pueden generar cobros duplicados o inconsistencias de stock.

---

## 2. ¿Para qué? (Objetivo)
Dotar a la terminal POS de una arquitectura de alta disponibilidad y resiliencia offline: detectar caídas de red en tiempo real conmutando a **Modo Contingencia Offline** (restringiendo a cobro en efectivo con catálogo en caché), almacenar las ventas transaccionalmente en una base de datos local **IndexedDB** (`RetailOfflineDB`) con UUID y hash SHA-256 emitiendo tickets de contingencia, y ejecutar una sincronización diferida automática por lotes al restablecerse la red garantizando estricta idempotencia.

---

## 3. ¿Hasta dónde? (Alcance)
* **Incluido:**
  * Detección reactiva de desconexión (`window.addEventListener('offline')` y heartbeat a `/health`).
  * Banner superior en ámbar de modo contingencia y contador de ventas en cola.
  * Bloqueo selectivo de pagos con tarjeta y padrones externos (solo cobro en efectivo).
  * Base de datos local embebida en IndexedDB con almacén `ventas_offline` indexado.
  * Generación de ticket térmico físico con leyenda *"Comprobante emitido en contingencia offline"* y hash de seguridad.
  * Ingesta batch en backend (`POST /api/v1/retail/contingencia/sincronizar`) con validación de idempotencia por UUID.
  * Despacho FIFO diferido en background y actualización local a `RESINCRONIZADO`.
* **Excluido:**
  * Autorización de tarjetas de crédito o pagos bancarios sin conectividad a pasarelas.

---

## 4. Referencias y Contratos
* **Contrato de API:** [`specs/generales/api-contracts.md`](../generales/api-contracts.md) → `POST /api/v1/retail/contingencia/sincronizar`, `GET /api/v1/retail/health`
* **Design System:** [`specs/generales/design-system.md`](../generales/design-system.md)
* **Modelo de Base de Datos:** `RET_CONTINGENCIA_OFFLINE_LOG`, IndexedDB `RetailOfflineDB`

---

## 5. Requerimientos Funcionales Detallados

### <a id="rf-26"></a>RF-26: Detección Automática y Conmutación a Modo Offline
* **Backend:**
  1. Expone `GET /api/v1/retail/health` para sondeo de heartbeat ligero (responde 200 OK con timestamp).
* **Frontend:**
  1. Monitorea eventos nativos `online` y `offline` y ejecuta ping a `/health` cada 15 segundos.
  2. Si falla 2 veces consecutivas o supera timeout (3000 ms):
     - Conmuta el estado compartido por contexto React a `OFFLINE`.
     - Despliega banner superior ámbar: *"MODO CONTINGENCIA ACTIVO — Sin conexión a internet. Caja operando en efectivo con catálogo local"*.
     - Deshabilita el medio de pago "Tarjeta POS" manteniendo únicamente "Efectivo".
  3. Al restablecer la red, cambia el banner a verde *"Conexión restablecida — Sincronizando..."* e inicia el envío.
* **Criterios de Aceptación (RF-26):**
  - [ ] Desconexión de red activa el modo de contingencia en menos de 2 segundos.
  - [ ] En modo offline, deshabilita "Tarjeta POS" y mantiene activo "Efectivo".
  - [ ] Permite continuar escaneando prendas y cobrando en efectivo sin pantallas de error.

---

### <a id="rf-27"></a>RF-27: Almacenamiento Local Seguro en IndexedDB
* **Backend:**
  1. Define esquema de datos de la orden offline para su posterior conciliación.
* **Frontend:**
  1. Abre `indexedDB.open('RetailOfflineDB', 1)` y crea el almacén `ventas_offline`.
  2. Al cobrar en efectivo en modo offline:
     - Genera un UUID v4 local único y correlativo de contingencia (ej. `CONT-TIENDA01-00012`).
     - Calcula el hash SHA-256 de integridad del payload para evitar adulteraciones locales.
     - Inserta el registro con `estado = 'PENDIENTE'`.
     - Descuenta temporalmente las prendas de la copia local del catálogo.
  3. Emite ticket térmico impreso con la leyenda *"COMPROBANTE EMITIDO EN CONTINGENCIA OFFLINE"* y los primeros 8 dígitos del hash SHA-256.
  4. Retención garantizada en IndexedDB incluso si se cierra el navegador.
* **Criterios de Aceptación (RF-27):**
  - [ ] Venta offline guarda registro con UUID y estado `PENDIENTE` en IndexedDB.
  - [ ] Cerrar y reabrir el navegador preserva las ventas en cola intactas.
  - [ ] El ticket impreso incluye la leyenda de contingencia y el hash de seguridad.

---

### <a id="rf-28"></a>RF-28: Sincronización Diferida y Conciliación Automática
* **Backend:**
  1. Expone `POST /api/v1/retail/contingencia/sincronizar`:
     - Recibe el lote de ventas offline.
     - Valida idempotencia verificando `venta_local_uuid` en `RET_CONTINGENCIA_OFFLINE_LOG` para evitar duplicados.
     - Envía a G5 la fecha y hora original de la venta física.
     - Delega la conciliación de stock a Ventas (G5) y asigna la numeración oficial en Retail. Retail no modifica inventario central.
     - Retorna `200 OK` con el mapeo de órdenes resincronizadas.
* **Frontend:**
  1. Al volver internet, el servicio en background lee registros `PENDIENTE` en IndexedDB.
  2. Envía el lote en cola FIFO y actualiza el banner con progreso (*"Sincronizando 1/3..."*).
  3. Al recibir 200 OK, actualiza el registro local en IndexedDB a `estado = 'RESINCRONIZADO'`.
  4. Cuando la cola llega a 0, el banner cambia a verde con toast de confirmación y se oculta tras 5 segundos.
* **Criterios de Aceptación (RF-28):**
  - [ ] Conectar la red dispara el envío automático en background sin intervención manual.
  - [ ] Reintentar el envío por red inestable no duplica órdenes (idempotencia por UUID).
  - [ ] Los registros en IndexedDB quedan marcados como `RESINCRONIZADO`.

---

## 6. Precondiciones y Dependencias
* Navegador con soporte estándar para IndexedDB (RNF-02).


## 7. Criterios de integración de Semana 11

Se mantiene el contrato central §5.10, incluido su lote de hasta 50 ventas. La ruta antigua `/ordenes/sincronizar` queda retirada de F10. El heartbeat ya existe y se conserva. CI/CD queda fuera de esta entrega.

- **CA-10-01:** un evento offline restringe inmediatamente el POS a efectivo. Al reconectar se verifica el heartbeat antes de sincronizar. Un solo proveedor de contexto comparte conectividad, cola y progreso, sin añadir stores globales.
- **CA-10-02:** IndexedDB confirma en una transacción la venta PENDIENTE, UUID, correlativo, hash y reserva de unidades locales antes de mostrar éxito o vaciar el carrito. Una cuota agotada o error de escritura conserva el carrito y muestra error. Reabrir la base conserva los datos. No se guardan tokens en las ventas.
- **CA-10-03:** se usa el último catálogo local disponible; se conservan sus códigos y precios. La reserva local evita revender unidades al recargar y al abrir otra pestaña. Un turno ya abierto se conserva para continuar durante el corte; no se abre una caja nueva sin conexión.
- **CA-10-04:** el ticket muestra CONT, fecha original, vuelto, leyenda de contingencia y los primeros ocho caracteres del hash. No anuncia pedido central ni comprobante fiscal confirmado antes de la conciliación.
- **CA-10-05:** el envío es FIFO, con un solo proceso por proveedor y grupos por terminal y turno. Se conserva ventaLocalUuid en todos los reintentos. RESINCRONIZADO y DUPLICADO quedan finalizados; los errores por venta permanecen visibles y pueden reintentarse. Una respuesta incompleta nunca elimina ventas.
- **CA-10-06:** el backend valida hash, importes, perfil activo, tienda, terminal y turno. Persiste una reserva antes de llamar a G5 y procesa cada venta en transacción separada. El UUID es único en la base y se bloquea durante el procesamiento: un reintento tras reiniciar o concurrente devuelve el resultado original. Otro cuerpo para el mismo UUID se rechaza. Una fila inválida no impide las demás.
- **CA-10-07:** solo una respuesta real de G5 confirma la sincronización. Fallos de G5 conservan el log y la clave; nunca se inventa un pedido. El cobro se registra exactamente una vez en F8, con el total neto efectivo para el arqueo. Un turno cerrado queda en revisión, sin alterar el cierre.

### Decisiones técnicas verificables

El hash detecta corrupción, no sustituye la autorización. SHA-256 se calcula sobre JSON UTF-8 sin espacios de esta matriz ordenada: `[terminalPos, turnoId, ventaLocalUuid, correlativoContingencia, fechaHoraOffline, [[sku, cantidad, precioEnCentimos], ...], totalEnCentimos, efectivoEnCentimos, vueltoEnCentimos, clienteIdO_null]`. Los importes admiten dos decimales; las líneas mantienen su orden. La fecha se conserva literalmente en formato ISO UTC del navegador.

La serie B010 se reserva a la conciliación F10, con secuencia persistente independiente de B001/F001, y el número se reserva antes de contactar a G5. Si G5 confirma pero la respuesta se pierde, el reintento conserva tanto UUID como comprobante. El contrato de lote no transporta datos de factura ni ticket regalo: se emite ticket de contingencia y se concilia como boleta; las operaciones que requieren identificación adicional quedan en revisión y conservan el ticket. No se inventan documentos del cliente.
