-- =====================================================================
-- LogiTrack - shipment-service
-- Script inicial de base de datos (MySQL 8)
-- Se ejecuta automáticamente la PRIMERA vez que se crea el contenedor
-- de MySQL (volumen vacío). Para re-ejecutarlo: docker compose down -v
-- =====================================================================

SET NAMES utf8mb4;

CREATE DATABASE IF NOT EXISTS logitrack_shipments
    CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE logitrack_shipments;

-- ---------------------------------------------------------------------
-- Clientes
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS clientes (
    id          CHAR(36)     NOT NULL,
    nombre      VARCHAR(120) NOT NULL,
    email       VARCHAR(150) NOT NULL,
    telefono    VARCHAR(30),
    -- Usuario de security-service dueño del cliente (sub del JWT, S2-07). NULL = sin dueño.
    usuario_id  CHAR(36),
    version     BIGINT,
    created_at  DATETIME(6)  NOT NULL,
    updated_at  DATETIME(6),
    CONSTRAINT pk_clientes PRIMARY KEY (id),
    CONSTRAINT uk_clientes_email UNIQUE (email)
);

CREATE INDEX idx_clientes_usuario ON clientes (usuario_id);

-- ---------------------------------------------------------------------
-- Envíos (origen y destino son Value Objects embebidos)
-- repartidor_id es solo una referencia: el repartidor vive en la base
-- de courier-service (logitrack_couriers), no hay FK entre microservicios.
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS envios (
    id                    CHAR(36)      NOT NULL,
    codigo_seguimiento    VARCHAR(20)   NOT NULL,
    cliente_id            CHAR(36)      NOT NULL,
    repartidor_id         CHAR(36),
    origen_calle          VARCHAR(120)  NOT NULL,
    origen_numero         VARCHAR(10)   NOT NULL,
    origen_ciudad         VARCHAR(80)   NOT NULL,
    origen_codigo_postal  VARCHAR(10)   NOT NULL,
    destino_calle         VARCHAR(120)  NOT NULL,
    destino_numero        VARCHAR(10)   NOT NULL,
    destino_ciudad        VARCHAR(80)   NOT NULL,
    destino_codigo_postal VARCHAR(10)   NOT NULL,
    peso_kg               DECIMAL(10,3) NOT NULL,
    alto_cm               DECIMAL(10,2) NOT NULL,
    ancho_cm              DECIMAL(10,2) NOT NULL,
    largo_cm              DECIMAL(10,2) NOT NULL,
    tarifa                DECIMAL(12,2) NOT NULL,
    estado                VARCHAR(20)   NOT NULL,
    version               BIGINT,
    created_at            DATETIME(6)   NOT NULL,
    updated_at            DATETIME(6),
    CONSTRAINT pk_envios PRIMARY KEY (id),
    CONSTRAINT uk_envios_codigo UNIQUE (codigo_seguimiento),
    CONSTRAINT fk_envios_cliente FOREIGN KEY (cliente_id) REFERENCES clientes (id)
);

CREATE INDEX idx_envios_estado ON envios (estado);

-- ---------------------------------------------------------------------
-- Historial de auditoría de cambios de estado
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS historial_estados (
    id               CHAR(36)    NOT NULL,
    envio_id         CHAR(36)    NOT NULL,
    estado_anterior  VARCHAR(20),
    estado_nuevo     VARCHAR(20) NOT NULL,
    fecha_hora       DATETIME(6) NOT NULL,
    version          BIGINT,
    created_at       DATETIME(6) NOT NULL,
    updated_at       DATETIME(6),
    CONSTRAINT pk_historial_estados PRIMARY KEY (id),
    CONSTRAINT fk_historial_envio FOREIGN KEY (envio_id) REFERENCES envios (id)
);

CREATE INDEX idx_historial_envio ON historial_estados (envio_id, fecha_hora);

-- ---------------------------------------------------------------------
-- Datos de prueba
-- ---------------------------------------------------------------------
INSERT INTO clientes (id, nombre, email, telefono, version, created_at, updated_at) VALUES
    ('7a2d9b10-1c3e-4f5a-8b6c-0d1e2f3a4b01', 'Tienda Norte SRL', 'ventas@tiendanorte.com', '+54 388 400-1000', 0, NOW(6), NOW(6));

-- ---------------------------------------------------------------------
-- Envíos de prueba para demo (el repartidor_id apunta a logitrack_couriers)
-- 0001: PENDIENTE sin repartidor (asignación exitosa)
-- 0002: PENDIENTE sin repartidor (rechazo de repartidor inactivo)
-- 0003: EN_RUTA con Brian Abalos
-- 0004: ENTREGADO
-- 0005: CANCELADO
-- ---------------------------------------------------------------------
INSERT INTO envios (id, codigo_seguimiento, cliente_id, repartidor_id,
    origen_calle, origen_numero, origen_ciudad, origen_codigo_postal,
    destino_calle, destino_numero, destino_ciudad, destino_codigo_postal,
    peso_kg, alto_cm, ancho_cm, largo_cm, tarifa, estado, version, created_at, updated_at) VALUES
    ('eeeeeeee-0000-4000-8000-000000000001', 'LT-2026-000001', '7a2d9b10-1c3e-4f5a-8b6c-0d1e2f3a4b01', NULL,
     'Belgrano', '120', 'San Salvador de Jujuy', '4600', 'Lavalle', '450', 'San Salvador de Jujuy', '4600',
     2.500, 20.00, 30.00, 40.00, 3660.00, 'PENDIENTE', 0, NOW(6), NOW(6)),
    ('eeeeeeee-0000-4000-8000-000000000002', 'LT-2026-000002', '7a2d9b10-1c3e-4f5a-8b6c-0d1e2f3a4b01', NULL,
     'Alvear', '800', 'San Salvador de Jujuy', '4600', 'Güemes', '75', 'Palpalá', '4612',
     8.000, 40.00, 50.00, 60.00, 12300.00, 'PENDIENTE', 0, NOW(6), NOW(6)),
    ('eeeeeeee-0000-4000-8000-000000000003', 'LT-2026-000003', '7a2d9b10-1c3e-4f5a-8b6c-0d1e2f3a4b01', '3f6c1a52-8e0b-4d7a-9c11-0a1b2c3d4e01',
     'Belgrano', '120', 'San Salvador de Jujuy', '4600', 'Sarmiento', '300', 'San Salvador de Jujuy', '4600',
     1.200, 10.00, 20.00, 25.00, 2040.00, 'EN_RUTA', 0, NOW(6), NOW(6)),
    ('eeeeeeee-0000-4000-8000-000000000004', 'LT-2026-000004', '7a2d9b10-1c3e-4f5a-8b6c-0d1e2f3a4b01', '3f6c1a52-8e0b-4d7a-9c11-0a1b2c3d4e02',
     'Alvear', '800', 'San Salvador de Jujuy', '4600', 'Necochea', '210', 'San Salvador de Jujuy', '4600',
     0.500, 5.00, 15.00, 20.00, 1725.00, 'ENTREGADO', 0, NOW(6), NOW(6)),
    ('eeeeeeee-0000-4000-8000-000000000005', 'LT-2026-000005', '7a2d9b10-1c3e-4f5a-8b6c-0d1e2f3a4b01', NULL,
     'Belgrano', '120', 'San Salvador de Jujuy', '4600', 'Balcarce', '90', 'Yala', '4600',
     4.000, 25.00, 35.00, 45.00, 5043.75, 'CANCELADO', 0, NOW(6), NOW(6));

INSERT INTO historial_estados (id, envio_id, estado_anterior, estado_nuevo, fecha_hora, version, created_at, updated_at) VALUES
    ('ffffffff-0000-4000-8000-000000000001', 'eeeeeeee-0000-4000-8000-000000000001', NULL, 'PENDIENTE', NOW(6), 0, NOW(6), NOW(6)),
    ('ffffffff-0000-4000-8000-000000000002', 'eeeeeeee-0000-4000-8000-000000000002', NULL, 'PENDIENTE', NOW(6), 0, NOW(6), NOW(6)),
    ('ffffffff-0000-4000-8000-000000000003', 'eeeeeeee-0000-4000-8000-000000000003', NULL, 'PENDIENTE', NOW(6), 0, NOW(6), NOW(6)),
    ('ffffffff-0000-4000-8000-000000000004', 'eeeeeeee-0000-4000-8000-000000000003', 'PENDIENTE', 'EN_RUTA', NOW(6), 0, NOW(6), NOW(6)),
    ('ffffffff-0000-4000-8000-000000000005', 'eeeeeeee-0000-4000-8000-000000000004', NULL, 'PENDIENTE', NOW(6), 0, NOW(6), NOW(6)),
    ('ffffffff-0000-4000-8000-000000000006', 'eeeeeeee-0000-4000-8000-000000000004', 'PENDIENTE', 'EN_RUTA', NOW(6), 0, NOW(6), NOW(6)),
    ('ffffffff-0000-4000-8000-000000000007', 'eeeeeeee-0000-4000-8000-000000000004', 'EN_RUTA', 'ENTREGADO', NOW(6), 0, NOW(6), NOW(6)),
    ('ffffffff-0000-4000-8000-000000000008', 'eeeeeeee-0000-4000-8000-000000000005', NULL, 'PENDIENTE', NOW(6), 0, NOW(6), NOW(6)),
    ('ffffffff-0000-4000-8000-000000000009', 'eeeeeeee-0000-4000-8000-000000000005', 'PENDIENTE', 'CANCELADO', NOW(6), 0, NOW(6), NOW(6));
