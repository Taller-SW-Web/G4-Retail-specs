# Spec — RF-32: Reporte de Prenda Dañada o No Ubicada en Mostrador (v0.1)

### Responsable: Maylle (Arquitectura de Software)
### Requerimiento Funcional: RF-32: Reporte de Prenda Dañada o No Ubicada en Mostrador
### Funcionalidad Padre: F12: Gestión de Incidencias de Inventario y Mermas en Tienda
### Prioridad: Must have (Condicionado a F12)

---

## ¿Por qué? (problema)
En la tienda física ocurren incidentes diarios con los productos: una prenda en exhibición o en el probador se mancha con maquillaje o desodorante, un cliente rompe una costura al medirse una talla muy ajustada, o el sistema indica que queda 1 par de zapatillas pero al buscar en el almacén físico la caja no aparece (posible pérdida o extravío). Si el vendedor no tiene cómo reportar esta novedad en el acto, el sistema sigue mostrando esa unidad como vendible, ocasionando que otros vendedores la prometan o que un cliente la agregue a su carrito para luego sufrir una cancelación forzada.

## ¿Para qué? (objetivo)
Permitir al personal de tienda reportar de forma ágil una incidencia sobre un artículo físico específico (mediante escaneo de su código de barras o búsqueda por SKU), seleccionando la tipología de falla (*"Prenda manchada en probador"*, *"Costura o tela dañada"*, *"Falla de confección"*, *"Artículo extraviado / no ubicado físicamente"*), adjuntando una descripción y generando el registro formal de la discrepancia.

## ¿Hasta dónde? (alcance)
* **Incluido:** Modal de captura rápida de incidencia en catálogo; búsqueda o pistoleo del SKU de la prenda; selector de tipo de falla con opciones predeterminadas de tienda deportiva; campo de observaciones; adjunto opcional de URL de foto/evidencia; y persistencia en la tabla `RET_INCIDENCIA_INVENTARIO`.
* **Excluido:** Retiro físico del producto hacia la trastienda (acción manual del personal) y peritaje contable de seguros.

## Referencias
* **Contrato:** [api-contracts.md](./api-contracts.md) — `POST /api/v1/retail/inventario/incidencias`
* **Modelo:** `IncidenciaReporteRequest` (`varianteSkuId`, `codigoBarras`, `tipoFalla`, `detalleObservacion`, `fotoUrl`), `IncidenciaReporteResponse` (`incidenciaId`, `estado`, `fechaReporte`, `mensaje`)

## ¿Qué debe hacer? (comportamiento)

### Backend (Microservicio Retail)
1. Expone `POST /api/v1/retail/inventario/incidencias`:
   * Verifica token Bearer del vendedor.
   * Valida campos obligatorios: `varianteSkuId`, `tipoFalla` (`MANCHADO_PROBADOR`, `COSTURA_ROTA`, `EXTRAVIO_NO_UBICADO`, `DEFECTO_FABRICA`), `detalleObservacion` (mínimo 5 caracteres).
   * Asocia la tienda del vendedor (`tienda_id`) y fecha/hora actual.
2. Inserta el registro en `RET_INCIDENCIA_INVENTARIO` con `estado_cuarentena = 'EN_CUARENTENA'`.
3. Dispara la orden de bloqueo preventivo en mostrador (RF-33).
4. Retorna `201 Created` con el ID de la incidencia y la confirmación de puesta en cuarentena.

### Frontend
1. En la ficha de detalle de producto o matriz de variantes:
   * Botón secundario con ícono de advertencia: *"Reportar Daño / Falla Física"*.
2. Modal de Reporte de Incidencia:
   * Permite confirmar el SKU específico escaneando la etiqueta de la prenda con el lector óptico.
   * Selector de Tipo de Incidencia:
     * Radio: *"Prenda Manchada en Probador"*.
     * Radio: *"Costura / Cremallera / Suela Dañada"*.
     * Radio: *"Prenda / Caja No Ubicada Físicamente (Faltante)"*.
     * Radio: *"Falla de Fábrica Detectada en Mostrador"*.
   * Textarea: *"Detalle del incidente"* (ej. *"Mancha de base de maquillaje en cuello de camiseta Talla S"*).
   * Botón para adjuntar foto referencial (opcional).
3. Botón *"Confirmar Reporte y Aislar Prenda"*:
   * Muestra confirmación: *"La prenda será retirada inmediatamente de la venta en mostrador"*.
   * Muestra mensaje de éxito: *"Incidencia #INC-0089 registrada. Por favor traslade la prenda al contenedor de cuarentena en almacén"*.

## ¿Cómo verificamos? (criterios de aceptación)
- [ ] Escanear el código de barras de una prenda rota en el modal carga automáticamente su nombre y SKU.
- [ ] Seleccionar el motivo "Costura dañada" y confirmar guarda la incidencia en estado `EN_CUARENTENA`.
- [ ] El sistema asocia el vendedor que reportó el incidente para control de calidad y auditoría.
- [ ] Enviar el formulario sin seleccionar tipo de falla muestra validación de campo requerido.

## ¿Con qué condiciones? (precondiciones y dependencias)
* El vendedor debe tener turno activo.
* Regla de Negocio RN-02: Veracidad y disponibilidad física real de stock.

## ¿Qué NO hará? (fuera de alcance)
* No destruye ni desecha físicamente el inventario (requiere autorización de jefe de tienda).
