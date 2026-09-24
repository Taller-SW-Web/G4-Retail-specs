# Spec — RF-12: Cálculo Consolidado de Totales e Impuestos (v0.1)

### Responsable: Mihael (Product Owner)
### Requerimiento Funcional: RF-12: Cálculo Consolidado de Totales e Impuestos
### Funcionalidad Padre: F4: Registro de Venta Asistida y Aplicación de Ofertas/Promociones
### Prioridad: Must have (Crítico)

---

## ¿Por qué? (problema)
En las operaciones comerciales bajo la legislación fiscal peruana (SUNAT), los precios al consumidor en mostrador incluyen el Impuesto General a las Ventas (IGV 18%). Sin embargo, para efectos contables y de facturación electrónica, es obligatorio desglosar con precisión de centavos el Subtotal Bruto, el Descuento Total, el Valor Venta Neto sin IGV, el Monto del IGV y el Total Final a Pagar. Un cálculo impreciso o con redondeos inconsistentes genera contingencias tributarias y bloquea el botón de cobro.

## ¿Para qué? (objetivo)
Calcular y presentar en tiempo real el balance financiero completo y consolidado de la orden en mostrador: Subtotal Bruto, Total de Descuentos, Base Imponible (Operación Gravada), IGV (18%) e Importe Neto Total a Pagar, aplicando las reglas de redondeo comercial bancario a 2 decimales y habilitando la transición al flujo de cobro.

## ¿Hasta dónde? (alcance)
* **Incluido:** Panel resumen financiero en la parte inferior del carrito POS, fórmulas matemáticas de desglose tributario según normativa peruana, formateo monetario en Soles peruanos (`S/ 0.00`), validación de totales no negativos, y control de activación del botón *"Proceder al Cobro"*.
* **Excluido:** Selección de medio de pago y registro de dinero en efectivo/tarjeta (cubierto en RF-13), y timbrado e impresión fiscal del comprobante (cubierto en RF-15).

## Referencias
* **Contrato:** [api-contracts.md](./api-contracts.md) — `POST /api/v1/ofertas/evaluar-carrito` y `POST /api/v1/ordenes/presenciales`
* **Modelo:** `ResumenFinanciero` (`subtotalBruto`: `number`, `descuentoTotal`: `number`, `baseImponible`: `number`, `montoIgv`: `number`, `totalPagar`: `number`)

## ¿Qué debe hacer? (comportamiento)

### Backend (Retail / Motor de Totales)
1. Provee el cálculo canónico de totales fiscales según la fórmula SUNAT:
   * `subtotalBruto = Σ (cantidad_i * precioUnitario_i)`
   * `totalPagar = subtotalBruto - descuentoTotal`
   * `baseImponible = totalPagar / 1.18` (redondeado a 2 decimales: `Math.round(base * 100) / 100`)
   * `montoIgv = totalPagar - baseImponible`
2. Valida que:
   * `totalPagar > 0` (no permite ventas con importe total cero o negativo).
   * La suma de `baseImponible + montoIgv` sea exactamente idéntica a `totalPagar`.
3. Retorna la estructura de `ResumenFinanciero` para ser persistida en la orden oficial.

### Frontend
1. Panel permanente en la parte inferior del Carrito POS:
   ```text
   ┌──────────────────────────────────────────────┐
   │ Subtotal Bruto:                    S/ 259.80 │
   │ Descuentos Aplicados:            - S/  25.98 │
   │ Base Gravada:                      S/ 198.15 │
   │ IGV Incluido (18%):                S/  35.67 │
   │ ──────────────────────────────────────────── │
   │ TOTAL A PAGAR:                     S/ 233.82 │
   └──────────────────────────────────────────────┘
   ```
2. Formato visual:
   * Moneda fija en Soles (`S/`) con exactamente dos decimales en todos los renglones.
   * El descuento total se destaca con color verde y signo negativo.
   * El total final a pagar se muestra con tipografía de mayor tamaño y negrita.
3. Botón de transición de flujo:
   * Botón principal *"Proceder al Cobro"* (color azul o verde prominente).
   * **Reglas de habilitación del botón:**
     * El carrito debe tener al menos 1 ítem (`items.length > 0`).
     * Debe existir un cliente identificado o asociado (cumpliendo RF-07 o RF-08).
     * `totalPagar` debe ser estrictamente mayor a 0.
   * Si no cumple los requisitos, el botón se muestra deshabilitado con un mensaje aclaratorio (ej. *"Asocie un cliente para proceder al cobro"* o *"Agregue productos al carrito"*).

## ¿Cómo verificamos? (criterios de aceptación)
- [ ] Venta de 1 prenda de S/ 129.90 sin descuento:
  * Subtotal Bruto: S/ 129.90
  * Descuento: S/ 0.00
  * Base Imponible: S/ 110.08
  * IGV (18%): S/ 19.82
  * Total a Pagar: S/ 129.90
- [ ] Venta con descuento de S/ 25.98 sobre S/ 259.80:
  * Total a pagar es exactamente S/ 233.82.
  * Base gravada (198.15) + IGV (35.67) suma exactamente S/ 233.82 sin diferencias de 1 centavo.
- [ ] El botón "Proceder al Cobro" permanece deshabilitado si no hay cliente asociado o el carrito está vacío.
- [ ] Al asociar un cliente y tener productos en el carrito, el botón se habilita de inmediato.

## ¿Con qué condiciones? (precondiciones y dependencias)
* Regla de Negocio RN-01: Obligatoriedad de desglose fiscal de IGV para comprobantes de pago.
* Regla de consistencia: Redondeo bancario simétrico a dos decimales.

## ¿Qué NO hará? (fuera de alcance)
* No aplica monedas extranjeras (todas las transacciones en mostrador son en PEN - Soles).
* No procesa cargos financieros por comisiones bancarias adicionales sobre el cliente.
