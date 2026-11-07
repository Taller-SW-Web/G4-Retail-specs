-- =============================================================================
-- EVIDENCIAS DE INTEGRIDAD — SEMANA 11 (HITO 4) — F8 Control de Turno y Cuadre de Caja
-- Módulo Retail (G4) — Responsable: Angie (DBA)
--
-- Consultas ejecutadas en el SQL Editor de Supabase, una por una. Cada captura de pantalla
-- lleva el nombre indicado en el encabezado "[NN-nombre]".
-- Requiere haber ejecutado antes diseño/schema.sql y diseño/schema-s11.sql.
-- =============================================================================

-- [01-tablas-existentes]
SELECT table_name
  FROM information_schema.tables
 WHERE table_schema = 'public'
   AND table_name IN ('ret_caja_sesion', 'ret_movimiento_caja', 'ret_cobro_turno',
                      'ret_solicitud_cambio_mostrador', 'ret_vale_compra')
 ORDER BY table_name;
-- Esperado: 5 filas.

-- [02-claves-foraneas]
SELECT tc.table_name AS tabla, tc.constraint_name AS restriccion,
       kcu.column_name AS columna, ccu.table_name AS referencia
  FROM information_schema.table_constraints tc
  JOIN information_schema.key_column_usage kcu
    ON tc.constraint_name = kcu.constraint_name AND tc.table_schema = kcu.table_schema
  JOIN information_schema.constraint_column_usage ccu
    ON tc.constraint_name = ccu.constraint_name AND tc.table_schema = ccu.table_schema
 WHERE tc.constraint_type = 'FOREIGN KEY'
   AND tc.table_name IN ('ret_movimiento_caja', 'ret_cobro_turno',
                         'ret_solicitud_cambio_mostrador', 'ret_vale_compra')
 ORDER BY tc.table_name;
-- Esperado: movimiento -> caja_sesion; cobro -> caja_sesion; solicitud -> caja_sesion; vale -> solicitud.

-- [03-indices]
SELECT tablename AS tabla, indexname AS indice, indexdef AS definicion
  FROM pg_indexes
 WHERE schemaname = 'public'
   AND tablename IN ('ret_solicitud_cambio_mostrador', 'ret_vale_compra', 'ret_cobro_turno')
 ORDER BY tablename, indexname;
-- Esperado: índices sobre boleta_numero, cliente_id y tienda_id (cambios y vales),
-- y sobre caja_sesion_id/estado, pedido_id e idempotency_key (cobros).

-- [04-turno-y-movimientos]  (después de registrar movimientos desde el POS)
SELECT c.id_sesion, c.tienda_id, c.terminal_pos_codigo, c.estado,
       c.saldo_inicial_efectivo AS fondo_fijo,
       m.tipo_movimiento, m.monto, m.motivo, m.autorizado_por_supervisor, m.fecha_hora
  FROM RET_CAJA_SESION c
  JOIN RET_MOVIMIENTO_CAJA m ON m.caja_sesion_id = c.id_sesion
 ORDER BY m.fecha_hora DESC
 LIMIT 20;

-- [04b-totales-por-turno]  (lo que alimenta el arqueo ciego; incluye el efectivo de ventas)
SELECT c.id_sesion,
       c.saldo_inicial_efectivo AS fondo_fijo,
       COALESCE((SELECT SUM(k.monto_total) FROM RET_COBRO_TURNO k
                  WHERE k.caja_sesion_id = c.id_sesion
                    AND k.medio_pago = 'EFECTIVO' AND k.estado <> 'ANULADO'), 0) AS ventas_efectivo,
       COALESCE((SELECT SUM(m.monto) FROM RET_MOVIMIENTO_CAJA m
                  WHERE m.caja_sesion_id = c.id_sesion
                    AND m.tipo_movimiento = 'INGRESO_MENOR'), 0) AS ingresos_menores,
       COALESCE((SELECT SUM(m.monto) FROM RET_MOVIMIENTO_CAJA m
                  WHERE m.caja_sesion_id = c.id_sesion
                    AND m.tipo_movimiento = 'SALIDA_GASTO'), 0) AS egresos,
       c.saldo_inicial_efectivo
         + COALESCE((SELECT SUM(k.monto_total) FROM RET_COBRO_TURNO k
                      WHERE k.caja_sesion_id = c.id_sesion
                        AND k.medio_pago = 'EFECTIVO' AND k.estado <> 'ANULADO'), 0)
         + COALESCE((SELECT SUM(m.monto) FROM RET_MOVIMIENTO_CAJA m
                      WHERE m.caja_sesion_id = c.id_sesion
                        AND m.tipo_movimiento = 'INGRESO_MENOR'), 0)
         - COALESCE((SELECT SUM(m.monto) FROM RET_MOVIMIENTO_CAJA m
                      WHERE m.caja_sesion_id = c.id_sesion
                        AND m.tipo_movimiento = 'SALIDA_GASTO'), 0) AS saldo_esperado,
       c.saldo_final_sistema AS saldo_guardado_al_cierre
  FROM RET_CAJA_SESION c
 ORDER BY c.fecha_hora_apertura DESC
 LIMIT 20;
-- En un turno cerrado, saldo_esperado debe coincidir con saldo_guardado_al_cierre.

-- [05-cierre-y-auditoria]  (después de cerrar el turno)
SELECT c.id_sesion, c.estado, c.saldo_final_declarado, c.saldo_final_sistema, c.diferencia_saldo,
       a.accion, a.estado AS estado_auditoria, a.detalle, a.fecha_hora
  FROM RET_CAJA_SESION c
  JOIN RET_AUDITORIA_OPERACIONES a ON a.caja_sesion_id = c.id_sesion
 ORDER BY a.fecha_hora DESC
 LIMIT 20;

-- [05b-cambios-y-vales]  (solo si F9 ya emitió un vale)
SELECT s.boleta_numero, s.estado_aprobacion, s.monto_acreditado,
       v.codigo_vale, v.monto_a_favor, v.saldo_disponible, v.estado AS estado_vale,
       v.fecha_emision, v.fecha_vencimiento,
       (v.fecha_vencimiento::date - v.fecha_emision::date) AS dias_de_vigencia
  FROM RET_SOLICITUD_CAMBIO_MOSTRADOR s
  JOIN RET_VALE_COMPRA v ON v.solicitud_cambio_id = s.id_solicitud
 ORDER BY v.fecha_emision DESC
 LIMIT 20;
-- Esperado: dias_de_vigencia = 30.

-- [07-cobros-del-turno]  (después de cobrar ventas desde el POS; requiere que VentaService registre el cobro)
SELECT c.id_sesion, c.estado AS estado_turno,
       k.idempotency_key, k.pedido_id,
       k.comprobante_serie || '-' || k.comprobante_numero AS comprobante,
       k.medio_pago, k.monto_total, k.monto_recibido, k.vuelto,
       k.estado AS estado_cobro, k.created_at
  FROM RET_CAJA_SESION c
  JOIN RET_COBRO_TURNO k ON k.caja_sesion_id = c.id_sesion
 ORDER BY k.created_at DESC
 LIMIT 20;
-- Esperado: cada cobro enlazado a su turno, con el pedido de G5 (PED-AAAA-NNNNN) y el comprobante.

-- [06-prueba-integridad]  (ejecutar TODO el bloque junto; no deja datos)
BEGIN;

-- 6.1 Datos válidos: turno -> solicitud de cambio -> vale
INSERT INTO RET_CAJA_SESION (id_sesion, tienda_id, terminal_pos_codigo, vendedor_id, saldo_inicial_efectivo)
VALUES ('aaaaaaaa-0000-0000-0000-000000000011', 'TIENDA-MIRAFLORES', 'POS-EVID', gen_random_uuid(), 200.00);

INSERT INTO RET_SOLICITUD_CAMBIO_MOSTRADOR
    (id_solicitud, caja_sesion_id, pedido_id_origen, variante_sku_devuelta_id, cliente_id,
     motivo_cambio, inspeccion_etiquetas, inspeccion_sin_uso, inspeccion_empaque,
     estado_aprobacion, monto_acreditado, boleta_numero, tienda_id)
VALUES ('bbbbbbbb-0000-0000-0000-000000000011', 'aaaaaaaa-0000-0000-0000-000000000011',
        gen_random_uuid(), gen_random_uuid(), gen_random_uuid(),
        'CAMBIO_TALLA', TRUE, TRUE, TRUE, 'APROBADO_EN_TIENDA', 116.91,
        'B001-00000045', 'TIENDA-MIRAFLORES');

INSERT INTO RET_VALE_COMPRA (solicitud_cambio_id, boleta_numero, cliente_id, tienda_id, monto_a_favor, saldo_disponible)
SELECT id_solicitud, boleta_numero, cliente_id, tienda_id, 116.91, 116.91
  FROM RET_SOLICITUD_CAMBIO_MOSTRADOR
 WHERE id_solicitud = 'bbbbbbbb-0000-0000-0000-000000000011';

-- El vale nace EMITIDO, con código VALE-AAAA-NNNNN y vigencia de 30 días
SELECT codigo_vale, estado, monto_a_favor, saldo_disponible,
       (fecha_vencimiento::date - fecha_emision::date) AS dias_de_vigencia
  FROM RET_VALE_COMPRA
 WHERE solicitud_cambio_id = 'bbbbbbbb-0000-0000-0000-000000000011';

-- 6.1b Cobro en efectivo asociado al turno (nace PENDIENTE_CONFIRMACION; el vuelto cuadra)
INSERT INTO RET_COBRO_TURNO
    (caja_sesion_id, idempotency_key, pedido_id, comprobante_serie, comprobante_numero,
     medio_pago, monto_total, monto_recibido, vuelto)
VALUES ('aaaaaaaa-0000-0000-0000-000000000011', 'evid-0001', 'PED-2026-00412', 'B001', '00000045',
        'EFECTIVO', 116.91, 120.00, 3.09);

SELECT c.id_sesion, c.saldo_inicial_efectivo AS fondo_fijo,
       k.idempotency_key, k.pedido_id, k.medio_pago, k.monto_total, k.vuelto, k.estado
  FROM RET_CAJA_SESION c
  JOIN RET_COBRO_TURNO k ON k.caja_sesion_id = c.id_sesion
 WHERE c.id_sesion = 'aaaaaaaa-0000-0000-0000-000000000011';

-- 6.2 Debe FALLAR: vale con solicitud inexistente (clave foránea)
SAVEPOINT p1;
INSERT INTO RET_VALE_COMPRA (solicitud_cambio_id, boleta_numero, cliente_id, tienda_id, monto_a_favor, saldo_disponible)
VALUES (gen_random_uuid(), 'B001-00000046', gen_random_uuid(), 'TIENDA-MIRAFLORES', 10.00, 10.00);
ROLLBACK TO SAVEPOINT p1;

-- 6.3 Debe FALLAR: segundo vale para la misma solicitud (evita el doble canje)
SAVEPOINT p2;
INSERT INTO RET_VALE_COMPRA (solicitud_cambio_id, boleta_numero, cliente_id, tienda_id, monto_a_favor, saldo_disponible)
VALUES ('bbbbbbbb-0000-0000-0000-000000000011', 'B001-00000045', gen_random_uuid(), 'TIENDA-MIRAFLORES', 10.00, 10.00);
ROLLBACK TO SAVEPOINT p2;

-- 6.4 Debe FALLAR: boleta con formato inválido
SAVEPOINT p3;
UPDATE RET_VALE_COMPRA SET boleta_numero = 'XYZ-1' WHERE solicitud_cambio_id = 'bbbbbbbb-0000-0000-0000-000000000011';
ROLLBACK TO SAVEPOINT p3;

-- 6.5 Debe FALLAR: egreso de caja con monto negativo
SAVEPOINT p4;
INSERT INTO RET_MOVIMIENTO_CAJA (caja_sesion_id, tipo_movimiento, monto, motivo, autorizado_por_supervisor)
VALUES ('aaaaaaaa-0000-0000-0000-000000000011', 'SALIDA_GASTO', -5.00, 'Prueba', 'SUP-001');
ROLLBACK TO SAVEPOINT p4;

-- 6.6 Debe FALLAR: borrar el turno que tiene solicitudes de cambio y cobros (ON DELETE RESTRICT)
SAVEPOINT p5;
DELETE FROM RET_CAJA_SESION WHERE id_sesion = 'aaaaaaaa-0000-0000-0000-000000000011';
ROLLBACK TO SAVEPOINT p5;

-- 6.7 Debe FALLAR: cobro asociado a un turno inexistente (clave foránea)
SAVEPOINT p6;
INSERT INTO RET_COBRO_TURNO (caja_sesion_id, idempotency_key, medio_pago, monto_total, monto_recibido, vuelto)
VALUES (gen_random_uuid(), 'evid-0002', 'EFECTIVO', 50.00, 50.00, 0.00);
ROLLBACK TO SAVEPOINT p6;

-- 6.8 Debe FALLAR: segundo cobro con la misma Idempotency-Key (evita el doble cobro)
SAVEPOINT p7;
INSERT INTO RET_COBRO_TURNO (caja_sesion_id, idempotency_key, medio_pago, monto_total, monto_recibido, vuelto)
VALUES ('aaaaaaaa-0000-0000-0000-000000000011', 'evid-0001', 'EFECTIVO', 116.91, 120.00, 3.09);
ROLLBACK TO SAVEPOINT p7;

-- 6.9 Debe FALLAR: cobro cuyo vuelto no cuadra con lo recibido
SAVEPOINT p8;
INSERT INTO RET_COBRO_TURNO (caja_sesion_id, idempotency_key, medio_pago, monto_total, monto_recibido, vuelto)
VALUES ('aaaaaaaa-0000-0000-0000-000000000011', 'evid-0003', 'EFECTIVO', 100.00, 120.00, 5.00);
ROLLBACK TO SAVEPOINT p8;

-- Todo se deshace: no queda ningún dato de prueba
ROLLBACK;

-- Verificación posterior: debe dar 0
SELECT count(*) FROM RET_CAJA_SESION WHERE terminal_pos_codigo = 'POS-EVID';
