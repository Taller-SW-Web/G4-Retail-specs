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
Permitir al personal de mostrador visualizar la bandeja exclusiva de pedidos asignados para retiro en su tienda (`tiendaId`), validar que la orden esté efectivamente en estado `LISTO_PARA_RECOJO`, verificar la identidad del receptor (titular o tercero autorizado con DNI de 8 dígitos), confirmar el checklist físico de integridad de prendas y actualizar el estado oficial a `ENTREGADO_EN_TIENDA` emitiendo constancia digital.

---

## 3. ¿Hasta dónde? (Alcance)
* **Incluido:**
  * Bandeja de pedidos pendientes de entrega filtrados por la tienda física en sesión (`GET /api/v1/pickup/pendientes`).
  * Búsqueda ágil por código de pedido o DNI del titular dentro de la bandeja.
  * Modal de confirmación de entrega física (`POST /api/v1/pickup/confirmar`).
  * Discriminación de receptor: Titular (autocompletado) o Tercero Autorizado (captura de DNI y nombres).
  * Checkbox obligatorio de verificación física de bultos y prendas.
  * Remoción automática de la orden de la bandeja de pendientes y generación de constancia digital.
* **Excluido:**
  * Preparación y empaque en almacén logístico (módulo de Despacho y Entrega).
  * Cambios de talla o devoluciones posteriores (cubierto en F9).

---

## 4. Referencias y Contratos
* **Contrato de API:** [`specs/generales/api-contracts.md`](../generales/api-contracts.md) → `GET /api/v1/pickup`, `POST /api/v1/pickup/confirmar`
* **Design System:** [`specs/generales/design-system.md`](../generales/design-system.md)
* **Modelo de Base de Datos:** `RET_ORDENES`, `RET_DESPACHOS_PICKUP`

---

## 5. Requerimientos Funcionales Detallados

### <a id="rf-18"></a>RF-18: Verificación y Validación de Retiro en Tienda
* **Backend:**
  1. Expone `GET /api/v1/pickup/pendientes`:
     * Extrae `tiendaId` del token del vendedor.
     * Filtra órdenes con modalidad `RETIRO_EN_TIENDA`, asignadas a esa tienda y en estado `LISTO_PARA_RECOJO`.
     * Retorna lista de pedidos listos con cliente, prendas y ubicación física en tienda (ej. *Gaveta B-04*).
* **Frontend:**
  1. Pestaña *"Entregas en Tienda (Pickup)"* con contador de pendientes (ej. badge `5 pendientes`).
  2. Buscador reactivo por DNI o código de pedido (`pedidoId`).
  3. Tarjeta `PickupCard` con código, cliente, bultos, fecha y casillero de trastienda.
  4. Botón *"Procesar Retiro"* en cada tarjeta. Si el pedido pertenece a otra sede o está en camino, muestra aviso ámbar y bloquea la entrega.
* **Criterios de Aceptación (RF-18):**
  - [ ] La bandeja solo muestra pedidos asignados a la tienda del vendedor en sesión.
  - [ ] Pedidos con despacho a domicilio nunca aparecen en esta bandeja.
  - [ ] Búsqueda por DNI filtra y resalta la tarjeta de la orden lista en menos de 300 ms.
  - [ ] Si la orden aún está en camino, el sistema impide iniciar el retiro y alerta al vendedor.

---

### <a id="rf-19"></a>RF-19: Registro de Confirmación de Entrega Física
* **Backend:**
  1. Expone `POST /api/v1/pickup/confirmar`:
     * Recibe `{ pedidoId, dniRecoge, nombreRecoge, esTerceroAutorizado }`.
     * Inyecta `encargadoEntregaId` del vendedor y `tiendaId`.
     * Valida `dniRecoge` de 8 dígitos y `nombreRecoge` no vacío.
     * Actualiza el estado a `ENTREGADO_EN_TIENDA` y notifica a Despacho y Ventas (mock).
     * Retorna `200 OK` con constancia digital (timestamp y número de constancia).
* **Frontend:**
  1. Modal `DeliveryModal` con lista de prendas contenidas para verificación física.
  2. Selector de receptor:
     - *Titular:* autocompleta DNI y nombres del comprador.
     - *Tercero Autorizado:* limpia campos y exige digitar DNI (8 dígitos) y nombres del receptor presencial.
  3. Checkbox obligatorio de verificación de buen estado y documento físico.
  4. Botón *"Confirmar y Registrar Entrega"* habilitado solo con checkbox marcado y datos válidos.
  5. Al responder 200 OK: cierra modal, muestra toast de éxito y retira la orden de la bandeja.
* **Criterios de Aceptación (RF-19):**
  - [ ] Retiro por titular autocompleta sus datos registrados en la compra.
  - [ ] Retiro por tercero permite capturar DNI de 8 dígitos y nombres de quien retira.
  - [ ] Checkbox de verificación física no marcado mantiene inactivo el botón de confirmación.
  - [ ] La confirmación retira el pedido de la bandeja activa y registra la constancia oficial.

---

## 6. Precondiciones y Dependencias
* Pedido en estado `LISTO_PARA_RECOJO` en la tienda física correspondiente.
