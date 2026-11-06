# Spec — F7: Verificación y Entrega Física en Tienda (Pickup) (v1.0)

### Responsable: Maylle (Arquitectura de Software) & Kevin (Frontend Lead)
### Requerimientos Funcionales Incluidos: RF-18, RF-19
### Prioridad: Must have

---

## 1. ¿Por qué? (Problema de Negocio)
Los clientes que compran por el canal digital (Web o Chatbot) bajo modalidad *Retiro en Tienda* (*Store Pickup*) acuden al local físico para reclamar su paquete:
1. Si el personal de mostrador no cuenta con una bandeja filtrada por su propia tienda y no puede validar si el paquete realmente se encuentra en estado `LISTO_PARA_RECOJO`, se generan entregas indebidas o búsquedas inútiles en trastienda.
2. Si el personal entrega el paquete sin verificar la identidad física del receptor (titular o tercero autorizado) ni registrar constancia digital de entrega, se originan reclamos de mercadería no recibida y pérdidas sin trazabilidad.

---

## 2. ¿Para qué? (Objetivo)
Permitir al personal de mostrador visualizar la bandeja exclusiva de pedidos asignados para retiro en su tienda (`tiendaId`), validar que la orden esté efectivamente en estado `LISTO_PARA_RECOJO`, verificar la identidad del receptor (titular o tercero autorizado con DNI de 8 dígitos), confirmar el checklist físico de integridad de prendas y que Ventas (G5) actualice el estado oficial a `ENTREGADO` emitiendo constancia digital.

---

## 3. ¿Hasta dónde? (Alcance)
* **Incluido:**
  * Bandeja de pedidos pendientes de entrega filtrados por la tienda física del vendedor (`GET /api/v1/retail/pickup/pendientes`).
  * Búsqueda ágil por código de pedido o DNI del titular dentro de la bandeja.
  * Modal de confirmación de entrega física (`POST /api/v1/retail/pickup/{pedidoId}/entrega`).
  * Discriminación de receptor: Titular (nombre autocompletado; el vendedor digita el DNI del documento) o Tercero Autorizado (captura de DNI, nombres y carta poder).
  * Checkbox obligatorio de verificación física de bultos y prendas.
  * Remoción automática de la orden de la bandeja de pendientes y generación de constancia digital.
* **Excluido:**
  * Preparación y empaque en almacén logístico (módulo de Despacho y Entrega).
  * Cambios de talla o devoluciones posteriores (cubierto en F9).

---

## 4. Referencias y Contratos
* **Contrato de API:** [`specs/generales/api-contracts.md`](../generales/api-contracts.md) §5.7 → `GET /api/v1/retail/pickup/pendientes`, `POST /api/v1/retail/pickup/{pedidoId}/entrega` (Ventas G5: `GET /api/v1/pedidos/pickup`, `POST /api/v1/pedidos/{pedidoId}/entrega-pickup`)
* **Design System:** [`specs/generales/design-system.md`](../generales/design-system.md)
* **Modelo de Base de Datos:** Sin tablas propias: el pedido y su estado los guarda Ventas (G5). Decisión #9 resuelta en la Semana 11.

---

## 5. Requerimientos Funcionales Detallados

### <a id="rf-18"></a>RF-18: Verificación y Validación de Retiro en Tienda
* **Backend:**
  1. Expone `GET /api/v1/retail/pickup/pendientes` (contrato §5.7):
     * Toma el vendedor del `sub` del JWT y su tienda del **perfil local** (`RET_PERSONAL_TIENDA`); el token no trae la tienda.
     * Si el perfil guarda la tienda como UUID (D-05), la traduce a su código `TIENDA-...` (`retail.tienda.codigos-por-uuid`). Un UUID sin código responde `409 TIENDA_SIN_CODIGO_SUCURSAL`: nunca se muestra la bandeja de otra sucursal.
     * Consulta a Ventas (G5) `GET /api/v1/pedidos/pickup?tiendaId={codigo}`, que filtra por tienda y modalidad retiro en tienda.
     * Retorna lista de pedidos con cliente (`clienteDni` puede venir `null`), prendas y ubicación física en tienda (ej. *Gaveta B-04*).
* **Frontend:**
  1. Pestaña *"Entregas en Tienda (Pickup)"* con contador de pendientes (ej. badge `5 pendientes`).
  2. Buscador reactivo por DNI o código de pedido (`pedidoId`); un pedido sin DNI no rompe la búsqueda y se encuentra por su código.
  3. Tarjeta `PickupCard` con código, cliente, bultos, fecha y casillero de trastienda (muestra *DNI no registrado* si falta).
  4. Botón *"Procesar Retiro"* en cada tarjeta. Si el pedido pertenece a otra sede o está en camino, muestra aviso ámbar y bloquea la entrega.
* **Criterios de Aceptación (RF-18):**
  - [ ] La bandeja solo muestra pedidos asignados a la tienda del vendedor en sesión.
  - [ ] Dos sucursales distintas consultan cada una su propia bandeja; una tienda sin código configurado responde `409` en vez de usar otra sucursal.
  - [ ] Pedidos con despacho a domicilio nunca aparecen en esta bandeja.
  - [ ] Búsqueda por DNI filtra y resalta la tarjeta de la orden lista en menos de 300 ms.
  - [ ] Si la orden aún está en camino, el sistema impide iniciar el retiro y alerta al vendedor.

---

### <a id="rf-19"></a>RF-19: Registro de Confirmación de Entrega Física
* **Backend:**
  1. Expone `POST /api/v1/retail/pickup/{pedidoId}/entrega`:
     * Recibe `{ dniRecoge, nombreRecoge, esTerceroAutorizado, cartaPoderVerificada, codigoRetiro? }`.
     * Toma el vendedor (`sub` del JWT) y la tienda de su perfil local.
     * Valida `dniRecoge` de 8 dígitos y `nombreRecoge` no vacío.
     * Si recoge el titular, el DNI debe ser el del pedido (`422 DNI_NO_COINCIDE_CON_TITULAR`); si recoge un tercero, exige carta poder verificada (`422 CARTA_PODER_REQUERIDA`).
     * Si el pedido llegó sin DNI del titular, no hay identidad que verificar: la entrega como titular responde `422 DNI_TITULAR_NO_REGISTRADO` y solo puede recoger un tercero con carta poder.
     * Informa la entrega a Ventas (G5) con token de servicio de G7; Ventas pasa el pedido a `ENTREGADO`.
     * Retorna `200 OK` con constancia digital (timestamp y número de constancia).
* **Frontend:**
  1. Modal `DeliveryModal` con lista de prendas contenidas para verificación física.
  2. Selector de receptor:
     - *Titular:* autocompleta los nombres; el vendedor **digita el DNI del documento físico** (no se autocompleta). Si no coincide con el del pedido, avisa y bloquea el botón.
     - *Titular sin DNI en el pedido:* muestra un aviso y bloquea la entrega como titular; solo queda la opción de tercero autorizado.
     - *Tercero Autorizado:* limpia campos y exige digitar DNI (8 dígitos), nombres del receptor presencial y marcar la carta poder verificada.
  3. Checkbox obligatorio de verificación de buen estado y documento físico.
  4. Botón *"Confirmar y Registrar Entrega"* habilitado solo con checkbox marcado y datos válidos.
  5. Al responder 200 OK: cierra modal, muestra toast de éxito y retira la orden de la bandeja.
* **Criterios de Aceptación (RF-19):**
  - [ ] Retiro por titular autocompleta su nombre y exige digitar el DNI del documento, que debe coincidir con el del pedido.
  - [ ] Si el pedido no tiene DNI del titular, no se puede confirmar como titular con ningún DNI.
  - [ ] Retiro por tercero exige DNI de 8 dígitos, nombres de quien retira y carta poder verificada.
  - [ ] Checkbox de verificación física no marcado mantiene inactivo el botón de confirmación.
  - [ ] La confirmación retira el pedido de la bandeja activa y registra la constancia oficial.

---

## 6. Precondiciones y Dependencias
* Pedido en estado `LISTO_PARA_RECOJO` en la tienda física correspondiente.
