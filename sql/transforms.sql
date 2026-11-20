-- sql/transforms.sql
-- Limpieza de registros rechazados y construccion de tabla_final

CREATE OR REPLACE TABLE rechazados_limpios AS
WITH catalogo_medicos AS (
    SELECT
        id_medico,
        MAX(medico) AS medico_ref
    FROM raw_turnos
    WHERE medico IS NOT NULL AND TRIM(medico) <> ''
    GROUP BY id_medico
),
catalogo_costos AS (
    SELECT
        especialidad,
        AVG(costo) AS costo_ref
    FROM validos
    GROUP BY especialidad
),
limpios AS (
    SELECT
        TRIM(r.id_turno) AS id_turno,
        COALESCE(
            TRY_CAST(TRIM(r.fecha_turno) AS DATE),
            CAST(TRY_STRPTIME(TRIM(r.fecha_turno), '%d/%m/%Y') AS DATE)
        ) AS fecha_turno,
        CAST(r.id_paciente AS INTEGER) AS id_paciente,
        CAST(ABS(r.edad) AS INTEGER) AS edad,
        UPPER(SUBSTR(TRIM(r.especialidad), 1, 1)) || LOWER(SUBSTR(TRIM(r.especialidad), 2)) AS especialidad,
        TRIM(r.id_medico) AS id_medico,
        COALESCE(NULLIF(TRIM(r.medico), ''), m.medico_ref) AS medico,
        TRIM(r.obra_social) AS obra_social,
        CAST(
            COALESCE(
                CASE WHEN r.costo > 0 THEN r.costo END,
                c.costo_ref
            ) AS DOUBLE
        ) AS costo,
        LOWER(TRIM(r.estado)) AS estado
    FROM rechazados r
    LEFT JOIN catalogo_medicos m
        ON TRIM(r.id_medico) = m.id_medico
    LEFT JOIN catalogo_costos c
        ON (UPPER(SUBSTR(TRIM(r.especialidad), 1, 1)) || LOWER(SUBSTR(TRIM(r.especialidad), 2))) = c.especialidad
    WHERE TRIM(r.id_turno) NOT IN (SELECT id_turno FROM validos)
)
SELECT *
FROM limpios
WHERE id_turno IS NOT NULL
  AND fecha_turno IS NOT NULL
  AND id_paciente > 0
  AND edad > 0
  AND medico IS NOT NULL
  AND costo > 0
  AND estado IN ('atendido', 'ausente', 'cancelado')
QUALIFY ROW_NUMBER() OVER (PARTITION BY id_turno) = 1;

CREATE OR REPLACE TABLE tabla_final AS
WITH union_tablas AS (
    SELECT
        id_turno,
        CAST(fecha_turno AS DATE) AS fecha_turno,
        CAST(id_paciente AS INTEGER) AS id_paciente,
        CAST(edad AS INTEGER) AS edad,
        especialidad,
        id_medico,
        medico,
        obra_social,
        CAST(costo AS DOUBLE) AS costo,
        estado
    FROM validos
    UNION ALL
    SELECT
        id_turno,
        fecha_turno,
        id_paciente,
        edad,
        especialidad,
        id_medico,
        medico,
        obra_social,
        costo,
        estado
    FROM rechazados_limpios
)
SELECT *
FROM union_tablas
QUALIFY ROW_NUMBER() OVER (PARTITION BY id_turno) = 1;
