# Informe ETL — Clínica Santa Lucía

## 1. Problemas encontrados en los datos originales
Al extraer los **2.575 registros** de la tabla `turnos` de `datos/clinica.sqlite` hacia `raw_turnos` (sin modificar el origen), se detectaron los siguientes problemas de calidad:

- **Registros duplicados (`id_turno`)**: 75 filas duplicadas exactas correspondientes a 74 `id_turno` repetidos (sobre 2.500 turnos únicos).
- **Fechas con formato inconsistente (`fecha_turno`)**: 257 registros cargados en formato `DD/MM/YYYY` en lugar de `YYYY-MM-DD`.
- **Edades negativas (`edad`)**: 101 registros con edades menores o iguales a cero (entre `-90` y `-1`), con el signo invertido.
- **Especialidades sin normalizar (`especialidad`)**: 206 registros escritos en mayúsculas y/o con espacios al inicio o al final (ej. `'GINECOLOGIA'`, `' PEDIATRIA'`, `'TRAUMATOLOGIA '`).
- **Nombres de médicos faltantes (`medico`)**: 158 registros con `medico` nulo, recuperables mediante la relación directa 1 a 1 con `id_medico`.
- **Costos faltantes (`costo`)**: 129 registros con `costo` nulo, recuperables mediante el arancel fijo por especialidad (`Clinica medica`: 18.000, `Pediatria`: 22.000, `Ginecologia`: 26.000, `Dermatologia`: 28.000, `Traumatologia`: 30.000, `Cardiologia`: 35.000).
- **Estados con espacios extras (`estado`)**: 154 registros con espacios al inicio o final (ej. `' atendido'`, `'ausente  '`).

## 2. Validación y registros rechazados por regla
Se definieron **11 reglas de validación** en `sql/validations.sql`. Del total de 2.575 registros, **1.525** pasaron a `validos` y **1.050** a `rechazados` (1.020 fallaron 1 regla y 30 fallaron 2 reglas simultáneamente).

| # | Regla de validación | Descripción | Registros rechazados |
|---|---------------------|-------------|---------------------:|
| 1 | `id_turno_invalido` | `id_turno` nulo o vacío | 0 |
| 2 | `id_turno_duplicado` | Clave `id_turno` repetida | 75 |
| 3 | `fecha_invalida` | Fecha nula o fuera de formato `YYYY-MM-DD` | 257 |
| 4 | `id_paciente_invalido` | `id_paciente` nulo o `<= 0` | 0 |
| 5 | `edad_invalida` | `edad` nula, `<= 0` o `> 120` | 101 |
| 6 | `especialidad_invalida` | Especialidad nula, con espacios o mayúsculas fuera de estándar | 206 |
| 7 | `id_medico_invalido` | `id_medico` nulo o vacío | 0 |
| 8 | `medico_nulo` | Nombre de `medico` nulo o vacío | 158 |
| 9 | `obra_social_invalida` | `obra_social` nula o vacía | 0 |
| 10 | `costo_invalido` | `costo` nulo o `<= 0` | 129 |
| 11 | `estado_invalido` | `estado` nulo o distinto de `atendido`, `ausente` o `cancelado` | 154 |

Tras la limpieza en `sql/transforms.sql`, se recuperaron **975** registros únicos en `rechazados_limpios` (eliminando únicamente las 75 copias duplicadas) y se consolidó `tabla_final` con **2.500 registros únicos**, sin nulos y con tipos correctos (`fecha_turno` como `DATE`, `id_paciente` y `edad` como `INTEGER`, `costo` como `DOUBLE`).

## 3. Respuestas a las preguntas de negocio (`sql/consultas.sql`)

### 1) ¿Cuántos turnos hubo por especialidad? y 2) ¿Cuál es el porcentaje de ausentismo por especialidad?
| Especialidad | Turnos totales | Turnos ausentes | % Ausentismo |
|--------------|---------------:|----------------:|-------------:|
| Clinica medica | 442 | 78 | 17,65% |
| Pediatria | 431 | 81 | 18,79% |
| Dermatologia | 420 | 64 | 15,24% |
| Ginecologia | 419 | 72 | 17,18% |
| Traumatologia | 416 | 65 | 15,63% |
| Cardiologia | 372 | 67 | 18,01% |

### 3) ¿Cuánto se facturó en turnos atendidos por mes (primeros 6 meses)?
| Mes | Turnos atendidos | Total facturado (ARS) |
|-----|-----------------:|----------------------:|
| 2024-01 | 66 | \$1.665.000 |
| 2024-02 | 68 | \$1.788.000 |
| 2024-03 | 78 | \$2.024.000 |
| 2024-04 | 73 | \$1.896.000 |
| 2024-05 | 77 | \$2.087.000 |
| 2024-06 | 64 | \$1.681.000 |

### 4) ¿Cuáles son los 5 médicos con más turnos atendidos?
| ID Médico | Médico | Turnos atendidos |
|-----------|--------|-----------------:|
| M21 | Dr. Romero C1 | 124 |
| M51 | Dr. Lopez F1 | 113 |
| M41 | Dr. Acosta E1 | 111 |
| M11 | Dr. Lopez B1 | 109 |
| M10 | Dr. Sosa B0 | 105 |

### 5) ¿Cuál es la edad promedio de los pacientes por obra social?
| Obra social | Edad promedio (años) |
|-------------|---------------------:|
| OSDE | 46,35 |
| Sin cobertura | 45,94 |
| Swiss Medical | 45,85 |
| Galeno | 45,43 |
| PAMI | 44,82 |
