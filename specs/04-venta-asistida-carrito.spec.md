# Spec — Registro de Venta Asistida y Aplicación de Promociones (v0.1)

### Responsable: Mihael (Product Owner)
### Requerimientos Funcionales asociados: RF-10, RF-11, RF-12

---

## ¿Por qué? (problema)
El armado de una orden en mostrador requiere calcular de forma exacta y transparente el total a pagar, aplicando las ofertas por temporada (descuentos en camisetas o packs deportivos) y cupones vigentes sin inconsistencias entre la tienda física y los canales digitales. Calcular promociones manualmente genera pérdidas por errores humanos y retardo en caja.

## ¿Para qué? (objetivo)
Permitir al vendedor armar y gestionar el carrito de venta asistida en la terminal POS, controlando cantidades según stock en tienda y evaluando en tiempo real con el motor de *Productos y Ofertas* los descuentos automáticos, cupones y el desglose de impuestos (IGV).

## ¿Hasta dónde? (alcance)
* **Incluido:** Gestión del carrito en memoria/estado de frontend (agregar, modificar cantidad, eliminar ítem, limpiar carrito), control de tope por stock local, ingreso de cupones de descuento, consulta al motor de ofertas y cálculo en tiempo real de Subtotal, Descuento Total, IGV (18%) e Importe Neto.
* **Excluido:** Creación o modificación de reglas de descuento (administradas por el gestor comercial en *Productos y Ofertas*) y persistencia final de la orden de venta (se realiza en el paso de cobro).

## Referencias
* **Contrato:** [specs/api-contracts.md](file:///c:/Users/Mihae/Programacion/Activos/modulo-retail/specs/api-contracts.md) — `POST /api/v1/ofertas/evaluar-carrito`
* **Modelo:** `CarritoItem` (`sku`, `nombre`, `talla`, `color`, `cantidad`, `precioUnitario`, `descuentoAplicado`, `subtotal`), `ResumenTotales` (`subtotalBruto`, `descuentoTotal`, `igv`, `totalPagar`)

## ¿Qué debe hacer? (comportamiento)

### Backend (Retail / Evaluación de Promociones)
1. Expone `POST /api/v1/retail/carrito/evaluar` que recibe la lista de SKUs, cantidades y cupón opcional.
2. Invoca al microservicio de *Productos y Ofertas* (`POST /api/v1/ofertas/evaluar-carrito`).
3. Aplica las reglas fiscales de Perú:
   * `totalPagar = subtotalBruto - descuentoTotal`
   * `subtotalSinIgv = totalPagar / 1.18`
   * `igv = totalPagar - subtotalSinIgv` (IGV 18% incluido en precio de venta comercial).
4. Devuelve el desglose detallado por ítem y los totales recalculados.
5. Si un cupón ingresado no existe o expiró, devuelve advertencia con el carrito calculado a precio regular sin bloquear la venta.

### Frontend
1. Panel lateral permanente del Carrito POS en la interfaz de mostrador.
2. Cada ítem en el carrito muestra: miniatura, nombre, variante (talla/color), precio unitario, selector de cantidad (+ / - / input numérico), subtotal y botón de eliminar (ícono de tacho).
3. Control estricto de cantidad: El botón "+" o la edición numérica se bloquea cuando la cantidad alcanza el `stockTienda` disponible del producto.
4. Campo para ingresar "Cupón de Descuento" con botón "Aplicar".
5. Bloque de resumen financiero siempre visible:
   * Subtotal Bruto: `S/ XXX.XX`
   * Descuentos Aplicados: `- S/ XX.XX` (resaltado en verde)
   * IGV Incluido (18%): `S/ XX.XX`
   * **Total a Pagar:** `S/ XXX.XX`
6. Botón principal: *"Proceder al Cobro"* (habilitado solo si el carrito tiene al menos 1 ítem y un cliente asociado).

## ¿Cómo verificamos? (criterios de aceptación)
- [ ] Agregar un producto incrementa la cantidad y actualiza los totales en tiempo real.
- [ ] Si se intenta seleccionar una cantidad superior al stock físico en tienda, el sistema no lo permite y muestra alerta *"Stock máximo alcanzado en tienda"*.
- [ ] Modificar la cantidad de un ítem a cero elimina automáticamente el ítem del carrito tras confirmación.
- [ ] Aplicar cupón válido reduce el total y muestra el concepto del descuento aplicado.
- [ ] Aplicar cupón inválido o expirado muestra mensaje *"Cupón no válido o expirado"* y mantiene los precios regulares sin afectar el carrito.
- [ ] El desglose de IGV y totales coincide al centavo con el cálculo matemático oficial.
- [ ] El botón "Proceder al Cobro" permanece inhabilitado si el carrito está vacío.

## ¿Con qué condiciones? (precondiciones y dependencias)
* Depende de que *Productos y Ofertas* tenga activo el endpoint de evaluación de reglas de descuento.
* El carrito se mantiene persistido en el estado local del navegador del vendedor para evitar pérdida accidental de datos ante refresco de pantalla.
* Regla de negocio: Ninguna promoción puede arrojar un precio final menor o igual a cero.

## ¿Qué NO hará? (fuera de alcance)
* No permite al vendedor modificar manualmente el precio de venta ni aplicar descuentos discrecionales no autorizados por el motor de ofertas.
* No reserva stock en la base de datos hasta el momento efectivo del cobro.
