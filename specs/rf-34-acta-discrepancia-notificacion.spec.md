# Spec — RF-34: Acta de Discrepancia y Notificación a Inventarios (v0.1)

### Responsable: Guillermo (QA / Control de Calidad)
### Requerimiento Funcional: RF-34: Acta de Discrepancia y Notificación a Inventarios
### Funcionalidad Padre: F12: Gestión de Incidencias de Inventario y Mermas en Tienda
### Prioridad: Should have (Importante)

---

## ¿Por qué? (problema)
Las prendas retenidas en cuarentena no pueden quedarse en el limbo físico ni en la base de datos de la tienda para siempre: deben derivarse formalmente al Almacén Central (para lavado industrial, reparación o devolución a la marca deportiva como Nike o Adidas) o declararse como merma/baja definitiva. Si este proceso no genera un documento digital (Acta de Discrepancia) y no notifica al microservicio de *Productos y Ofertas*, el inventario contable y el inventario físico jamás cuadrarán.

## ¿Para qué? (objetivo)
Permitir al jefe de tienda o cajero consolidar las prendas en cuarentena al cierre de semana o mes, emitir un **Acta Digital de Discrepancia / Merma de Tienda** con código correlativo e imprimirla para adjuntarla al paquete físico, enviando simultáneamente una notificación vía API a *Productos y Ofertas* (`POST /api/v1/inventario/ajuste-discrepancia`) para regularizar el stock contable de la tienda.

## ¿Hasta dónde? (alcance)
* **Incluido:** Selección de artículos en cuarentena para inclusión en el acta; opciones de destino (*"Devolución a Almacén Central por Garantía"*, *"Baja por Deterioro / Merma Irrecuperable"*, *"Ajuste por Faltante / Pérdida"*); generación de acta con correlativo oficial (ej. `ACTA-MERMA-2026-0012`); formato PDF/impreso con casillas de firma del jefe de tienda; y notificación vía API REST a *Productos y Ofertas* para el decremento contable definitivo.
* **Excluido:** Deducciones contables del balance impositivo corporativo (área de finanzas).

## Referencias
* **Contrato:** [api-contracts.md](./api-contracts.md) — `POST /api/v1/retail/inventario/actas-merma`, `POST /api/v1/productos/inventario/ajuste-discrepancia`
* **Modelo:** `ActaDiscrepanciaRequest` (`tiendaId`, `responsableId`, `tipoDestino`, `incidenciasIds`: `[]`, `observaciones`), `ActaDiscrepanciaResponse` (`actaNumero`, `fechaEmision`, `totalPrendasAfectadas`, `urlPdfActa`, `estadoNotificacionProductos`)

## ¿Qué debe hacer? (comportamiento)

### Backend (Retail / Notificación a Productos)
1. Expone `POST /api/v1/retail/inventario/actas-merma`:
   * Verifica permisos de supervisor o jefe de tienda.
   * Recibe la lista de incidencias en cuarentena a liquidar.
   * Genera el correlativo oficial del acta (`ACTA-MERMA-TIENDA-YYYY-XXXX`).
   * Envía petición al microservicio de *Productos y Ofertas*:
     * `POST /api/v1/inventario/ajuste-discrepancia`: solicitando el decremento del stock patrimonial de la tienda por motivo de merma/devolución.
   * Actualiza el estado de las incidencias en `RET_INCIDENCIA_INVENTARIO` a `DERIVADO_ALMACEN` o `BAJA_DEFINITIVA`.
2. Retorna `201 Created` con el acta digital y la constancia de ajuste de inventario.

### Frontend
1. En el módulo de inventario de mostrador:
   * Pestaña *"Generar Acta de Salida por Merma / Discrepancia"*.
2. Interfaz de armado de acta:
   * Lista de artículos en cuarentena con casillas de selección.
   * Selector de destino del lote:
     * Radio: *"Envío a Almacén Central (Falla de fábrica / Reclamo a marca)"*.
     * Radio: *"Baja Definitiva en Tienda (Prenda destruida / Extravío confirmado)"*.
   * Resumen de prendas seleccionadas (ej. `2 zapatillas, 1 camiseta`).
3. Botón *"Emitir Acta y Notificar a Inventarios"*:
   * Muestra modal de confirmación con advertencia de que la acción regularizará el stock patrimonial.
4. Pantalla de Acta Emitida:
   * Visualización del Acta Formal:
     * Cabecera con datos de la tienda física y fecha.
     * Número de acta correlativo.
     * Tabla con prendas, códigos SKU, marcas, tallas y motivos de merma.
     * Campos para firma del Jefe de Tienda y del transportista de almacén.
   * Botón *"Imprimir Acta de Despacho de Mermas"*.

## ¿Cómo verificamos? (criterios de aceptación)
- [ ] Selección de 2 prendas en cuarentena y emisión del acta → Cambia su estado a `DERIVADO_ALMACEN` retirándolas de la bandeja de cuarentena.
- [ ] El sistema llama exitosamente a la API de Productos y Ofertas reportando el ajuste de inventario.
- [ ] El acta generada cuenta con número correlativo inmutable y desglose de prendas apto para imprimir.
- [ ] Intentar generar un acta sin seleccionar ninguna prenda muestra validación de lista vacía.

## ¿Con qué condiciones? (precondiciones y dependencias)
* Prendas en estado `EN_CUARENTENA` registradas bajo RF-32 y RF-33.
* Conexión con el microservicio de *Productos y Ofertas*.
* Regla de Negocio RN-02: Regularización de inventarios y control de mermas.

## ¿Qué NO hará? (fuera de alcance)
* No genera asientos contables en libros diarios de la empresa (gestión de Finanzas).
