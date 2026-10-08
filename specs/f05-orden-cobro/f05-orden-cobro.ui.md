# UI Spec — F5: Registro de Venta Asistida y Emisión de Boleta

**Pantalla:** Modal de Cobro y Vista de Comprobante  
**Ruta:** Modal sobre `/pos` y pantalla de confirmación `/recibo/:id`  
**Spec Funcional:** `f05-orden-cobro.md`  
**Design System:** `specs/generales/design-system.md`  

---

## 1. Usuario Objetivo
Cajero en mostrador. Requiere cobrar en efectivo a máxima velocidad, entregar el vuelto exacto y entregar el ticket impreso al cliente.

## 2. Objetivo de la Pantalla
Facilitar la selección de medios de pago, el cálculo de vuelto con botones de billetes peruanos y la visualización de la boleta electrónica.

## 3. Composición y Layout

### Modal de Cobro (`PaymentModal`)
- **Cabecera:** Total a cobrar en tamaño gigante (`text-4xl font-bold`).
- **Selector de Medio:** Pestañas tipo segmented control (*Efectivo, Tarjeta, Mixto*).
- **Sección Efectivo:**
  - Input numérico grande con símbolo `S/`.
  - Botones de billetes peruanos (`DenominationCounter`): `[S/ 10]`, `[S/ 20]`, `[S/ 50]`, `[S/ 100]`, `[Exacto]`.
  - Tarjeta de Vuelto (`Card` con fondo verde suave): *"Vuelto a entregar: S/ 15.50"*.
- **Selector de Comprobante:** Boleta de Venta / Factura.
- **Botón de Acción:** Botón *"Confirmar Venta"* (`Button` variante `Confirm`).

### Vista de Boleta (`Receipt` / `ReceiptPage`)
- Formato térmico tipo ticket de 80mm de ancho.
- Razón social, RUC de la empresa, dirección de la tienda y fecha/hora.
- Serie y correlativo (ej. `B001-0004521`).
- Tabla de ítems con cantidad, descripción y precio.
- Desglose de Operación Gravada, IGV (18%) e Importe Total.
- Botones: *"Imprimir Ticket"*, *"Enviar por Correo"* y *"Nueva Venta"*.

## 4. Ciclo de Estados de la Interfaz

| Estado | Comportamiento Visual |
|---|---|
| **Efectivo Insuficiente** | Mensaje en rojo: *"Faltan S/ 8.00 para cubrir el total"*. Botón de Confirmar deshabilitado. |
| **Efectivo Suficiente** | Recuadro de Vuelto cambia a verde destacado con el monto exacto. Botón de Confirmar habilitado con atajo `[Enter]`. |
| **Procesando Venta** | Spinner centrado en el modal con texto *"Registrando orden y emitiendo comprobante..."*. |
| **Venta Exitosa** | Cierre del modal de cobro y apertura inmediata de la vista de Boleta con sonido de éxito. |

## 5. Tono Visual y Mapeo al Design System

| Elemento UI | Token / Clase del Design System |
|---|---|
| Modal Contenedor | `bg-white rounded-2xl p-6 max-w-xl shadow-2xl` |
| Total a Cobrar | `font-display text-4xl font-bold text-accent-signal` |
| Botón Billete Rápido | `border border-border-default rounded-lg py-2 px-3 text-sm font-semibold hover:bg-surface-cloud` |
| Recuadro de Vuelto | `bg-emerald-50 border border-emerald-200 rounded-xl p-4 text-emerald-800` |
| Ticket Térmico | `bg-white font-mono text-xs max-w-sm mx-auto p-4 border border-border-default shadow-sm` |
