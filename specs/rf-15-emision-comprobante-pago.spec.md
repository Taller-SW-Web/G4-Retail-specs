# Spec — RF-15: Emisión y Despliegue de Comprobante de Pago Electrónico (v0.1)

### Responsable: Miguel (DevOps / Tech Lead)
### Requerimiento Funcional: RF-15: Emisión y Despliegue de Comprobante de Pago Electrónico
### Funcionalidad Padre: F5: Generación de Pedido, Pago en Tienda y Creación de Boleta
### Prioridad: Must have (Crítico)

---

## ¿Por qué? (problema)
Al concluir una compra en tienda, es una obligación tributaria ineludible entregar al comprador su comprobante de pago electrónico (Boleta de Venta o Factura). Si el sistema no valida las condiciones legales (ej. obligatoriedad de DNI para montos mayores a S/ 700 o RUC para facturas) o no genera el ticket térmico con su serie y correlativo, la tienda incurre en infracciones graves ante la administración tributaria (SUNAT).

## ¿Para qué? (objetivo)
Permitir la selección del tipo de comprobante (Boleta de Venta o Factura Electrónica), validar el cumplimiento de las normativas tributarias (DNI obligatorio si el total >= S/ 700.00; RUC de 11 dígitos y razón social para facturas), emitir el comprobante con su serie y numeración correlativa fiscal, y desplegar en pantalla una vista de ticket térmico lista para impresión directa o envío digital.

## ¿Hasta dónde? (alcance)
* **Incluido:** Selector de comprobante (Boleta / Factura), reglas tributarias SUNAT de obligatoriedad de documento, asignación de serie y número correlativo oficial, renderizado de ticket de venta con formato térmico (80 mm), botón de impresión directa (`window.print()`), y botón *"Nueva Venta"* para reiniciar el mostrador.
* **Excluido:** Cobro presencial (cubierto en RF-13), orquestación transaccional de stock y orden (cubierto en RF-14), y comunicación directa con los webservices SOAP de SUNAT (orquestada por el microservicio central de Facturación y Ventas).

## Referencias
* **Contrato:** [api-contracts.md](./api-contracts.md) — `POST /api/v1/ordenes/presenciales` (Sección 3)
* **Modelo:** `ComprobantePago` (`tipo`: `"BOLETA" | "FACTURA"`, `serie`: `string`, `correlativo`: `string`, `fechaEmision`: `string`, `datosEmisor`: `{ruc, razonSocial, direccion}`, `datosReceptor`: `{documento, nombre}`, `totales`: `{subtotal, igv, total}`, `qrPayload`: `string`)

## ¿Qué debe hacer? (comportamiento)

### Backend (Retail / Formateo de Comprobante)
1. Durante la petición de finalización de orden:
   * Valida la regla fiscal peruana RN-01:
     * Si `tipo == "FACTURA"`: Requiere obligatoriamente `tipoDocumento == "RUC"`, `numeroDocumento` de 11 dígitos y `razonSocial`.
     * Si `tipo == "BOLETA"` y `total >= 700.00`: Requiere obligatoriamente `tipoDocumento == "DNI"` y nombre del cliente (no permite cliente anónimo).
2. Coordina con *Ventas y Facturación* la obtención de la numeración fiscal:
   * Boleta: Serie `B001` - Correlativo incremental (ej. `00045231`).
   * Factura: Serie `F001` - Correlativo incremental (ej. `00012094`).
3. Retorna la estructura completa del comprobante con la fecha/hora legal de emisión y la cadena para generar el código QR fiscal.

### Frontend
1. En la pantalla de cobro:
   * Selector tipo radio: *"Boleta de Venta"* (opción predeterminada) o *"Factura Electrónica"*.
   * Si el total de la venta es mayor o igual a S/ 700.00 y no hay DNI registrado, muestra advertencia obligatoria: *"Por normativa SUNAT, ventas mayores o iguales a S/ 700.00 requieren identificar al cliente con su DNI"*.
2. Pantalla de Éxito / Ticket de Venta:
   * Despliega la tarjeta visual simulando un ticket térmico de mostrador:
     * Logotipo comercial de la cadena deportiva.
     * Datos fiscales de la tienda: RUC de la empresa, Razón Social, Dirección física de la tienda.
     * Identificación del Comprobante: `BOLETA DE VENTA ELECTRÓNICA B001-00045231`.
     * Fecha y hora exacta de emisión.
     * Datos del cliente (DNI/RUC, Nombre o Razón Social).
     * Tabla desglosada de artículos (Cantidad, Prenda, Talla/Color, P. Unitario, Importe).
     * Desglose fiscal: Op. Gravada (S/ XX.XX), IGV 18% (S/ XX.XX) y Total Cancelado (S/ XX.XX).
     * Medio de pago empleado (Efectivo y vuelto, o Tarjeta con N° operación).
     * Código QR de verificación fiscal.
3. Botones de acción final:
   * Botón destacado *"Imprimir Ticket"*: Lanza el diálogo de impresión del navegador con estilos optimizados para papel continuo de 80 mm.
   * Botón *"Nueva Venta"*: Restablece todo el estado de mostrador para recibir al siguiente cliente en cola.

## ¿Cómo verificamos? (criterios de aceptación)
- [ ] Venta de S/ 750.00 con boleta sin DNI de cliente → El sistema impide emitir la boleta y exige asociar DNI.
- [ ] Venta con factura seleccionada y cliente con DNI → Muestra error *"Para emitir Factura debe asociar un cliente con RUC corporativo"*.
- [ ] Venta finalizada exitosamente → Muestra ticket con serie B001 o F001, correlativo, fecha y desglose de IGV idéntico al total.
- [ ] Clic en "Imprimir Ticket" activa el diálogo nativo de impresión con estilos CSS `@media print` para ticket térmico.
- [ ] Clic en "Nueva Venta" limpia el comprobante de la pantalla, vacía el carrito y sitúa el cursor en el buscador de productos.

## ¿Con qué condiciones? (precondiciones y dependencias)
* Regla de Negocio RN-01: Cumplimiento tributario de comprobantes de pago según directivas SUNAT.
* La numeración de correlativos debe ser estrictamente correlativa e inmutable.

## ¿Qué NO hará? (fuera de alcance)
* No gestionará libros contables electrónicos ni declaraciones tributarias mensuales (PDT/SIRE).
* No permite reimprimir comprobantes alterando sus datos originales tras ser emitidos.
