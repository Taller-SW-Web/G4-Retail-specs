# Spec — F4: Gestión del Carrito de Compras en Mostrador (v1.0)

### Responsable: Mihael (Product Owner) & Kevin (Frontend Lead)
### Requerimientos Funcionales Incluidos: RF-10, RF-11, RF-12
### Prioridad: Must have (Crítico para Hito 3)

---

## 1. ¿Por qué? (Problema de Negocio)
Durante la venta asistida en tienda:
1. El cliente agrega prendas, pide cambiar tallas/cantidades o retirar artículos antes de pagar. Si el carrito no es reactivo o no valida los topes de stock local físico, se generan descuadres de inventario.
2. Si el cliente olvida su billetera o se dirige al probador, el cajero debe poder poner la venta en espera (*Held Cart*) para no bloquear la fila.
3. El cálculo de descuentos y promociones no puede hacerse manualmente porque genera errores de cobro.
4. Bajo la legislación fiscal peruana (SUNAT), es obligatorio desglosar con precisión de centavos: Subtotal, Descuentos, Base Imponible (Operación Gravada), IGV (18%) y Total a Pagar.

---

## 2. ¿Para qué? (Objetivo)
Gestionar de forma reactiva la orden en mostrador mediante un panel lateral permanente de carrito POS: agregar variantes por SKU, incrementar/decrementar cantidades con validación estricta contra `stockTienda`, pausar ventas en espera (*Parked Sales*), evaluar promociones automáticas y cupones comerciales en tiempo real, calcular el desglose tributario de IGV (18%) con redondeo bancario a 2 decimales y controlar la activación del botón de cobro.

---

## 3. ¿Hasta dónde? (Alcance)
* **Incluido:**
  * Panel lateral derecho de carrito POS en `/pos`.
  * Incremento/decremento de unidades con tope en existencias físicas locales.
  * Eliminación individual de líneas y vaciado de carrito con confirmación.
  * Funcionalidad de *Carritos en Espera* (pausar venta con alias descriptivo y reanudarla en 1 clic).
  * Evaluación de promociones automáticas y cupones de descuento (`POST /api/v1/ordenes/calcular`).
  * Cálculo financiero oficial según fórmula SUNAT (Subtotal, Descuento, Base Imponible, IGV 18%, Total).
  * Persistencia del carrito en `localStorage` ante recargas involuntarias de pestaña.
* **Excluido:**
  * Cobro monetario y cierre de orden (responsabilidad de F5 / RF-13 y RF-14).
  * Creación o edición de reglas de cupones (responsabilidad de *Productos y Ofertas* G6).

---

## 4. Referencias y Contratos
* **Contrato de API:** [`specs/generales/api-contracts.md`](../generales/api-contracts.md) → `POST /api/v1/ordenes/calcular`
* **Design System:** [`specs/generales/design-system.md`](../generales/design-system.md)
* **Modelo de Base de Datos:** `RET_ORDENES_TEMPORALES`, `RET_PROMOCIONES`

---

## 5. Requerimientos Funcionales Detallados

### <a id="rf-10"></a>RF-10: Gestión del Carrito POS en Mostrador
* **Backend:**
  1. Valida que los ítems contengan `sku` válido y `cantidad > 0`.
  2. Expone endpoints de persistencia de ventas pausadas si se requiere sincronización en nube.
* **Frontend:**
  1. Panel lateral derecho (`CartPanel`) con contador de artículos totales (ej. *"3 prendas"*).
  2. Al agregar una variante:
     * Si no existe en el carrito: la añade con `cantidad = 1`.
     * Si ya existe: incrementa `cantidad + 1`, siempre que no exceda `stockTienda`.
  3. Controles por cada ítem (`CartLine`):
     * Miniatura, nombre del producto, talla y color.
     * Precio unitario de lista.
     * Stepper de cantidad: botón `-`, input editable y botón `+`.
     * Si la cantidad alcanza `stockTienda`, el botón `+` se deshabilita con tooltip de stock máximo.
     * Ícono de papelera para remover la prenda.
  4. Suspensión de Venta (*Carritos en Espera - Probadores*):
     * Botón *"Pausar Venta"*: modal para ingresar alias (ej. *"Probador 3 - Zapatillas"*).
     * Guarda el carrito en la bandeja de suspendidos y limpia el mostrador.
     * Botón *"Ventas en Espera (N)"*: lista carritos pausados con botón *"Reanudar"* para cargarlos en 1 clic.
  5. Botón *"Vaciar Carrito"* con modal de confirmación.
  6. Persistencia en `localStorage` para evitar pérdidas ante recarga de página.
* **Criterios de Aceptación (RF-10):**
  - [ ] Agregar un producto nuevo lo lista con cantidad 1 y subtotal correcto.
  - [ ] No permite incrementar unidades por encima del `stockTienda` disponible.
  - [ ] Pausar venta limpia el mostrador y permite recuperarla íntegra desde la bandeja de suspendidos.
  - [ ] Recargar la página (F5) preserva los artículos y cantidades del carrito.

---

### <a id="rf-11"></a>RF-11: Aplicación Dinámica de Descuentos y Promociones
* **Backend:**
  1. Valida la lista de ítems contra el motor de ofertas y el cupón ingresado.
  2. Retorna el monto total de descuento calculado y el desglose de qué beneficio aplica a cada SKU.
  3. Si el cupón es inválido o vencido, devuelve advertencia descriptiva sin bloquear la compra.
* **Frontend:**
  1. Bloque *"Promociones y Cupones"* en el carrito con campo de texto en mayúsculas y botón *"Aplicar"*.
  2. Al validar un cupón vigente:
     * Muestra badge verde: *"Cupón VERANO2026 aplicado (-10%)"* y botón para removerlo.
     * En cada ítem beneficiado: tacha el precio regular (`~~S/ 129.90~~`) y muestra el precio rebajado (`S/ 116.91`).
  3. Si el cupón no es válido: muestra texto rojo *"Cupón no válido o vencido"* sin alterar los ítems.
  4. Resumen financiero muestra línea en verde: *"Descuento Total: - S/ XX.XX"*.
* **Criterios de Aceptación (RF-11):**
  - [ ] Productos en promoción automática aplican el descuento sin requerir cupón.
  - [ ] Ingreso de cupón válido descuenta el porcentaje/monto correspondiente de los productos aplicables.
  - [ ] Cupón falso o vencido muestra alerta de error y mantiene los precios normales.
  - [ ] Remover el cupón restablece los precios inmediatamente.

---

### <a id="rf-12"></a>RF-12: Cálculo Consolidado de Totales e Impuestos
* **Backend:**
  1. Aplica la fórmula canónica de impuestos SUNAT:
     * `subtotalBruto = Σ (cantidad_i * precioUnitario_i)`
     * `totalPagar = subtotalBruto - descuentoTotal`
     * `baseImponible = totalPagar / 1.18` (redondeo a 2 decimales: `Math.round(base * 100) / 100`)
     * `montoIgv = totalPagar - baseImponible`
  2. Valida que `totalPagar > 0` y que `baseImponible + montoIgv == totalPagar`.
* **Frontend:**
  1. Resumen financiero permanente en el pie del carrito (`TotalsPanel`):
     * Subtotal Bruto (`S/ 0.00`)
     * Descuentos Aplicados (`- S/ 0.00` en verde)
     * Base Gravada (`S/ 0.00`)
     * IGV Incluido (18%) (`S/ 0.00`)
     * **TOTAL A PAGAR:** destacado en Oswald `text-3xl font-bold`
  2. Botón principal *"Proceder al Cobro (F5)"*:
     * Habilitado únicamente si: `items.length > 0`, `totalPagar > 0` y cliente asociado.
     * Si el carrito está vacío o falta cliente, se muestra inhabilitado con texto orientativo.
* **Criterios de Aceptación (RF-12):**
  - [ ] Los cálculos matemáticos cumplen exactamente `Total = Subtotal - Descuentos` y desglose de IGV.
  - [ ] Formato monetario estricto en Soles con 2 decimales (`S/ XX.XX`).
  - [ ] El botón de cobro permanece deshabilitado si el carrito tiene 0 ítems.

---

## 6. Precondiciones y Dependencias
* Precios de productos configurados en moneda nacional (PEN).
