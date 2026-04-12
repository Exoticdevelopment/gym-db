-- ============================================================
--  CONSULTAS DE VERIFICACIÓN — GIMNASIO G6
--  Ejecutar en SQL Developer → Hoja de Trabajo → Gimnasio G6
-- ============================================================

-- --- Ver todos los clientes ---
SELECT * FROM CLIENTE ORDER BY id_cliente DESC;

-- --- Ver todos los instructores ---
SELECT * FROM INSTRUCTOR ORDER BY id_instructor;

-- --- Ver todas las clases con su instructor ---
SELECT
    c.id_clase,
    c.nombre                           AS clase,
    c.fecha,
    TO_CHAR(c.hora_inicio, 'HH24:MI') AS hora_inicio,
    TO_CHAR(c.hora_fin,    'HH24:MI') AS hora_fin,
    c.capacidad_max,
    i.nombre || ' ' || i.apellido      AS instructor
FROM CLASE c
JOIN INSTRUCTOR i ON c.id_instructor = i.id_instructor
ORDER BY c.fecha, c.hora_inicio;

-- --- Ver todas las reservas con cliente y clase ---
SELECT
    r.id_reserva,
    cl.nombre || ' ' || cl.apellido    AS cliente,
    c.nombre                           AS clase,
    r.fecha_reserva,
    r.estado
FROM RESERVA r
JOIN CLIENTE cl ON cl.id_cliente = r.id_cliente
JOIN CLASE   c  ON c.id_clase    = r.id_clase
ORDER BY r.id_reserva DESC;

-- --- Ver cupos disponibles por clase ---
SELECT
    c.id_clase,
    c.nombre                                                           AS clase,
    c.capacidad_max,
    COUNT(CASE WHEN r.estado = 'ACTIVA' THEN 1 END)                   AS reservas_activas,
    c.capacidad_max - COUNT(CASE WHEN r.estado = 'ACTIVA' THEN 1 END) AS cupos_disponibles
FROM CLASE c
LEFT JOIN RESERVA r ON c.id_clase = r.id_clase
GROUP BY c.id_clase, c.nombre, c.capacidad_max, c.fecha
ORDER BY c.fecha;