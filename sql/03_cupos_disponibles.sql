SELECT
    c.id_clase,
    c.nombre            AS clase,
    c.capacidad_max,
    COUNT(CASE WHEN r.estado = 'ACTIVA' THEN 1 END) AS reservas_activas,
    c.capacidad_max - COUNT(CASE WHEN r.estado = 'ACTIVA' THEN 1 END) AS cupos_disponibles
FROM CLASE c
LEFT JOIN RESERVA r ON c.id_clase = r.id_clase
GROUP BY c.id_clase, c.nombre, c.capacidad_max, c.fecha
ORDER BY c.fecha;