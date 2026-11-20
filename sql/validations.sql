-- sql/validations.sql
-- Reglas de validacion definidas:
-- 1. id_turno_invalido: id_turno nulo o vacio
-- 2. id_turno_duplicado: clave id_turno repetida
-- 3. fecha_invalida: fecha_turno nula o no convertible a DATE en formato YYYY-MM-DD
-- 4. id_paciente_invalido: id_paciente nulo o menor o igual a 0
-- 5. edad_invalida: edad nula, menor o igual a 0 o mayor a 120
-- 6. especialidad_invalida: especialidad nula, con espacios o fuera de formato estandar
-- 7. id_medico_invalido: id_medico nulo o vacio
-- 8. medico_nulo: medico nulo o vacio
-- 9. obra_social_invalida: obra_social nula o vacia
-- 10. costo_invalido: costo nulo o menor o igual a 0
-- 11. estado_invalido: estado nulo o fuera de (atendido, ausente, cancelado)

CREATE OR REPLACE TABLE rechazados AS
WITH base AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY id_turno) AS rn
    FROM raw_turnos
),
evaluados AS (
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
        estado,
        CONCAT_WS('; ',
            CASE WHEN id_turno IS NULL OR TRIM(id_turno) = '' THEN 'id_turno_invalido' END,
            CASE WHEN rn > 1 THEN 'id_turno_duplicado' END,
            CASE WHEN fecha_turno IS NULL OR TRY_CAST(fecha_turno AS DATE) IS NULL THEN 'fecha_invalida' END,
            CASE WHEN id_paciente IS NULL OR id_paciente <= 0 THEN 'id_paciente_invalido' END,
            CASE WHEN edad IS NULL OR edad <= 0 OR edad > 120 THEN 'edad_invalida' END,
            CASE WHEN especialidad IS NULL OR especialidad NOT IN (
                'Clinica medica', 'Pediatria', 'Traumatologia',
                'Dermatologia', 'Ginecologia', 'Cardiologia'
            ) THEN 'especialidad_invalida' END,
            CASE WHEN id_medico IS NULL OR TRIM(id_medico) = '' THEN 'id_medico_invalido' END,
            CASE WHEN medico IS NULL OR TRIM(medico) = '' THEN 'medico_nulo' END,
            CASE WHEN obra_social IS NULL OR TRIM(obra_social) = '' THEN 'obra_social_invalida' END,
            CASE WHEN costo IS NULL OR costo <= 0 THEN 'costo_invalido' END,
            CASE WHEN estado IS NULL OR estado NOT IN ('atendido', 'ausente', 'cancelado') THEN 'estado_invalido' END
        ) AS motivo_rechazo
    FROM base
)
SELECT *
FROM evaluados
WHERE motivo_rechazo <> '';

CREATE OR REPLACE TABLE validos AS
WITH base AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY id_turno) AS rn
    FROM raw_turnos
)
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
FROM base
WHERE id_turno IS NOT NULL
  AND TRIM(id_turno) <> ''
  AND rn = 1
  AND fecha_turno IS NOT NULL
  AND TRY_CAST(fecha_turno AS DATE) IS NOT NULL
  AND id_paciente IS NOT NULL
  AND id_paciente > 0
  AND edad IS NOT NULL
  AND edad > 0
  AND edad <= 120
  AND especialidad IN (
      'Clinica medica', 'Pediatria', 'Traumatologia',
      'Dermatologia', 'Ginecologia', 'Cardiologia'
  )
  AND id_medico IS NOT NULL
  AND TRIM(id_medico) <> ''
  AND medico IS NOT NULL
  AND TRIM(medico) <> ''
  AND obra_social IS NOT NULL
  AND TRIM(obra_social) <> ''
  AND costo IS NOT NULL
  AND costo > 0
  AND estado IN ('atendido', 'ausente', 'cancelado');
