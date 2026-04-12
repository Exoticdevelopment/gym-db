-- ============================================================
--  SISTEMA DE RESERVAS - GIMNASIO
--  Base de Datos Relacionales · Oracle Database · Grupo G6
--  Script completo: DDL + Secuencias + Triggers + DML
-- ============================================================

-- ============================================================
--  0. LIMPIEZA PREVIA (ejecutar si ya existen las tablas)
-- ============================================================
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE RESERVA CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE CLASE CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE INSTRUCTOR CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE CLIENTE CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SEQ_CLIENTE';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SEQ_INSTRUCTOR';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SEQ_CLASE';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SEQ_RESERVA';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

-- ============================================================
--  1. SECUENCIAS (equivalente a AUTO_INCREMENT en Oracle)
-- ============================================================

CREATE SEQUENCE SEQ_CLIENTE
    START WITH 1
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;

CREATE SEQUENCE SEQ_INSTRUCTOR
    START WITH 1
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;

CREATE SEQUENCE SEQ_CLASE
    START WITH 1
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;

CREATE SEQUENCE SEQ_RESERVA
    START WITH 1
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;

-- ============================================================
--  2. DDL - CREACIÓN DE TABLAS
-- ============================================================

-- ------------------------------------------------------------
--  2.1 Tabla: CLIENTE
-- ------------------------------------------------------------
CREATE TABLE CLIENTE (
    id_cliente      NUMBER          NOT NULL,
    cedula          VARCHAR2(15)    NOT NULL,
    nombre          VARCHAR2(60)    NOT NULL,
    apellido        VARCHAR2(60)    NOT NULL,
    email           VARCHAR2(100)   NOT NULL,
    telefono        VARCHAR2(15)    DEFAULT NULL,
    fecha_registro  DATE            DEFAULT SYSDATE NOT NULL,
    -- Clave primaria
    CONSTRAINT PK_CLIENTE       PRIMARY KEY (id_cliente),
    -- Restricciones de unicidad
    CONSTRAINT UQ_CLIENTE_CED   UNIQUE (cedula),
    CONSTRAINT UQ_CLIENTE_EMAIL UNIQUE (email)
);

-- ------------------------------------------------------------
--  2.2 Tabla: INSTRUCTOR
-- ------------------------------------------------------------
CREATE TABLE INSTRUCTOR (
    id_instructor   NUMBER          NOT NULL,
    cedula          VARCHAR2(15)    NOT NULL,
    nombre          VARCHAR2(60)    NOT NULL,
    apellido        VARCHAR2(60)    NOT NULL,
    especialidad    VARCHAR2(80)    DEFAULT NULL,
    telefono        VARCHAR2(15)    DEFAULT NULL,
    -- Clave primaria
    CONSTRAINT PK_INSTRUCTOR        PRIMARY KEY (id_instructor),
    -- Restricción de unicidad
    CONSTRAINT UQ_INSTRUCTOR_CED    UNIQUE (cedula)
);

-- ------------------------------------------------------------
--  2.3 Tabla: CLASE
-- ------------------------------------------------------------
CREATE TABLE CLASE (
    id_clase        NUMBER          NOT NULL,
    nombre          VARCHAR2(80)    NOT NULL,
    descripcion     VARCHAR2(255)   DEFAULT NULL,
    fecha           DATE            NOT NULL,
    hora_inicio     TIMESTAMP       NOT NULL,
    hora_fin        TIMESTAMP       NOT NULL,
    capacidad_max   NUMBER(3)       NOT NULL,
    id_instructor   NUMBER          NOT NULL,
    -- Clave primaria
    CONSTRAINT PK_CLASE         PRIMARY KEY (id_clase),
    -- Clave foránea
    CONSTRAINT FK_CLASE_INST    FOREIGN KEY (id_instructor)
        REFERENCES INSTRUCTOR (id_instructor)
        ON DELETE CASCADE
);

-- ------------------------------------------------------------
--  2.4 Tabla: RESERVA (tabla de hechos / tabla intermedia)
-- ------------------------------------------------------------
CREATE TABLE RESERVA (
    id_reserva      NUMBER          NOT NULL,
    fecha_reserva   DATE            DEFAULT SYSDATE NOT NULL,
    estado          VARCHAR2(15)    DEFAULT 'ACTIVA' NOT NULL,
    id_cliente      NUMBER          NOT NULL,
    id_clase        NUMBER          NOT NULL,
    -- Clave primaria
    CONSTRAINT PK_RESERVA           PRIMARY KEY (id_reserva),
    -- Claves foráneas
    CONSTRAINT FK_RESERVA_CLI       FOREIGN KEY (id_cliente)
        REFERENCES CLIENTE (id_cliente)
        ON DELETE CASCADE,
    CONSTRAINT FK_RESERVA_CLASE     FOREIGN KEY (id_clase)
        REFERENCES CLASE (id_clase)
        ON DELETE CASCADE,
    -- Validación de estado permitido
    CONSTRAINT CHK_ESTADO_RESERVA   CHECK (estado IN ('ACTIVA', 'CANCELADA', 'COMPLETADA'))
);

-- ============================================================
--  3. TRIGGERS (auto-incremento con las secuencias)
-- ============================================================

-- Trigger: CLIENTE
CREATE OR REPLACE TRIGGER TRG_CLIENTE_BI
    BEFORE INSERT ON CLIENTE
    FOR EACH ROW
BEGIN
    IF :NEW.id_cliente IS NULL THEN
        :NEW.id_cliente := SEQ_CLIENTE.NEXTVAL;
    END IF;
END;
/

-- Trigger: INSTRUCTOR
CREATE OR REPLACE TRIGGER TRG_INSTRUCTOR_BI
    BEFORE INSERT ON INSTRUCTOR
    FOR EACH ROW
BEGIN
    IF :NEW.id_instructor IS NULL THEN
        :NEW.id_instructor := SEQ_INSTRUCTOR.NEXTVAL;
    END IF;
END;
/

-- Trigger: CLASE
CREATE OR REPLACE TRIGGER TRG_CLASE_BI
    BEFORE INSERT ON CLASE
    FOR EACH ROW
BEGIN
    IF :NEW.id_clase IS NULL THEN
        :NEW.id_clase := SEQ_CLASE.NEXTVAL;
    END IF;
END;
/

-- Trigger: RESERVA
CREATE OR REPLACE TRIGGER TRG_RESERVA_BI
    BEFORE INSERT ON RESERVA
    FOR EACH ROW
BEGIN
    IF :NEW.id_reserva IS NULL THEN
        :NEW.id_reserva := SEQ_RESERVA.NEXTVAL;
    END IF;
END;
/

-- ============================================================
--  4. TRIGGER DE CONTROL DE CONCURRENCIA
--     Evita que se supere la capacidad máxima de una clase
-- ============================================================
CREATE OR REPLACE TRIGGER TRG_CONTROL_CUPOS
    BEFORE INSERT ON RESERVA
    FOR EACH ROW
DECLARE
    v_cupos_ocupados    NUMBER;
    v_capacidad_max     NUMBER;
BEGIN
    -- Contar reservas ACTIVAS en esa clase
    SELECT COUNT(*)
    INTO v_cupos_ocupados
    FROM RESERVA
    WHERE id_clase = :NEW.id_clase
      AND estado   = 'ACTIVA';

    -- Obtener capacidad máxima de la clase
    SELECT capacidad_max
    INTO v_capacidad_max
    FROM CLASE
    WHERE id_clase = :NEW.id_clase;

    -- Lanzar error si no hay cupos
    IF v_cupos_ocupados >= v_capacidad_max THEN
        RAISE_APPLICATION_ERROR(-20001,
            'No hay cupos disponibles para esta clase. Capacidad máxima: '
            || v_capacidad_max);
    END IF;
END;
/

-- ============================================================
--  5. DML - DATOS DE PRUEBA
-- ============================================================

-- ------------------------------------------------------------
--  5.1 Instructores
-- ------------------------------------------------------------
INSERT INTO INSTRUCTOR (cedula, nombre, apellido, especialidad, telefono)
VALUES ('1001234567', 'Carlos', 'Ramírez', 'Spinning', '3101234567');

INSERT INTO INSTRUCTOR (cedula, nombre, apellido, especialidad, telefono)
VALUES ('1009876543', 'Laura', 'Gómez', 'Yoga', '3209876543');

INSERT INTO INSTRUCTOR (cedula, nombre, apellido, especialidad, telefono)
VALUES ('1005551234', 'Andrés', 'Torres', 'Crossfit', NULL);

-- ------------------------------------------------------------
--  5.2 Clientes
-- ------------------------------------------------------------
INSERT INTO CLIENTE (cedula, nombre, apellido, email, telefono)
VALUES ('8001112233', 'María', 'López', 'maria.lopez@email.com', '3151112233');

INSERT INTO CLIENTE (cedula, nombre, apellido, email, telefono)
VALUES ('8004445566', 'Juan', 'Martínez', 'juan.martinez@email.com', NULL);

INSERT INTO CLIENTE (cedula, nombre, apellido, email, telefono)
VALUES ('8007778899', 'Sofía', 'Herrera', 'sofia.herrera@email.com', '3207778899');

INSERT INTO CLIENTE (cedula, nombre, apellido, email, telefono)
VALUES ('8002223344', 'Diego', 'Castro', 'diego.castro@email.com', '3112223344');

INSERT INTO CLIENTE (cedula, nombre, apellido, email, telefono)
VALUES ('8005556677', 'Valentina', 'Ríos', 'valentina.rios@email.com', NULL);

-- ------------------------------------------------------------
--  5.3 Clases
-- ------------------------------------------------------------
INSERT INTO CLASE (nombre, descripcion, fecha, hora_inicio, hora_fin, capacidad_max, id_instructor)
VALUES (
    'Spinning Avanzado',
    'Clase de alta intensidad en bicicleta estática',
    TO_DATE('2026-04-15', 'YYYY-MM-DD'),
    TO_TIMESTAMP('2026-04-15 07:00:00', 'YYYY-MM-DD HH24:MI:SS'),
    TO_TIMESTAMP('2026-04-15 08:00:00', 'YYYY-MM-DD HH24:MI:SS'),
    15,
    1
);

INSERT INTO CLASE (nombre, descripcion, fecha, hora_inicio, hora_fin, capacidad_max, id_instructor)
VALUES (
    'Yoga Relajante',
    'Sesión de yoga enfocada en flexibilidad y meditación',
    TO_DATE('2026-04-15', 'YYYY-MM-DD'),
    TO_TIMESTAMP('2026-04-15 09:00:00', 'YYYY-MM-DD HH24:MI:SS'),
    TO_TIMESTAMP('2026-04-15 10:00:00', 'YYYY-MM-DD HH24:MI:SS'),
    10,
    2
);

INSERT INTO CLASE (nombre, descripcion, fecha, hora_inicio, hora_fin, capacidad_max, id_instructor)
VALUES (
    'Crossfit Principiantes',
    'Entrenamiento funcional de alta intensidad para principiantes',
    TO_DATE('2026-04-16', 'YYYY-MM-DD'),
    TO_TIMESTAMP('2026-04-16 06:00:00', 'YYYY-MM-DD HH24:MI:SS'),
    TO_TIMESTAMP('2026-04-16 07:00:00', 'YYYY-MM-DD HH24:MI:SS'),
    20,
    3
);

INSERT INTO CLASE (nombre, descripcion, fecha, hora_inicio, hora_fin, capacidad_max, id_instructor)
VALUES (
    'Spinning Matutino',
    'Clase de spinning para iniciar el día con energía',
    TO_DATE('2026-04-17', 'YYYY-MM-DD'),
    TO_TIMESTAMP('2026-04-17 06:30:00', 'YYYY-MM-DD HH24:MI:SS'),
    TO_TIMESTAMP('2026-04-17 07:30:00', 'YYYY-MM-DD HH24:MI:SS'),
    12,
    1
);

-- ------------------------------------------------------------
--  5.4 Reservas
-- ------------------------------------------------------------
INSERT INTO RESERVA (id_cliente, id_clase, estado)
VALUES (1, 1, 'ACTIVA');

INSERT INTO RESERVA (id_cliente, id_clase, estado)
VALUES (2, 1, 'ACTIVA');

INSERT INTO RESERVA (id_cliente, id_clase, estado)
VALUES (3, 2, 'ACTIVA');

INSERT INTO RESERVA (id_cliente, id_clase, estado)
VALUES (4, 3, 'ACTIVA');

INSERT INTO RESERVA (id_cliente, id_clase, estado)
VALUES (5, 2, 'CANCELADA');

INSERT INTO RESERVA (id_cliente, id_clase, estado)
VALUES (1, 4, 'ACTIVA');

COMMIT;

-- ============================================================
--  6. CRUD - OPERACIONES DE CONSULTA / MODIFICACIÓN
-- ============================================================

-- --- SELECT: Ver todos los clientes ---
SELECT * FROM CLIENTE ORDER BY apellido, nombre;

-- --- SELECT: Ver clases con su instructor ---
SELECT
    c.id_clase,
    c.nombre                            AS clase,
    c.fecha,
    c.hora_inicio,
    c.hora_fin,
    c.capacidad_max,
    i.nombre || ' ' || i.apellido       AS instructor,
    i.especialidad
FROM CLASE c
JOIN INSTRUCTOR i ON c.id_instructor = i.id_instructor
ORDER BY c.fecha, c.hora_inicio;

-- --- SELECT: Ver reservas con datos de cliente y clase ---
SELECT
    r.id_reserva,
    cl.nombre || ' ' || cl.apellido     AS cliente,
    cl.email,
    c.nombre                            AS clase,
    c.fecha,
    r.fecha_reserva,
    r.estado
FROM RESERVA r
JOIN CLIENTE cl  ON r.id_cliente = cl.id_cliente
JOIN CLASE   c   ON r.id_clase   = c.id_clase
ORDER BY r.fecha_reserva DESC;

-- --- SELECT: Cupos disponibles por clase ---
SELECT
    c.id_clase,
    c.nombre                                            AS clase,
    c.capacidad_max,
    COUNT(CASE WHEN r.estado = 'ACTIVA' THEN 1 END)    AS reservas_activas,
    c.capacidad_max - COUNT(CASE WHEN r.estado = 'ACTIVA' THEN 1 END) AS cupos_disponibles
FROM CLASE c
LEFT JOIN RESERVA r ON c.id_clase = r.id_clase
GROUP BY c.id_clase, c.nombre, c.capacidad_max
ORDER BY c.fecha;

-- --- UPDATE: Cancelar una reserva ---
UPDATE RESERVA
SET estado = 'CANCELADA'
WHERE id_reserva = 5;
COMMIT;

-- --- UPDATE: Completar reservas de una clase pasada ---
UPDATE RESERVA
SET estado = 'COMPLETADA'
WHERE id_clase = 1
  AND estado   = 'ACTIVA';
COMMIT;

-- --- DELETE: Eliminar un cliente (CASCADE elimina sus reservas) ---
-- DELETE FROM CLIENTE WHERE id_cliente = 5;
-- COMMIT;

-- ============================================================
--  FIN DEL SCRIPT
--  Grupo G6 · Bases de Datos Relacionales · Oracle Database
-- ============================================================
