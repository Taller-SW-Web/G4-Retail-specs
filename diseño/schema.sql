-- =============================================================================
-- ESQUEMA DDL FÍSICO — BASE DE DATOS RETAIL (GRUPO 4)
-- Marketplace Multicanal de Artículos Deportivos — Ciclo 2026-II
-- Motor Recomendado: PostgreSQL 15+ (Compatible con UUID nativo y JSONB)
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- -----------------------------------------------------------------------------
-- 1. TABLA: RET_CAJA_SESION
-- Control de turnos, fondo fijo y arqueo ciego en mostrador (F8)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS RET_CAJA_SESION (
    id_sesion               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tienda_id               UUID NOT NULL,
    terminal_pos_codigo     VARCHAR(20) NOT NULL,
    vendedor_id             UUID NOT NULL, -- Ref. externa lógica: Módulo Seguridad
    fecha_hora_apertura     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    saldo_inicial_efectivo  DECIMAL(12, 2) NOT NULL CHECK (saldo_inicial_efectivo >= 0),
    fecha_hora_cierre       TIMESTAMP NULL,
    saldo_final_declarado   DECIMAL(12, 2) NULL, -- Arqueo ciego digitado por cajero
    saldo_final_sistema     DECIMAL(12, 2) NULL, -- Calculado por sistema
    diferencia_saldo        DECIMAL(12, 2) NULL, -- Diferencia: declarado - sistema
    estado                  VARCHAR(20) NOT NULL DEFAULT 'ABIERTA' 
                            CHECK (estado IN ('ABIERTA', 'CERRADA', 'OBSERVADA')),
    observaciones_cierre    TEXT NULL,
    created_at              TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at              TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- 2. TABLA: RET_MOVIMIENTO_CAJA
-- Movimientos menores de efectivo durante el turno (F8)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS RET_MOVIMIENTO_CAJA (
    id_movimiento           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    caja_sesion_id          UUID NOT NULL,
    tipo_movimiento         VARCHAR(30) NOT NULL 
                            CHECK (tipo_movimiento IN ('INGRESO_MENOR', 'SALIDA_GASTO')),
    monto                   DECIMAL(12, 2) NOT NULL CHECK (monto > 0),
    motivo                  TEXT NOT NULL,
    autorizado_por_supervisor VARCHAR(100) NOT NULL,
    fecha_hora              TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_movimiento_caja_sesion 
        FOREIGN KEY (caja_sesion_id) REFERENCES RET_CAJA_SESION(id_sesion) ON DELETE CASCADE
);

-- -----------------------------------------------------------------------------
-- 3. TABLA: RET_CARRITO_ESPERA
-- Suspensión y retención temporal de carritos para probadores (F4)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS RET_CARRITO_ESPERA (
    id_carrito_espera       UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tienda_id               UUID NOT NULL,
    vendedor_id             UUID NOT NULL, -- Ref. externa lógica: Módulo Seguridad
    cliente_id              UUID NULL,     -- Ref. externa lógica opcional: Módulo Seguridad
    alias_ticket            VARCHAR(80) NOT NULL,
    subtotal_estimado       DECIMAL(12, 2) NOT NULL DEFAULT 0 CHECK (subtotal_estimado >= 0),
    fecha_creacion          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_expiracion_reserva TIMESTAMP NOT NULL,
    estado                  VARCHAR(20) NOT NULL DEFAULT 'SUSPENDIDO'
                            CHECK (estado IN ('SUSPENDIDO', 'REANUDADO', 'EXPIRADO'))
);

-- -----------------------------------------------------------------------------
-- 4. TABLA: RET_CARRITO_ESPERA_ITEM
-- Detalle de artículos dentro del carrito suspendido (F4)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS RET_CARRITO_ESPERA_ITEM (
    id_item                 UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    carrito_espera_id       UUID NOT NULL,
    producto_id             UUID NOT NULL, -- Ref. externa lógica: Módulo Productos
    variante_sku_id         UUID NOT NULL, -- Ref. externa lógica: Módulo Productos
    nombre_producto         VARCHAR(150) NOT NULL,
    talla_color             VARCHAR(50) NOT NULL,
    cantidad                INTEGER NOT NULL CHECK (cantidad > 0),
    precio_unitario         DECIMAL(12, 2) NOT NULL CHECK (precio_unitario >= 0),
    CONSTRAINT fk_item_carrito_espera 
        FOREIGN KEY (carrito_espera_id) REFERENCES RET_CARRITO_ESPERA(id_carrito_espera) ON DELETE CASCADE
);

-- -----------------------------------------------------------------------------
-- 5. TABLA: RET_SOLICITUD_CAMBIO_MOSTRADOR
-- Recepción e inspección física de prendas para cambio en tienda (F9)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS RET_SOLICITUD_CAMBIO_MOSTRADOR (
    id_solicitud            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    caja_sesion_id          UUID NOT NULL,
    pedido_id_origen        UUID NOT NULL, -- Ref. externa lógica: Módulo Ventas
    variante_sku_devuelta_id UUID NOT NULL, -- Ref. externa lógica: Módulo Productos
    cliente_id              UUID NOT NULL, -- Ref. externa lógica: Módulo Seguridad
    motivo_cambio           VARCHAR(50) NOT NULL,
    inspeccion_etiquetas    BOOLEAN NOT NULL DEFAULT FALSE,
    inspeccion_sin_uso      BOOLEAN NOT NULL DEFAULT FALSE,
    inspeccion_empaque      BOOLEAN NOT NULL DEFAULT FALSE,
    estado_aprobacion       VARCHAR(30) NOT NULL 
                            CHECK (estado_aprobacion IN ('APROBADO_EN_TIENDA', 'RECHAZADO')),
    vale_temporal_codigo    VARCHAR(50) NULL,
    monto_acreditado        DECIMAL(12, 2) NOT NULL DEFAULT 0 CHECK (monto_acreditado >= 0),
    fecha_inspeccion        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_cambio_caja_sesion 
        FOREIGN KEY (caja_sesion_id) REFERENCES RET_CAJA_SESION(id_sesion) ON DELETE RESTRICT
);

-- -----------------------------------------------------------------------------
-- 6. TABLA: RET_INCIDENCIA_INVENTARIO
-- Reporte y cuarentena de prendas dañadas o mermas en mostrador (F12)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS RET_INCIDENCIA_INVENTARIO (
    id_incidencia           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tienda_id               UUID NOT NULL,
    vendedor_reporta_id     UUID NOT NULL, -- Ref. externa lógica: Módulo Seguridad
    variante_sku_id         UUID NOT NULL, -- Ref. externa lógica: Módulo Productos
    codigo_barras           VARCHAR(50) NOT NULL,
    tipo_falla              VARCHAR(50) NOT NULL,
    detalle_observacion     TEXT NOT NULL,
    evidencia_foto_url      VARCHAR(255) NULL,
    estado_cuarentena       VARCHAR(30) NOT NULL DEFAULT 'EN_CUARENTENA'
                            CHECK (estado_cuarentena IN ('EN_CUARENTENA', 'DERIVADO_ALMACEN', 'DESCARTADO', 'RECHAZADO')),
    fecha_reporte           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- 7. TABLA: RET_CONTINGENCIA_OFFLINE_LOG
-- Cola de sincronización y resiliencia para ventas sin conexión (F10)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS RET_CONTINGENCIA_OFFLINE_LOG (
    id_log                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tienda_id               UUID NOT NULL,
    terminal_pos_codigo     VARCHAR(20) NOT NULL,
    venta_local_uuid        VARCHAR(64) NOT NULL UNIQUE,
    payload_json_orden      JSONB NOT NULL,
    firma_hash_seguridad    VARCHAR(64) NOT NULL,
    estado_sincronizacion   VARCHAR(20) NOT NULL DEFAULT 'PENDIENTE'
                            CHECK (estado_sincronizacion IN ('PENDIENTE', 'RESINCRONIZADO', 'CONFLICTO')),
    fecha_emision_offline   TIMESTAMP NOT NULL,
    fecha_sincronizacion    TIMESTAMP NULL,
    error_detalle           TEXT NULL
);

-- -----------------------------------------------------------------------------
-- 8. TABLA: RET_PERSONAL_TIENDA
-- Perfiles y roles operativos del personal dentro de la sucursal (F1, F8)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS RET_PERSONAL_TIENDA (
    id_personal             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    usuario_id              UUID NOT NULL UNIQUE, -- Identificador lógico del usuario ('sub')
    tienda_id               UUID NOT NULL,
    codigo_vendedor         VARCHAR(20) NOT NULL,
    perfil_tienda           VARCHAR(20) NOT NULL 
                            CHECK (perfil_tienda IN ('VENDEDOR', 'CAJERO', 'SUPERVISOR')),
    activo                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at              TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at              TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- ÍNDICES DE CONSULTA FRECUENTE
-- -----------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_caja_sesion_tienda_vendedor ON RET_CAJA_SESION(tienda_id, vendedor_id, estado);
CREATE INDEX IF NOT EXISTS idx_carrito_espera_tienda_estado ON RET_CARRITO_ESPERA(tienda_id, estado);
CREATE INDEX IF NOT EXISTS idx_offline_log_estado ON RET_CONTINGENCIA_OFFLINE_LOG(tienda_id, estado_sincronizacion);
CREATE INDEX IF NOT EXISTS idx_incidencia_tienda_estado ON RET_INCIDENCIA_INVENTARIO(tienda_id, estado_cuarentena);
CREATE INDEX IF NOT EXISTS idx_personal_tienda_usuario ON RET_PERSONAL_TIENDA(usuario_id, tienda_id, activo);
