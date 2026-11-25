# Spec — F6: Consulta y Seguimiento Histórico de Pedidos (v1.1)

### Responsable: Maylle (Arquitectura de Software) & Kevin (Frontend Lead)
### Requerimientos Funcionales Incluidos: RF-16, RF-17
### Prioridad: Should have

---

## 1. ¿Por qué? (Problema de Negocio)
Los clientes acuden al mostrador para consultar por compras realizadas en cualquier canal (Web, Chatbot o Retail físico) o en días anteriores:
1. Sin una herramienta rápida para buscar pedidos por código o DNI/RUC, el vendedor no puede brindar información certera al comprador.
2. Responder únicamente que la orden "está pendiente" genera desconfianza; el vendedor necesita ver la línea de tiempo exacta (si fue pagada, si el almacén la está preparando o si ya llegó a tienda para retiro).

---

## 2. ¿Para qué? (Objetivo)
Permitir al personal de mostrador buscar y listar órdenes de compra realizadas en cualquier canal comercial mediante código de pedido (`PED-YYYY-NNNNN`) o documento del comprador (DNI/RUC), visualizando el desglose de prendas y desplegando un componente interactivo de línea de tiempo (*Timeline / Stepper*) con el historial cronológico de estados oficiales de Ventas (`CREADO`, `PAGADO`, `EN_PREPARACION`, `DESPACHADO`, `ENTREGADO`, `ANULADO`).

---

## 3. ¿Hasta dónde? (Alcance)
* **Incluido:**
  * **Hito 4 / Semana 11:** búsqueda por código de orden, delegada a G5 mediante `GET /api/v1/pedidos/{pedidoId}` con `ventas:pedidos:consultar`.
  * Vista profunda de orden con prendas adquiridas, fotos, tallas y comprobantes asociados.
  * Línea de tiempo gráfica de estados con fechas/horas exactas (UTC-5 Lima).
  * Badges semánticos de estado (verde: entregado, azul: despachado / en camino, ámbar: en preparación, rojo: anulado).
* **Excluido:**
  * Entrega física en tienda con firma o código PIN (cubierto en F7 / Pickup con Despacho G2).
  * Anulaciones y devoluciones (cubierto en Postventa G5).

### 3.1. Pendiente para la planificación del siguiente hito — RF-16-DOC

**Decisión del PO (06/11/2026):** diferir la búsqueda histórica por DNI/RUC y su lista cronológica de pedidos al siguiente hito. RF-16 conserva este requisito pendiente; entregar la consulta por código no completa la búsqueda por documento.

**Motivo y fuente:** G5 confirmó al PO que `GET /api/v1/pedidos?buscar={DNI_o_RUC}` encuentra pedidos de cualquier canal y estado, incluido `ENTREGADO`, pero el acuerdo de privacidad A10 con Seguridad restringe ese listado a `ADMIN_VENTAS`. Los tokens de servicio de canal, incluido `modulo-retail`, no tienen acceso. El scope `ventas:pedidos:consultar` permite consultar un pedido por código y la bandeja Pickup, pero no habilita ese listado general.

**Alcance vigente:** consulta por código y trazabilidad (RF-17). El filtro local por DNI de F7 solo busca dentro de los recojos pendientes de la tienda y no sustituye el historial multicanal del cliente.

**Responsable de retomar:** Mihael (PO), con G5 y el equipo de F6. Antes de implementar RF-16-DOC:

- [ ] Incluir RF-16-DOC expresamente en la planificación del siguiente hito.
- [ ] Acordar con G5 el acceso permitido para Retail bajo A10: canales y estados visibles, datos devueltos y límites de consulta.
- [ ] Registrar la ruta, parámetros, respuestas y autorización acordados en [§5.6 del contrato de API](../generales/api-contracts.md#56-f6--consulta-de-pedidos). Si el acuerdo requiere un permiso nuevo, coordinar su emisión con G7; no solicitar `ADMIN_VENTAS` para el cliente de Retail.
- [ ] Implementar y probar los criterios de búsqueda por documento de RF-16, junto con los casos de autorización y límites que se acuerden. No usar el listado general restringido mientras no exista ese acuerdo.

---

## 4. Referencias y Contratos
* **Contrato de API:** [`specs/generales/api-contracts.md`](../generales/api-contracts.md#56-f6--consulta-de-pedidos) → rutas propias `/api/v1/retail/pedidos` y `/api/v1/retail/pedidos/{pedidoId}`; alcance por hito según §3.1.
* **Design System:** [`specs/generales/design-system.md`](../generales/design-system.md)
* **Modelo de Base de Datos:** consulta delegada a G5; en el hito actual se usa `GET /api/v1/pedidos/{pedidoId}`.

---

## 5. Requerimientos Funcionales Detallados

### <a id="rf-16"></a>RF-16: Búsqueda Histórica de Órdenes de Clientes
* **Backend:**
  1. Expone `GET /api/v1/retail/pedidos?codigoPedido=` y `GET /api/v1/retail/pedidos/{pedidoId}` en el hito actual. El filtro `documentoCliente` queda pendiente para RF-16-DOC (§3.1):
     * Exige `codigoPedido` en la consulta del hito actual; la consulta directa recibe `pedidoId` en la ruta.
     * Consume el detalle de *Ventas y Postventa (G5)* por código, sin llamar al listado general restringido por A10.
     * **Siguiente hito (RF-16-DOC):** retorna las órdenes permitidas por documento, de la más reciente a la más antigua.
     * Si no existen registros, responde `404 Not Found` (`PEDIDO_NO_ENCONTRADO`).
* **Frontend:**
  1. Vista en `/pedidos` con buscador por código. El selector *"Por DNI/RUC"* queda para RF-16-DOC (§3.1).
  2. Si busca por código exacto y existe: abre de inmediato el detalle de la orden.
  3. **Siguiente hito (RF-16-DOC):** si busca por DNI/RUC, muestra tabla de compras históricas del cliente con N° Pedido, Fecha, Canal, Total y Estado, dentro del acceso que se acuerde con G5.
  4. Botón *"Ver Detalle"* en cada fila para cargar la trazabilidad profunda.
* **Criterios de Aceptación (RF-16):**
  - [ ] Búsqueda por código existente retorna 200 OK y carga la orden en < 1 segundo.
  - [ ] **Siguiente hito (RF-16-DOC):** búsqueda por DNI/RUC de cliente con múltiples pedidos lista las órdenes ordenadas cronológicamente, dentro del acceso acordado con G5.
  - [ ] Búsqueda de código erróneo responde 404 y muestra `EmptyState` sin romper la pantalla.

---

### <a id="rf-17"></a>RF-17: Visualización de Estados y Trazabilidad del Pedido
* **Backend:**
  1. Compila el array `historialEstados` asegurando orden cronológico ascendente.
  2. Normaliza timestamps a huso horario de Perú (UTC-5).
  3. Devuelve detalle de prendas: SKU, nombre, talla, color, cantidad y precio.
* **Frontend:**
  1. Cabecera con código de pedido monoespaciado, canal de procedencia y badge de estado coloreado.
  2. Componente de Línea de Tiempo (*Timeline Stepper*):
     - Nodos completados con línea continua iluminada y check verde.
     - Nodo en curso resaltado en azul o ámbar.
     - Si la orden fue anulada: interrupción de la línea con nodo rojo de cancelación.
  3. Tabla desglosada de prendas con fotos miniaturas, variantes y subtotales.
* **Criterios de Aceptación (RF-17):**
  - [ ] La línea de tiempo refleja cada cambio de estado con fecha y hora legibles.
  - [ ] El badge de estado adopta el color semántico correspondiente según el Design System.
  - [ ] Los pedidos con modalidad Pickup muestran la tienda física y aviso de recojo disponible.

---

## 6. Precondiciones y Dependencias
* Vendedor autenticado en terminal Retail.
