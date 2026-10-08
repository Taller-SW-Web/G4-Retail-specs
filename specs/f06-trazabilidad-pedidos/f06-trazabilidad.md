# Spec — F6: Consulta y Seguimiento Histórico de Pedidos (v1.0)

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
Permitir al personal de mostrador buscar y listar órdenes de compra realizadas en cualquier canal comercial mediante código de pedido o documento del comprador (DNI/RUC), visualizando el desglose de prendas y desplegando un componente interactivo de línea de tiempo (*Timeline / Stepper*) con el historial cronológico de estados (`REGISTRADO`, `PAGADO`, `EN_PREPARACION`, `LISTO_PARA_RECOJO`, `ENTREGADO`, `ANULADO`).

---

## 3. ¿Hasta dónde? (Alcance)
* **Incluido:**
  * Búsqueda por código de orden o documento de identidad (`GET /api/v1/pedidos`).
  * Lista cronológica descendente de órdenes históricas del cliente.
  * Vista profunda de orden con prendas adquiridas, fotos, tallas y comprobantes asociados.
  * Línea de tiempo gráfica de estados con fechas/horas exactas (UTC-5 Lima).
  * Badges semánticos de estado (verde: entregado, azul: listo para recojo, ámbar: en preparación, rojo: anulado).
* **Excluido:**
  * Entrega física en tienda con firma o código PIN (cubierto en F7 / Pickup).
  * Anulaciones y devoluciones (cubierto en Postventa G5).

---

## 4. Referencias y Contratos
* **Contrato de API:** [`specs/generales/api-contracts.md`](../generales/api-contracts.md) → `GET /api/v1/pedidos`, `GET /api/v1/pedidos/{id}`
* **Design System:** [`specs/generales/design-system.md`](../generales/design-system.md)
* **Modelo de Base de Datos:** `RET_ORDENES`, `RET_ORDEN_HISTORIAL`

---

## 5. Requerimientos Funcionales Detallados

### <a id="rf-16"></a>RF-16: Búsqueda Histórica de Órdenes de Clientes
* **Backend:**
  1. Expone `GET /api/v1/pedidos?codigoPedido=&documentoCliente=`:
     * Valida que al menos uno de los dos filtros esté presente.
     * Consulta `RET_ORDENES` y cruza con *Ventas y Postventa* (o mock controlado).
     * Retorna órdenes ordenadas de la más reciente a la más antigua.
     * Si no existen registros, responde `404 Not Found` (`PEDIDO_NO_ENCONTRADO`).
* **Frontend:**
  1. Vista en `/pedidos` con buscador superior y selector de criterio: *"Por Código de Pedido"* / *"Por DNI/RUC"*.
  2. Si busca por código exacto y existe: abre de inmediato el detalle de la orden.
  3. Si busca por DNI: muestra tabla de compras históricas del cliente con N° Pedido, Fecha, Canal, Total y Estado.
  4. Botón *"Ver Detalle"* en cada fila para cargar la trazabilidad profunda.
* **Criterios de Aceptación (RF-16):**
  - [ ] Búsqueda por código existente retorna 200 OK y carga la orden en < 1 segundo.
  - [ ] Búsqueda por DNI de cliente con múltiples pedidos lista las órdenes ordenadas cronológicamente.
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
