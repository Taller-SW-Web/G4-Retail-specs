# Spec — RF-11: Aplicación Dinámica de Descuentos y Promociones (v0.1)

### Responsable: Mihael (Product Owner)
### Requerimiento Funcional: RF-11: Aplicación Dinámica de Descuentos y Promociones
### Funcionalidad Padre: F4: Registro de Venta Asistida y Aplicación de Ofertas/Promociones
### Prioridad: Must have (Crítico)

---

## ¿Por qué? (problema)
Las tiendas deportivas manejan campañas promocionales frecuentes (ej. 2x1 en camisetas, 20% en zapatillas de running o cupones de temporada de verano). Si el vendedor debe calcular estos descuentos a mano o con calculadora, se cometen errores de cobro, diferencias respecto a los precios de la tienda online o pérdidas económicas por descuentos mal aplicados.

## ¿Para qué? (objetivo)
Evaluar en tiempo real el contenido del carrito de compras contra el motor comercial de *Productos y Ofertas*, aplicando de forma transparente las promociones automáticas vigentes y permitiendo al vendedor ingresar cupones de descuento promocionales, mostrando claramente el beneficio obtenido.

## ¿Hasta dónde? (alcance)
* **Incluido:** Campo de texto para cupón de descuento en el carrito POS, consumo del endpoint de evaluación `POST /api/v1/ofertas/evaluar-carrito`, aplicación de descuentos automáticos por categoría/volumen, feedback visual por cada ítem beneficiado y desglose del descuento global aplicado.
* **Excluido:** Gestión manual del carrito de compras (cubierto en RF-10), cálculo de la base imponible e IGV del comprobante (cubierto en RF-12), y creación o edición de reglas de descuento (administradas centralmente por *Productos y Ofertas*).

## Referencias
* **Contrato:** [api-contracts.md](./api-contracts.md) — `POST /api/v1/ofertas/evaluar-carrito` (Sección 2)
* **Modelo:** `EvaluacionOfertaRequest` (`tiendaId`, `cupon`, `items`: `[{sku, cantidad, precioUnitario}]`), `EvaluacionOfertaResponse` (`subtotal`, `descuentoTotal`, `total`, `detalles`: `[{sku, descuento, promocionAplicada}]`)

## ¿Qué debe hacer? (comportamiento)

### Backend (Retail / Intermediario con Ofertas)
1. Expone `POST /api/v1/retail/carrito/evaluar`:
   * Recibe la lista de SKUs, cantidades, precios unitarios y el código de cupón opcional.
   * Inyecta el `tiendaId` del vendedor autenticado.
2. Invoca al microservicio de *Productos y Ofertas* (`POST /api/v1/ofertas/evaluar-carrito`).
3. Si el microservicio responde `200 OK`:
   * Devuelve el monto total de descuento calculado y el detalle de qué promoción aplicó a cada ítem.
4. Si el cupón ingresado no existe, está vencido o no aplica a los productos seleccionados:
   * Retorna advertencia descriptiva (ej. `"Cupón no válido o vencido"`), pero devuelve el carrito calculado a precio regular sin bloquear la compra.

### Frontend
1. Muestra un bloque en el carrito POS: *"Promociones y Cupones"*:
   * Campo de texto en mayúsculas: `"Ingresar Cupón de Descuento"` con botón *"Aplicar"*.
2. Al ingresar un cupón y pulsar *"Aplicar"*:
   * Muestra estado de carga breve.
   * Si es válido:
     * Muestra badge verde: *"Cupón VERANO2026 aplicado (-10%)"*.
     * Botón para remover el cupón si el cliente desea cambiarlo.
   * Si es inválido:
     * Muestra texto rojo de advertencia: *"El cupón ingresado no es válido o ha expirado"*.
3. En cada ítem del carrito beneficiado por una oferta:
   * Muestra el precio regular tachado (ej. `~~S/ 129.90~~`).
   * Muestra el precio con descuento en color verde (ej. `S/ 116.91`).
   * Etiqueta descriptiva de la promoción (ej. *"10% OFF Temporada"*).
4. El resumen del carrito refleja una línea destacada en verde: *"Descuento Total Promociones: - S/ XX.XX"*.

## ¿Cómo verificamos? (criterios de aceptación)
- [ ] Carrito con productos en promoción automática → Muestra el descuento aplicado sin necesidad de escribir ningún cupón.
- [ ] Ingreso de cupón vigente `VERANO2026` → Aplica el 10% de descuento sobre los productos aplicables y actualiza los totales.
- [ ] Ingreso de cupón falso o expirado `FALSO123` → Muestra mensaje de error y mantiene los precios normales sin alterar el carrito.
- [ ] Remover el cupón aplicado → Restablece el valor de descuento del cupón y recalcula los totales inmediatamente.
- [ ] Modificar cantidades de un producto en el carrito recalcula automáticamente las promociones por volumen.

## ¿Con qué condiciones? (precondiciones y dependencias)
* El microservicio de *Productos y Ofertas* debe tener activo el motor de reglas de ofertas.
* Regla de Negocio RN-04: El vendedor no puede ingresar descuentos discrecionales directos; todo descuento debe provenir del motor oficial.
* Regla de negocio: El total final tras descuentos nunca puede ser menor o igual a cero.

## ¿Qué NO hará? (fuera de alcance)
* No creará nuevas campañas ni configurará porcentajes de descuento desde la pantalla de caja.
