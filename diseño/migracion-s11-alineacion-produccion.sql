-- =============================================================================
-- MIGRACIÓN S11 — ALINEACIÓN DE PRODUCCIÓN (Supabase) CON EL BACKEND DE develop
-- Retail (Grupo 4) — Ciclo 2026-II
--
-- Motivo: la base de producción tiene aplicado solo en parte schema-s11.sql y no tiene
-- el esquema de ventas de F5 (backend: src/main/resources/db/registro-venta.sql).
-- Como el perfil supabase usa ddl-auto=none, sin esta migración fallan en producción:
--   * F5  POST de venta real       -> faltan ret_venta, ret_venta_item, ret_venta_operacion
--                                     y las secuencias ret_comprobante_b001/f001_seq
--   * F9  emisión de vales         -> ret_vale_compra conserva solicitud_cambio_id,
--                                     monto_a_favor y saldo_disponible; falta ret_vale_codigo_seq
--   * F9  registro de cambios      -> pedido_id_origen y variante_sku_devuelta_id son UUID
--                                     (el backend guarda texto), cliente_id es NOT NULL y
--                                     falta venta_id
--
-- Es idempotente y corre en una sola transacción.
-- =============================================================================
BEGIN;

-- -----------------------------------------------------------------------------
-- 1. Esquema de ventas confirmado (F5), igual a registro-venta.sql del backend
-- -----------------------------------------------------------------------------
CREATE SEQUENCE IF NOT EXISTS ret_comprobante_b001_seq START WITH 1 MAXVALUE 99999999 NO CYCLE;
CREATE SEQUENCE IF NOT EXISTS ret_comprobante_f001_seq START WITH 1 MAXVALUE 99999999 NO CYCLE;
CREATE SEQUENCE IF NOT EXISTS ret_vale_codigo_seq      START WITH 1 MAXVALUE 99999    NO CYCLE;

CREATE TABLE IF NOT EXISTS ret_venta (
    id_venta UUID PRIMARY KEY,
    caja_sesion_id UUID NOT NULL REFERENCES ret_caja_sesion (id_sesion),
    tienda_id VARCHAR(50) NOT NULL,
    pedido_id TEXT NOT NULL UNIQUE,
    estado_pedido VARCHAR(20) NOT NULL DEFAULT 'PAGADO' CHECK (estado_pedido IN ('PAGADO', 'ENTREGADO')),
    serie VARCHAR(4) NOT NULL CHECK (serie IN ('B001', 'F001')),
    correlativo INTEGER NOT NULL CHECK (correlativo BETWEEN 1 AND 99999999),
    fecha_emision TIMESTAMP WITH TIME ZONE NOT NULL,
    total NUMERIC(12, 2) NOT NULL CHECK (total >= 0),
    UNIQUE (serie, correlativo)
);

CREATE TABLE IF NOT EXISTS ret_venta_item (
    venta_id UUID NOT NULL REFERENCES ret_venta (id_venta),
    numero_linea INTEGER NOT NULL CHECK (numero_linea > 0),
    sku TEXT NOT NULL,
    cantidad INTEGER NOT NULL CHECK (cantidad > 0),
    precio_unitario_pagado NUMERIC(12, 2) NOT NULL CHECK (precio_unitario_pagado >= 0),
    PRIMARY KEY (venta_id, numero_linea)
);

CREATE TABLE IF NOT EXISTS ret_venta_operacion (
    clave VARCHAR(64) PRIMARY KEY,
    usuario_id UUID NOT NULL,
    huella VARCHAR(64) NOT NULL,
    fecha_operacion TIMESTAMP WITH TIME ZONE NOT NULL,
    lineas TEXT NOT NULL,
    respuesta TEXT
);

-- Mismo criterio que el resto de tablas RET_*: RLS activo (el backend entra como postgres).
ALTER TABLE ret_venta           ENABLE ROW LEVEL SECURITY;
ALTER TABLE ret_venta_item      ENABLE ROW LEVEL SECURITY;
ALTER TABLE ret_venta_operacion ENABLE ROW LEVEL SECURITY;

-- El backend numera los vales con ret_vale_codigo_seq: continuar después de los ya emitidos.
SELECT setval('ret_vale_codigo_seq',
              GREATEST(COALESCE((SELECT MAX(substring(codigo_vale FROM '[0-9]+$')::int) FROM ret_vale_compra), 0), 1),
              EXISTS (SELECT 1 FROM ret_vale_compra));

-- -----------------------------------------------------------------------------
-- 2. RET_SOLICITUD_CAMBIO_MOSTRADOR: tipos y nulabilidad que usa la entidad SolicitudCambio
-- -----------------------------------------------------------------------------
ALTER TABLE ret_solicitud_cambio_mostrador ADD COLUMN IF NOT EXISTS venta_id UUID NULL;

DO $$
BEGIN
    IF (SELECT data_type FROM information_schema.columns WHERE table_schema = 'public'
          AND table_name = 'ret_solicitud_cambio_mostrador' AND column_name = 'pedido_id_origen') = 'uuid' THEN
        ALTER TABLE ret_solicitud_cambio_mostrador
            ALTER COLUMN pedido_id_origen TYPE TEXT USING pedido_id_origen::text;
    END IF;
    IF (SELECT data_type FROM information_schema.columns WHERE table_schema = 'public'
          AND table_name = 'ret_solicitud_cambio_mostrador' AND column_name = 'variante_sku_devuelta_id') = 'uuid' THEN
        ALTER TABLE ret_solicitud_cambio_mostrador
            ALTER COLUMN variante_sku_devuelta_id TYPE TEXT USING variante_sku_devuelta_id::text;
    END IF;
END $$;

ALTER TABLE ret_solicitud_cambio_mostrador ALTER COLUMN pedido_id_origen DROP NOT NULL;
ALTER TABLE ret_solicitud_cambio_mostrador ALTER COLUMN cliente_id DROP NOT NULL;

-- Filas de semilla anteriores a S11: la entidad lee cantidad como int primitivo.
UPDATE ret_solicitud_cambio_mostrador SET cantidad = 1 WHERE cantidad IS NULL;

-- -----------------------------------------------------------------------------
-- 3. RET_VALE_COMPRA: completar la migración evolutiva de schema-s11.sql
-- -----------------------------------------------------------------------------
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public'
                 AND table_name = 'ret_vale_compra' AND column_name = 'solicitud_cambio_id') THEN
        ALTER TABLE ret_vale_compra RENAME COLUMN solicitud_cambio_id TO solicitud_id;
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public'
                 AND table_name = 'ret_vale_compra' AND column_name = 'monto_a_favor') THEN
        ALTER TABLE ret_vale_compra RENAME COLUMN monto_a_favor TO monto;
    END IF;
    -- Quita también los CHECK que dependen de saldo_disponible (incluido chk_vale_canje_coherente).
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public'
                 AND table_name = 'ret_vale_compra' AND column_name = 'saldo_disponible') THEN
        ALTER TABLE ret_vale_compra DROP COLUMN saldo_disponible;
    END IF;
END $$;

ALTER TABLE ret_vale_compra ALTER COLUMN cliente_id DROP NOT NULL;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_vale_canje_coherente') THEN
        ALTER TABLE ret_vale_compra ADD CONSTRAINT chk_vale_canje_coherente
            CHECK ((estado = 'CANJEADO' AND fecha_canje IS NOT NULL) OR (estado <> 'CANJEADO' AND fecha_canje IS NULL));
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ux_ret_vale_compra_solicitud') THEN
        ALTER TABLE ret_vale_compra ADD CONSTRAINT ux_ret_vale_compra_solicitud UNIQUE (solicitud_id);
    END IF;
END $$;

COMMIT;
