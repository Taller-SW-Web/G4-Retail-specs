-- =============================================================================
-- MIGRACIÓN S14 (HITO 5) — F12: INCIDENCIAS DE INVENTARIO, CUARENTENA Y ACTAS DE MERMA
-- Marketplace Multicanal de Artículos Deportivos — Retail (Grupo 4) — Ciclo 2026-II
-- Responsable: Angie (DBA)
--
-- Requiere haber ejecutado antes diseño/schema.sql (crea RET_INCIDENCIA_INVENTARIO y la
-- función update_updated_at_column). Es idempotente y corre en una sola transacción.
--
-- Alinea la persistencia de F12 con el contrato v0.4 (§5.12) y el hallazgo G4-P0-05:
-- la cuarentena de Retail es una PROYECCIÓN LOCAL de la incidencia que se reporta a
-- Inventory (G6); el saldo central lo lleva Inventory.
--
-- Cambios:
--   1. RET_ACTA_DISCREPANCIA (nueva): acta de merma (RF-34) y secuencia ret_acta_merma_seq
--      para el correlativo ACTA-MERMA-AAAA-NNNN que arma la API
--   2. RET_INCIDENCIA_INVENTARIO:
--        - variante_sku_id pasa de UUID a TEXT (el SKU es un identificador opaco de G6, §2.2)
--        - estados: EN_CUARENTENA, DERIVADO_ALMACEN, BAJA_DEFINITIVA, PENDIENTE_REPORTE (§5.12)
--        - + nombre_producto, + idempotency_key, + incidencia_inventory_id, + acta_id,
--          + intentos_reporte, + ultimo_error_reporte, + updated_at
--   3. Índices para la bandeja de cuarentena, el bloqueo del carrito y el reenvío a Inventory
--   4. RLS y políticas (mismo criterio que el resto de tablas RET_*)
--
-- Cuarentena ACTIVA (bloquea la venta en el POS, RF-33) = EN_CUARENTENA o PENDIENTE_REPORTE.
-- =============================================================================
BEGIN;

-- -----------------------------------------------------------------------------
-- 1. SECUENCIA DEL NÚMERO DE ACTA
--    La API la lee y arma ACTA-MERMA-AAAA-NNNN, igual que ret_vale_codigo_seq para el vale.
-- -----------------------------------------------------------------------------
CREATE SEQUENCE IF NOT EXISTS ret_acta_merma_seq START WITH 1 INCREMENT BY 1 MAXVALUE 9999 NO CYCLE;

-- -----------------------------------------------------------------------------
-- 2. TABLA: RET_ACTA_DISCREPANCIA (RF-34)
--    Documenta la salida de las prendas en cuarentena. No cierra el caso en Inventory.
--    Columnas acordadas con Cristhian (entidad ActaDiscrepancia).
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS RET_ACTA_DISCREPANCIA (
    id_acta                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    numero_acta             VARCHAR(30) NOT NULL UNIQUE
                            CHECK (numero_acta ~ '^ACTA-MERMA-[0-9]{4}-[0-9]{4}$'),
    tienda_id               TEXT NOT NULL,
    supervisor_id           UUID NOT NULL, -- Ref. externa lógica: Seguridad (SUPERVISOR que emite)
    tipo_destino            VARCHAR(30) NOT NULL
                            CHECK (tipo_destino IN ('DEVOLUCION_CENTRAL', 'BAJA_DEFINITIVA', 'AJUSTE_PERDIDA')),
    observaciones           TEXT NULL,
    total_prendas           INTEGER NOT NULL CHECK (total_prendas > 0),
    fecha_emision           TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- 3. RET_INCIDENCIA_INVENTARIO: alineación con §5.12
-- -----------------------------------------------------------------------------

-- 3.1 El SKU es texto opaco de Productos (G6), no un UUID propio de Retail.
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
         WHERE table_schema = 'public' AND table_name = 'ret_incidencia_inventario'
           AND column_name = 'variante_sku_id' AND data_type = 'uuid'
    ) THEN
        ALTER TABLE RET_INCIDENCIA_INVENTARIO
            ALTER COLUMN variante_sku_id TYPE TEXT USING variante_sku_id::text;
    END IF;
END $$;

-- 3.2 Columnas nuevas
ALTER TABLE RET_INCIDENCIA_INVENTARIO
    ADD COLUMN IF NOT EXISTS nombre_producto         VARCHAR(150) NULL,
    ADD COLUMN IF NOT EXISTS idempotency_key         VARCHAR(64)  NULL,
    ADD COLUMN IF NOT EXISTS incidencia_inventory_id TEXT         NULL,
    ADD COLUMN IF NOT EXISTS acta_id                 UUID         NULL,
    ADD COLUMN IF NOT EXISTS intentos_reporte        INTEGER      NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS ultimo_error_reporte    TEXT         NULL,
    ADD COLUMN IF NOT EXISTS updated_at              TIMESTAMPTZ  NOT NULL DEFAULT CURRENT_TIMESTAMP;

-- 3.3 Estados de §5.12. schema.sql traía DESCARTADO y RECHAZADO, que el contrato ya no usa.
--     DESCARTADO equivale a BAJA_DEFINITIVA. RECHAZADO no tiene equivalente: las filas en ese
--     estado son datos de prueba cargados a mano (F12 no tenía backend antes de S14), así que
--     se eliminan. Ninguna tabla las referencia todavía.
ALTER TABLE RET_INCIDENCIA_INVENTARIO
    DROP CONSTRAINT IF EXISTS ret_incidencia_inventario_estado_cuarentena_check;

UPDATE RET_INCIDENCIA_INVENTARIO
   SET estado_cuarentena = 'BAJA_DEFINITIVA'
 WHERE estado_cuarentena = 'DESCARTADO';

DELETE FROM RET_INCIDENCIA_INVENTARIO
 WHERE estado_cuarentena = 'RECHAZADO';

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_incidencia_estado') THEN
        ALTER TABLE RET_INCIDENCIA_INVENTARIO
            ADD CONSTRAINT chk_incidencia_estado
            CHECK (estado_cuarentena IN ('EN_CUARENTENA', 'DERIVADO_ALMACEN', 'BAJA_DEFINITIVA', 'PENDIENTE_REPORTE'));
    END IF;

    -- RF-32: la observación tiene al menos 5 caracteres. NOT VALID: se exige a las filas nuevas
    -- y no hace fallar la migración por algún dato de prueba antiguo con texto corto.
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_incidencia_observacion_min') THEN
        ALTER TABLE RET_INCIDENCIA_INVENTARIO
            ADD CONSTRAINT chk_incidencia_observacion_min
            CHECK (char_length(btrim(detalle_observacion)) >= 5) NOT VALID;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_incidencia_intentos') THEN
        ALTER TABLE RET_INCIDENCIA_INVENTARIO
            ADD CONSTRAINT chk_incidencia_intentos CHECK (intentos_reporte >= 0);
    END IF;

    -- Una incidencia incluida en un acta ya salió de la cuarentena activa
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_incidencia_acta_coherente') THEN
        ALTER TABLE RET_INCIDENCIA_INVENTARIO
            ADD CONSTRAINT chk_incidencia_acta_coherente
            CHECK (acta_id IS NULL OR estado_cuarentena IN ('DERIVADO_ALMACEN', 'BAJA_DEFINITIVA'));
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_incidencia_acta') THEN
        ALTER TABLE RET_INCIDENCIA_INVENTARIO
            ADD CONSTRAINT fk_incidencia_acta
            FOREIGN KEY (acta_id) REFERENCES RET_ACTA_DISCREPANCIA(id_acta) ON DELETE RESTRICT;
    END IF;
END $$;

DROP TRIGGER IF EXISTS trg_ret_incidencia_inventario_updated_at ON RET_INCIDENCIA_INVENTARIO;
CREATE TRIGGER trg_ret_incidencia_inventario_updated_at
    BEFORE UPDATE ON RET_INCIDENCIA_INVENTARIO
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- -----------------------------------------------------------------------------
-- 4. ÍNDICES
-- -----------------------------------------------------------------------------
-- POST /incidencias es idempotente (🔁): un reintento con la misma clave no crea otra fila
CREATE UNIQUE INDEX IF NOT EXISTS ux_ret_incidencia_clave
    ON RET_INCIDENCIA_INVENTARIO (idempotency_key) WHERE idempotency_key IS NOT NULL;

-- RF-33: bloqueo del carrito por SKU en cuarentena activa
CREATE INDEX IF NOT EXISTS idx_incidencia_sku_activa
    ON RET_INCIDENCIA_INVENTARIO (tienda_id, variante_sku_id)
    WHERE estado_cuarentena IN ('EN_CUARENTENA', 'PENDIENTE_REPORTE');

-- Reenvío a Inventory (G6) de las incidencias que aún no aceptó
CREATE INDEX IF NOT EXISTS idx_incidencia_pendiente_reporte
    ON RET_INCIDENCIA_INVENTARIO (fecha_reporte)
    WHERE estado_cuarentena = 'PENDIENTE_REPORTE';

CREATE INDEX IF NOT EXISTS idx_incidencia_acta    ON RET_INCIDENCIA_INVENTARIO (acta_id) WHERE acta_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_acta_tienda_fecha  ON RET_ACTA_DISCREPANCIA (tienda_id, fecha_emision DESC);
-- idx_incidencia_tienda_estado (tienda_id, estado_cuarentena) ya existe desde schema.sql

-- -----------------------------------------------------------------------------
-- 5. ROW LEVEL SECURITY — RET_ACTA_DISCREPANCIA
-- -----------------------------------------------------------------------------
ALTER TABLE RET_ACTA_DISCREPANCIA ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'ret_acta_discrepancia' AND policyname = 'ret_acta_discrepancia_auth_policy') THEN
        CREATE POLICY "ret_acta_discrepancia_auth_policy" ON RET_ACTA_DISCREPANCIA FOR ALL TO authenticated USING (true) WITH CHECK (true);
    END IF;
END $$;

COMMIT;
