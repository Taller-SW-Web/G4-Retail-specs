# Spec — F11: Alertas Operativas y Notificaciones en Tienda (v1.0)

### Responsable: Mihael (Product Owner) & Guillermo (QA)
### Requerimientos Funcionales Incluidos: RF-29, RF-30, RF-31
### Prioridad: Could have

---

## 1. ¿Por qué? (Problema de Negocio)
En la rutina operativa de tienda física:
1. En artículos de alta rotación (calzado y camisetas), las tallas populares se agotan rápidamente. Si el vendedor no tiene alertas de stock crítico (< 2 unidades) o quiebre local (0 unidades), promete prendas que luego no encuentra en almacén.
2. Los clientes de Click & Collect esperan entregas en < 1 minuto; sin una bandeja proactiva que indique qué paquetes llegaron hoy y en qué anaquel físico se encuentran, el vendedor pierde tiempo buscando a ciegas.
3. Si el vendedor no tiene en pantalla las promociones y cupones vigentes del día, pierde oportunidades de asesoría comercial (*up-selling/cross-selling*).

---

## 2. ¿Para qué? (Objetivo)
Centralizar en la terminal POS una **Torre de Control Operativa de Turno**: proveyendo un widget de alertas de stock crítico de tienda (con consulta al almacén central si está agotado localmente), un tablero visual de bultos Pickup arribados hoy con su anaquel físico, y un tablón/banner de promociones y combos comerciales del día con inyección de cupones al carrito en 1 clic.

---

## 3. ¿Hasta dónde? (Alcance)
* **Incluido:**
  * Widget colapsable de stock crítico (`stockTienda <= 2`) y quiebres (0 unidades) con visualización de existencias en almacén central.
  * Bandeja de pedidos Pickup del día con código, cliente y anaquel físico de trastienda (`📍 Anaquel A-12`).
  * Tablón de campañas vigentes del canal Retail con chip de cupones y botón de copiado/inyección directa al carrito.
  * Centro de notificaciones en campana de `AppHeader` con badge numérico.
* **Excluido:**
  * Generación de órdenes de compra a fábricas o transferencias inter-sucursales.
  * Creación o edición de reglas de precios comerciales.

---

## 4. Referencias y Contratos
* **Contrato de API:** [`specs/generales/api-contracts.md`](../generales/api-contracts.md) → `GET /api/v1/alertas`
* **Design System:** [`specs/generales/design-system.md`](../generales/design-system.md)
* **Modelo de Base de Datos:** `RET_CATALOGO_CACHE`, `RET_DESPACHOS_PICKUP`

---

## 5. Requerimientos Funcionales Detallados

### <a id="rf-29"></a>RF-29: Panel de Alertas de Stock Crítico y Quiebre en Tienda
* **Backend:**
  1. Expone `GET /api/v1/retail/control/stock-critico`:
     * Extrae `tiendaId` del vendedor.
     * Consulta prendas con existencias locales `<= 2`.
     * Clasifica en `AGOTADO` (0) o `CRITICO` (1-2) y cruza existencias en almacén central.
* **Frontend:**
  1. Widget *"Semáforo de Stock de Tienda"* con badge en cabecera.
  2. Tarjetas compactas con foto, nombre, SKU y semáforo (rojo parpadeante: agotado; ámbar: últimas unidades).
  3. Muestra existencias en almacén central (ej. *"Central: 45 disponibles"*) y botón para consultar otras sedes.
* **Criterios de Aceptación (RF-29):**
  - [ ] Variante con stock local <= 2 aparece en el panel con semáforo ámbar.
  - [ ] Variante con stock 0 local cambia a semáforo rojo "Agotado en tienda".
  - [ ] El widget indica existencias en almacén central para orientar venta asistida.

---

### <a id="rf-30"></a>RF-30: Bandeja de Pedidos Pick-Up del Día en Tienda
* **Backend:**
  1. Expone `GET /api/v1/retail/control/pickup-pendientes`:
     * Filtra bultos en `LISTO_PARA_RECOJO` arribados a la tienda del operador.
     * Retorna lista ordenada por fecha de arribo más reciente.
* **Frontend:**
  1. Pestaña *"Retiro en Tienda / Pick-Up"* con contador de paquetes pendientes.
  2. Tarjetas visuales destacando: nombre del cliente, DNI, código de orden y ubicación en tienda (`📍 Anaquel B-04`).
  3. Botón verde *"Entregar Paquete"* que transiciona al modal formal de verificación física (RF-18 / RF-19).
* **Criterios de Aceptación (RF-30):**
  - [ ] La bandeja lista los paquetes web arribados a esa tienda física.
  - [ ] Muestra el anaquel físico para rápida localización del bulto.
  - [ ] Filtrar por DNI aísla la tarjeta del cliente en mostrador de inmediato.

---

### <a id="rf-31"></a>RF-31: Tablón Informativo de Campañas y Promociones Vigentes
* **Backend:**
  1. Expone `GET /api/v1/retail/control/campanas-vigentes`:
     * Consulta promociones activas para el canal `RETAIL` dentro de su fecha de vigencia.
     * Cachea resultados con TTL de 15 minutos.
* **Frontend:**
  1. Tira horizontal superior en el POS (*"Promociones del Día en Mostrador"*).
  2. Chips con iconos llamativos (ej. `🏷️ 2x1 Medias`, `⚡ 30% Chimpunes con Cupón GOAL2026`).
  3. Clic en el chip inyecta automáticamente el cupón en el Carrito POS (RF-11).
  4. Clic en *"Ver Condiciones"* despliega popover con restricciones y monto mínimo.
* **Criterios de Aceptación (RF-31):**
  - [ ] Barra superior despliega las campañas activas para Retail.
  - [ ] Clic en campaña con cupón rellena automáticamente el campo del carrito POS.
  - [ ] Campañas expiradas no aparecen en el tablón de mostrador.

---

## 6. Precondiciones y Dependencias
* Conexión con *Productos y Ofertas* y *Despacho y Entrega*.
