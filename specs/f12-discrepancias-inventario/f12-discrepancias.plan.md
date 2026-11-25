# Plan de Implementación — F12: Gestión de Discrepancias y Prendas no Ubicadas

> Documento de regularización y decisiones de arquitectura para discrepancias de inventario.

---

## 1. Decisiones Técnicas Confirmadas
1. **Separación de Estados de Stock:** El stock físico de `RET_STOCK_TIENDA` se divide en `cantidad_disponible` y `cantidad_cuarentena`. Al emitir el acta, las unidades se transfieren a cuarentena impidiendo su adición a cualquier carrito.

## 2. Registro de Incidencias y Regularizaciones
- **S14 — Persistencia alineada con el contrato §5.12 (Angie, DBA).** La decisión 1 queda sustituida: el contrato v0.4 eliminó `RET_STOCK_TIENDA` y Retail no guarda saldos (G4-P0-05). La cuarentena es una proyección local en `RET_INCIDENCIA_INVENTARIO`: una variante está bloqueada para la venta si tiene alguna incidencia de la tienda en `EN_CUARENTENA` o `PENDIENTE_REPORTE`. Migración: `diseño/schema-s14-f12.sql`, que pasa `variante_sku_id` a `TEXT`, reemplaza los estados `DESCARTADO` y `RECHAZADO` por los de §5.12 (`DESCARTADO` pasa a `BAJA_DEFINITIVA`; las filas en `RECHAZADO` eran datos de prueba y se eliminan) y crea `RET_ACTA_DISCREPANCIA` con el correlativo `ACTA-MERMA-AAAA-NNNN`.
