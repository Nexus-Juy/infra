-- =====================================================================
-- LogiTrack - courier-service
-- Base de datos propia del microservicio de repartidores (MySQL 8)
-- Se ejecuta automáticamente la PRIMERA vez que se crea el contenedor
-- de MySQL (volumen vacío). Para re-ejecutarlo: docker compose down -v
-- =====================================================================

SET NAMES utf8mb4;

CREATE DATABASE IF NOT EXISTS logitrack_couriers
    CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE logitrack_couriers;

-- ---------------------------------------------------------------------
-- Repartidores
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS repartidores (
    id             CHAR(36)     NOT NULL,
    nombre         VARCHAR(120) NOT NULL,
    tipo_vehiculo  VARCHAR(20)  NOT NULL,
    email          VARCHAR(150) NOT NULL,
    telefono       VARCHAR(30)  NOT NULL,
    estado         VARCHAR(20)  NOT NULL,
    version        BIGINT,
    created_at     DATETIME(6)  NOT NULL,
    updated_at     DATETIME(6),
    CONSTRAINT pk_repartidores PRIMARY KEY (id),
    CONSTRAINT uk_repartidores_email UNIQUE (email)
);

-- ---------------------------------------------------------------------
-- Datos de prueba (mismos UUID que usa shipment-service para los envíos)
-- ---------------------------------------------------------------------
INSERT INTO repartidores (id, nombre, tipo_vehiculo, email, telefono, estado, version, created_at, updated_at) VALUES
    ('3f6c1a52-8e0b-4d7a-9c11-0a1b2c3d4e01', 'Brian Abalos',    'MOTO',      'brian.abalos@logitrack.com',    '+54 388 400-2001', 'ACTIVO',   0, NOW(6), NOW(6)),
    ('3f6c1a52-8e0b-4d7a-9c11-0a1b2c3d4e02', 'Martín Quispe',   'CAMIONETA', 'martin.quispe@logitrack.com',   '+54 388 400-2002', 'ACTIVO',   0, NOW(6), NOW(6)),
    ('3f6c1a52-8e0b-4d7a-9c11-0a1b2c3d4e03', 'Sofía Mamaní',    'BICICLETA', 'sofia.mamani@logitrack.com',    '+54 388 400-2003', 'INACTIVO', 0, NOW(6), NOW(6));
