# Spec — RF-27: Almacenamiento Local Seguro en IndexedDB (v0.1)

### Responsable: Cristhian (Backend Developer)
### Requerimiento Funcional: RF-27: Almacenamiento Local Seguro en IndexedDB
### Funcionalidad Padre: F10: Modo de Contingencia y Resiliencia Offline
### Prioridad: Must have (Crítico)

---

## ¿Por qué? (problema)
Cuando una venta se concreta durante una caída de red, los datos no pueden enviarse al servidor central. Si estos datos se guardan en variables volátiles o en un `localStorage` frágil (limitado a 5MB y vulnerable a borrado accidental o inyección), la información de la venta se pierde si el cajero refresca la página o se apaga la pantalla, provocando descalces de dinero y pérdida de boletas emitidas físicamente al cliente.

## ¿Para qué? (objetivo)
Implementar una base de datos local embebida en el navegador mediante **IndexedDB** (`RetailOfflineDB`), estructurada para almacenar transaccionalmente cada venta offline completada: asignándole un UUID local único, serie de contingencia física, cálculo de hash criptográfico de integridad SHA-256 y marca de tiempo, garantizando la inmutabilidad y persistencia de las órdenes hasta su sincronización formal.

## ¿Hasta dónde? (alcance)
* **Incluido:** Creación del almacén de objetos `ventas_offline` en IndexedDB del navegador; esquema con campos: `id_local`, `tiendaId`, `vendedorId`, `fechaHoraOffline`, `items`, `totales`, `pagoEfectivo`, `hashIntegridad`, `estado: PENDIENTE`; impresión de ticket físico con leyenda de contingencia (*"Comprobante emitido en contingencia offline"*); y retención de datos incluso ante cierre accidental del navegador.
* **Excluido:** Encriptación por hardware de grado militar HSM.

## Referencias
* **Contrato:** [api-contracts.md](./api-contracts.md) — Estructura interna de persistencia IndexedDB
* **Modelo:** `VentaOfflineSchema` (`idLocal`, `terminalPos`, `vendedorId`, `items`: `[]`, `totalNeto`, `efectivoRecibido`, `vuelto`, `hashSha256`, `estado`: `"PENDIENTE"`)

## ¿Qué debe hacer? (comportamiento)

### Frontend (Módulo de Persistencia Local IndexedDB)
1. Inicialización de la base de datos local:
   * Al cargar la aplicación, abre `indexedDB.open('RetailOfflineDB', 1)`.
   * Crea el almacén `ventas_offline` con índice por `estado` y `fechaHoraOffline`.
2. Al presionar *"Cobrar en Efectivo"* en Modo Offline:
   * Genera un identificador local único (UUID v4).
   * Asigna número de ticket correlativo de contingencia (ej. `CONT-TIENDA01-00012`).
   * Construye el payload JSON transaccional.
   * Calcula el hash SHA-256 del contenido JSON para evitar adulteraciones locales.
   * Abre una transacción `readwrite` en IndexedDB e inserta el registro con `estado = 'PENDIENTE'`.
3. Emisión del Comprobante Físico de Contingencia:
   * Renderiza el ticket de venta térmico agregando en el pie de página:
     * `COMPROBANTE EMITIDO EN CONTINGENCIA OFFLINE`.
     * `CÓDIGO DE SEGURIDAD: [Primeros 8 caracteres del Hash]`.
     * Leyenda: *"Comprobante electrónico válido por contingencia de red"*.
   * Lanza diálogo de impresión para entregar el papel al cliente.
4. Descuenta temporalmente las unidades vendidas de la copia local del catálogo para evitar sobrevender prendas físicas existentes en tienda.
5. Actualiza el contador del banner: *"N ventas en cola local pendientes"*.

## ¿Cómo verificamos? (criterios de aceptación)
- [ ] Cobro de venta en modo offline genera registro con UUID y estado `PENDIENTE` en IndexedDB (visible en pestaña Application de DevTools).
- [ ] Cerrar completamente la ventana del navegador y volver a abrirla conserva intactos los registros en cola en IndexedDB.
- [ ] El ticket impreso incluye la leyenda de emisión en contingencia y el código hash de seguridad.
- [ ] La cantidad vendida descuenta el stock de la caché local impidiendo volver a vender esa unidad física.

## ¿Con qué condiciones? (precondiciones y dependencias)
* Navegador con soporte para la API estándar IndexedDB (Chrome, Firefox, Edge).
* Regla de Negocio RN-03: Seguridad y auditoría de transacciones comerciales.

## ¿Qué NO hará? (fuera de alcance)
* No almacena números de tarjeta ni datos bancarios sensibles en el almacenamiento local.
