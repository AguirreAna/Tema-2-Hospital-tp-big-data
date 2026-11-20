-- sql/consultas.sql
-- Preguntas de negocio sobre tabla_final

-- 1. ¿Cuantos turnos hubo por especialidad?
SELECT
    especialidad,
    COUNT(*) AS cantidad_turnos
FROM tabla_final
GROUP BY especialidad
ORDER BY cantidad_turnos DESC;

-- 2. ¿Cual es el porcentaje de ausentismo por especialidad?
SELECT
    especialidad,
    COUNT(*) AS total_turnos,
    SUM(CASE WHEN estado = 'ausente' THEN 1 ELSE 0 END) AS turnos_ausentes,
    ROUND(
        100.0 * SUM(CASE WHEN estado = 'ausente' THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS porcentaje_ausentismo
FROM tabla_final
GROUP BY especialidad
ORDER BY porcentaje_ausentismo DESC;

-- 3. ¿Cuanto se facturo en turnos atendidos por mes (primeros 6 meses)?
SELECT
    DATE_TRUNC('month', fecha_turno) AS mes,
    COUNT(*) AS turnos_atendidos,
    SUM(costo) AS total_facturado
FROM tabla_final
WHERE estado = 'atendido'
GROUP BY mes
ORDER BY mes ASC
LIMIT 6;

-- 4. ¿Cuales son los 5 medicos con mas turnos atendidos?
SELECT
    id_medico,
    medico,
    COUNT(*) AS turnos_atendidos
FROM tabla_final
WHERE estado = 'atendido'
GROUP BY id_medico, medico
ORDER BY turnos_atendidos DESC
LIMIT 5;

-- 5. ¿Cual es la edad promedio de los pacientes por obra social?
SELECT
    obra_social,
    ROUND(AVG(edad), 2) AS edad_promedio
FROM tabla_final
GROUP BY obra_social
ORDER BY edad_promedio DESC;
