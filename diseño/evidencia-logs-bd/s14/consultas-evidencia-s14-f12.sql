-- =============================================================================
-- EVIDENCIAS DE INTEGRIDAD — SEMANA 14 (HITO 5) — F12 Incidencias, Cuarentena y Actas
-- Módulo Retail (G4) — Responsable: Angie (DBA)
--
-- Requiere haber ejecutado antes diseño/schema.sql y diseño/schema-s14-f12.sql.
--
-- Cómo usarlo en el SQL Editor de Supabase:
--   * Ejecutar UN bloque a la vez (seleccionar el bloque y "Run"): el editor solo muestra
--     el resultado de la última sentencia.
--   * Cada captura se guarda en esta carpeta con el nombre "evidencia-NN-nombre.png"
--     indicado en el encabezado [NN-nombre].
--   * Los bloques marcados "Esperado: ERROR" deben fallar: la captura del error ES la
--     evidencia de que la restricción funciona. Una sentencia que falla no guarda nada.
--   * Las filas de prueba usan IDs fijos (…a1, …a2, …b1) y se borran en el bloque [09].
-- =============================================================================


-- [01-tablas-y-columnas] ------------------------------------------------------
SELECT table_name AS tabla, column_name AS columna, data_type AS tipo, is_nullable AS nulo
  FROM information_schema.columns
 WHERE table_schema = 'public'
   AND table_name IN ('ret_incidencia_inventario', 'ret_acta_discrepancia')
 ORDER BY table_name, ordinal_position;
-- Esperado: variante_sku_id es "text"; existen acta_id, idempotency_key,
-- incidencia_inventory_id e intentos_reporte; ret_acta_discrepancia tiene supervisor_id.


-- [02-restricciones] ----------------------------------------------------------
SELECT conrelid::regclass AS tabla, conname AS restriccion, pg_get_constraintdef(oid) AS definicion
  FROM pg_constraint
 WHERE conrelid IN ('ret_incidencia_inventario'::regclass, 'ret_acta_discrepancia'::regclass)
 ORDER BY 1, 2;
-- Esperado: chk_incidencia_estado con los 4 estados de §5.12, chk_incidencia_acta_coherente,
-- fk_incidencia_acta -> ret_acta_discrepancia y el CHECK del formato ACTA-MERMA-AAAA-NNNN.


-- [03-indices] ----------------------------------------------------------------
SELECT tablename AS tabla, indexname AS indice, indexdef AS definicion
  FROM pg_indexes
 WHERE schemaname = 'public'
   AND tablename IN ('ret_incidencia_inventario', 'ret_acta_discrepancia')
 ORDER BY tablename, indexname;
-- Esperado: ux_ret_incidencia_clave, idx_incidencia_sku_activa, idx_incidencia_pendiente_reporte,
-- idx_incidencia_acta, idx_incidencia_tienda_estado e idx_acta_tienda_fecha.


-- [04-rls-y-secuencia] --------------------------------------------------------
SELECT t.tablename AS objeto, t.rowsecurity::text AS detalle
  FROM pg_tables t
 WHERE t.schemaname = 'public'
   AND t.tablename IN ('ret_incidencia_inventario', 'ret_acta_discrepancia')
UNION ALL
SELECT s.sequencename, 'max_value=' || s.max_value || ', last_value=' || coalesce(s.last_value::text, 'sin usar')
  FROM pg_sequences s
 WHERE s.schemaname = 'public' AND s.sequencename = 'ret_acta_merma_seq';
-- Esperado: RLS "true" en ambas tablas y la secuencia ret_acta_merma_seq con max_value=9999.


-- [05-reporte-incidencia] (RF-32) ---------------------------------------------
INSERT INTO RET_INCIDENCIA_INVENTARIO
    (id_incidencia, tienda_id, vendedor_reporta_id, variante_sku_id, nombre_producto,
     codigo_barras, tipo_falla, detalle_observacion, idempotency_key)
VALUES
    ('00000000-0000-0000-0000-0000000000a1', 'TIENDA-MIRAFLORES', gen_random_uuid(),
     'CAM-PERU-M-BLA', 'Camiseta Perú M Blanca', '7759876543210', 'MANCHADO_PROBADOR',
     'Mancha de maquillaje en el cuello', 'evid-s14-01'),
    ('00000000-0000-0000-0000-0000000000a2', 'TIENDA-MIRAFLORES', gen_random_uuid(),
     'ZAP-RUN-42-NEG', 'Zapatilla Running 42 Negra', '7751234567890', 'DEFECTO_FABRICA',
     'Suela despegada de fábrica', 'evid-s14-02')
RETURNING id_incidencia, variante_sku_id AS sku, tipo_falla, estado_cuarentena, intentos_reporte;
-- Esperado: 2 filas con estado_cuarentena = EN_CUARENTENA e intentos_reporte = 0.


-- [06-bandeja-cuarentena] (RF-33: GET /inventario/cuarentena y bloqueo del carrito) --
SELECT id_incidencia, variante_sku_id AS sku, nombre_producto, tipo_falla,
       estado_cuarentena, fecha_reporte
  FROM RET_INCIDENCIA_INVENTARIO
 WHERE tienda_id = 'TIENDA-MIRAFLORES'
   AND estado_cuarentena IN ('EN_CUARENTENA', 'PENDIENTE_REPORTE')
 ORDER BY fecha_reporte DESC;
-- Esperado: aparecen las 2 prendas: son los SKU que el carrito debe rechazar.


-- [07a-error-observacion-corta] -----------------------------------------------
INSERT INTO RET_INCIDENCIA_INVENTARIO
    (tienda_id, vendedor_reporta_id, variante_sku_id, codigo_barras, tipo_falla, detalle_observacion)
VALUES ('TIENDA-MIRAFLORES', gen_random_uuid(), 'CAM-PERU-M-BLA', '7759876543210', 'COSTURA_ROTA', 'mal');
-- Esperado: ERROR chk_incidencia_observacion_min (menos de 5 caracteres, CA-RF32-04).


-- [07b-error-reporte-duplicado] -----------------------------------------------
INSERT INTO RET_INCIDENCIA_INVENTARIO
    (tienda_id, vendedor_reporta_id, variante_sku_id, codigo_barras, tipo_falla,
     detalle_observacion, idempotency_key)
VALUES ('TIENDA-MIRAFLORES', gen_random_uuid(), 'CAM-PERU-M-BLA', '7759876543210',
        'COSTURA_ROTA', 'Costura abierta en manga', 'evid-s14-01');
-- Esperado: ERROR ux_ret_incidencia_clave (misma Idempotency-Key: un reintento no duplica).


-- [07c-error-estado-invalido] -------------------------------------------------
INSERT INTO RET_INCIDENCIA_INVENTARIO
    (tienda_id, vendedor_reporta_id, variante_sku_id, codigo_barras, tipo_falla,
     detalle_observacion, estado_cuarentena)
VALUES ('TIENDA-MIRAFLORES', gen_random_uuid(), 'CAM-PERU-M-BLA', '7759876543210',
        'COSTURA_ROTA', 'Costura abierta en manga', 'DESCARTADO');
-- Esperado: ERROR chk_incidencia_estado (DESCARTADO ya no es un estado de §5.12).


-- [08a-emitir-acta] (RF-34) ---------------------------------------------------
-- Número fijo para no consumir el correlativo real de ret_acta_merma_seq.
INSERT INTO RET_ACTA_DISCREPANCIA
    (id_acta, numero_acta, tienda_id, supervisor_id, tipo_destino, total_prendas, observaciones)
VALUES ('00000000-0000-0000-0000-0000000000b1', 'ACTA-MERMA-2026-9999', 'TIENDA-MIRAFLORES',
        gen_random_uuid(), 'DEVOLUCION_CENTRAL', 1, 'Lote enviado con transporte interno')
RETURNING id_acta, numero_acta, tipo_destino, total_prendas, fecha_emision;
-- Esperado: 1 fila con ACTA-MERMA-2026-9999.


-- [08b-error-acta-sin-salir-de-cuarentena] ------------------------------------
UPDATE RET_INCIDENCIA_INVENTARIO
   SET acta_id = '00000000-0000-0000-0000-0000000000b1'
 WHERE id_incidencia = '00000000-0000-0000-0000-0000000000a2';
-- Esperado: ERROR chk_incidencia_acta_coherente (una prenda en cuarentena no puede tener acta).


-- [08c-error-acta-vacia] ------------------------------------------------------
INSERT INTO RET_ACTA_DISCREPANCIA (numero_acta, tienda_id, supervisor_id, tipo_destino, total_prendas)
VALUES ('ACTA-MERMA-2026-9998', 'TIENDA-MIRAFLORES', gen_random_uuid(), 'BAJA_DEFINITIVA', 0);
-- Esperado: ERROR por total_prendas > 0 (equivale a 400 LISTA_VACIA, CA-RF34-04).


-- [08d-error-formato-acta] ----------------------------------------------------
INSERT INTO RET_ACTA_DISCREPANCIA (numero_acta, tienda_id, supervisor_id, tipo_destino, total_prendas)
VALUES ('ACTA-2026-12', 'TIENDA-MIRAFLORES', gen_random_uuid(), 'BAJA_DEFINITIVA', 1);
-- Esperado: ERROR por el CHECK del formato ACTA-MERMA-AAAA-NNNN.


-- [08e-liquidar-incidencia] ---------------------------------------------------
UPDATE RET_INCIDENCIA_INVENTARIO
   SET estado_cuarentena = 'DERIVADO_ALMACEN', acta_id = '00000000-0000-0000-0000-0000000000b1'
 WHERE id_incidencia = '00000000-0000-0000-0000-0000000000a2';

SELECT a.numero_acta, a.tipo_destino, i.id_incidencia, i.variante_sku_id AS sku,
       i.estado_cuarentena, i.updated_at
  FROM RET_ACTA_DISCREPANCIA a
  JOIN RET_INCIDENCIA_INVENTARIO i ON i.acta_id = a.id_acta
 WHERE a.id_acta = '00000000-0000-0000-0000-0000000000b1';
-- Esperado: ACTA-MERMA-2026-9999 con la zapatilla en DERIVADO_ALMACEN (CA-RF34-01).
-- Opcional: volver a ejecutar [06] y capturarlo como "evidencia-08f-bandeja-tras-acta.png":
-- ahora solo queda la camiseta en la bandeja.


-- [09-limpieza] ---------------------------------------------------------------
-- Ejecutar al terminar las capturas. Primero las incidencias (tienen la FK al acta).
DELETE FROM RET_INCIDENCIA_INVENTARIO
 WHERE id_incidencia IN ('00000000-0000-0000-0000-0000000000a1', '00000000-0000-0000-0000-0000000000a2');
DELETE FROM RET_ACTA_DISCREPANCIA
 WHERE id_acta = '00000000-0000-0000-0000-0000000000b1';

SELECT (SELECT count(*) FROM RET_INCIDENCIA_INVENTARIO WHERE idempotency_key LIKE 'evid-s14-%') AS incidencias_prueba,
       (SELECT count(*) FROM RET_ACTA_DISCREPANCIA WHERE numero_acta LIKE 'ACTA-MERMA-2026-99%') AS actas_prueba;
-- Esperado: 0 y 0. No hace falta captura.
