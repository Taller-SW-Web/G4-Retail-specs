-- =============================================================================
-- MIGRACIÓN S14 (HITO 5) — F9: CAMBIO DIRECTO DE PRENDA EN MOSTRADOR
-- Marketplace Multicanal de Artículos Deportivos — Retail (Grupo 4) — Ciclo 2026-II
-- Responsable: Angie (DBA) · Columnas acordadas con Cristhian (entidades de F9)
--
-- Requiere haber ejecutado antes diseño/schema.sql, diseño/schema-s11.sql y
-- diseño/migracion-s11-alineacion-produccion.sql (crea RET_VENTA). Es idempotente y corre
-- en una sola transacción.
--
-- Contrato v0.5.4, §5.9 (decisión del PO del 25/11): el cambio directo reemplaza al vale.
-- RET_VALE_COMPRA no se toca: queda en desuso, con sus registros de la S11.
--
-- Cambios:
--   1. RET_SOLICITUD_CAMBIO_MOSTRADOR: tipo de cambio, constancia, montos, pedido nuevo en Ventas,
--      venta de la boleta (MAYOR_VALOR), estado del envío a Ventas y la huella y respuesta de la
--      idempotencia. Todas NULL, salvo
--      intentos_envio (DEFAULT 0), para no romper las filas del vale de la S11.
--   2. RET_SOLICITUD_CAMBIO_ITEM (nueva): prendas nuevas que se lleva el cliente.
--   3. RET_CORRELATIVO (nueva): correlativos que reinician por tienda y año
--      (constancia CAMB-AAAA-NNNNNN). Una secuencia no sirve porque no reinicia.
--   4. Índices y RLS.
-- =============================================================================
BEGIN;

-- -----------------------------------------------------------------------------
-- 1. RET_SOLICITUD_CAMBIO_MOSTRADOR: columnas del cambio directo
-- -----------------------------------------------------------------------------
ALTER TABLE RET_SOLICITUD_CAMBIO_MOSTRADOR
    ADD COLUMN IF NOT EXISTS tipo_cambio       VARCHAR(20)    NULL,
    ADD COLUMN IF NOT EXISTS numero_constancia VARCHAR(20)    NULL,
    ADD COLUMN IF NOT EXISTS monto_credito     DECIMAL(12, 2) NULL,
    ADD COLUMN IF NOT EXISTS total_nuevo       DECIMAL(12, 2) NULL,
    ADD COLUMN IF NOT EXISTS diferencia        DECIMAL(12, 2) NULL,
    ADD COLUMN IF NOT EXISTS pedido_id_nuevo   TEXT           NULL,  -- Pedido creado en Ventas (G5)
    ADD COLUMN IF NOT EXISTS venta_nueva_id    UUID           NULL,  -- Boleta del MAYOR_VALOR; NULL en MISMO_VALOR
    ADD COLUMN IF NOT EXISTS estado_inventario VARCHAR(20)    NULL,
    ADD COLUMN IF NOT EXISTS pedido_pendiente  TEXT           NULL,  -- Pedido a reenviar si Ventas respondió 503
    ADD COLUMN IF NOT EXISTS intentos_envio    INTEGER        NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS huella            VARCHAR(64)    NULL,  -- Hash del cuerpo: un reintento con la misma clave y otro cuerpo es 409
    ADD COLUMN IF NOT EXISTS respuesta         TEXT           NULL;  -- Respuesta guardada que se devuelve igual en un reintento

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_cambio_tipo') THEN
        ALTER TABLE RET_SOLICITUD_CAMBIO_MOSTRADOR
            ADD CONSTRAINT chk_cambio_tipo
            CHECK (tipo_cambio IS NULL OR tipo_cambio IN ('MISMO_VALOR', 'MAYOR_VALOR'));
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_cambio_constancia_formato') THEN
        ALTER TABLE RET_SOLICITUD_CAMBIO_MOSTRADOR
            ADD CONSTRAINT chk_cambio_constancia_formato
            CHECK (numero_constancia IS NULL OR numero_constancia ~ '^CAMB-[0-9]{4}-[0-9]{6}$');
    END IF;

    -- Los tres montos son >= 0. No se fuerza diferencia = total_nuevo - monto_credito: en un cambio
    -- del mismo modelo es MISMO_VALOR con diferencia 0 aunque el precio vigente haya cambiado (§5.9).
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_cambio_montos') THEN
        ALTER TABLE RET_SOLICITUD_CAMBIO_MOSTRADOR
            ADD CONSTRAINT chk_cambio_montos
            CHECK ((monto_credito IS NULL OR monto_credito >= 0)
               AND (total_nuevo   IS NULL OR total_nuevo   >= 0)
               AND (diferencia    IS NULL OR diferencia    >= 0));
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_cambio_estado_inventario') THEN
        ALTER TABLE RET_SOLICITUD_CAMBIO_MOSTRADOR
            ADD CONSTRAINT chk_cambio_estado_inventario
            CHECK (estado_inventario IS NULL OR estado_inventario IN ('PENDIENTE', 'CONFIRMADO'));
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_cambio_intentos_envio') THEN
        ALTER TABLE RET_SOLICITUD_CAMBIO_MOSTRADOR
            ADD CONSTRAINT chk_cambio_intentos_envio CHECK (intentos_envio >= 0);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_cambio_venta_nueva') THEN
        ALTER TABLE RET_SOLICITUD_CAMBIO_MOSTRADOR
            ADD CONSTRAINT fk_cambio_venta_nueva
            FOREIGN KEY (venta_nueva_id) REFERENCES RET_VENTA(id_venta) ON DELETE RESTRICT;
    END IF;
END $$;

-- La constancia es correlativa por año y tienda: única dentro de cada tienda
CREATE UNIQUE INDEX IF NOT EXISTS ux_cambio_tienda_constancia
    ON RET_SOLICITUD_CAMBIO_MOSTRADOR (tienda_id, numero_constancia)
    WHERE numero_constancia IS NOT NULL;

-- Job que reenvía a Ventas los cambios pendientes cada 5 minutos
CREATE INDEX IF NOT EXISTS idx_cambio_estado_inventario_pendiente
    ON RET_SOLICITUD_CAMBIO_MOSTRADOR (fecha_inspeccion)
    WHERE estado_inventario = 'PENDIENTE';

CREATE INDEX IF NOT EXISTS idx_cambio_venta_nueva
    ON RET_SOLICITUD_CAMBIO_MOSTRADOR (venta_nueva_id)
    WHERE venta_nueva_id IS NOT NULL;

-- -----------------------------------------------------------------------------
-- 2. TABLA: RET_SOLICITUD_CAMBIO_ITEM (prendas nuevas del cambio)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS RET_SOLICITUD_CAMBIO_ITEM (
    id_item          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    solicitud_id     UUID NOT NULL,
    sku              TEXT NOT NULL,              -- SKU opaco de Productos (G6)
    cantidad         INTEGER NOT NULL CHECK (cantidad > 0),
    precio_unitario  DECIMAL(12, 2) NOT NULL CHECK (precio_unitario >= 0),
    CONSTRAINT fk_cambio_item_solicitud
        FOREIGN KEY (solicitud_id) REFERENCES RET_SOLICITUD_CAMBIO_MOSTRADOR(id_solicitud) ON DELETE RESTRICT
);

CREATE INDEX IF NOT EXISTS idx_cambio_item_solicitud ON RET_SOLICITUD_CAMBIO_ITEM (solicitud_id);

-- -----------------------------------------------------------------------------
-- 3. TABLA: RET_CORRELATIVO (correlativos por tienda, año y tipo)
--    La API toma el siguiente número con un UPDATE ... SET ultimo = ultimo + 1 ... RETURNING
--    (o un INSERT ... ON CONFLICT para el primero del año), dentro de la transacción del cambio.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS RET_CORRELATIVO (
    tienda_id   TEXT        NOT NULL,
    anio        INTEGER     NOT NULL CHECK (anio BETWEEN 2000 AND 9999),
    tipo        VARCHAR(20) NOT NULL,
    ultimo      INTEGER     NOT NULL DEFAULT 0 CHECK (ultimo >= 0),
    CONSTRAINT pk_ret_correlativo PRIMARY KEY (tienda_id, anio, tipo)
);

-- -----------------------------------------------------------------------------
-- 4. ROW LEVEL SECURITY (mismo criterio que el resto de tablas RET_*)
-- -----------------------------------------------------------------------------
ALTER TABLE RET_SOLICITUD_CAMBIO_ITEM ENABLE ROW LEVEL SECURITY;
ALTER TABLE RET_CORRELATIVO           ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'ret_solicitud_cambio_item' AND policyname = 'ret_solicitud_cambio_item_auth_policy') THEN
        CREATE POLICY "ret_solicitud_cambio_item_auth_policy" ON RET_SOLICITUD_CAMBIO_ITEM FOR ALL TO authenticated USING (true) WITH CHECK (true);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'ret_correlativo' AND policyname = 'ret_correlativo_auth_policy') THEN
        CREATE POLICY "ret_correlativo_auth_policy" ON RET_CORRELATIVO FOR ALL TO authenticated USING (true) WITH CHECK (true);
    END IF;
END $$;

COMMIT;
