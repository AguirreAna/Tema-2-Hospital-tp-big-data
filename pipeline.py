from pathlib import Path
import sqlite3

import duckdb
import pandas as pd

# Rutas
BASE_DIR = Path(__file__).resolve().parent
DATA_DIR = BASE_DIR / "datos"
SQL_DIR = BASE_DIR / "sql"
DB_PATH = BASE_DIR / "clinica.duckdb"


def read_sql(filename: str):
    try:
        path = SQL_DIR / filename
        return path.read_text(encoding="utf-8")
    except Exception as e:
        print("Ocurrio un error al leer el sql", e)
        raise e


def count(con, table):
    try:
        return con.execute(f"""
            SELECT COUNT(*) FROM {table}
        """).fetchone()
    except Exception as e:
        raise e


def extract(con):
    print("######### Extraccion #############")
    sqlite_con = sqlite3.connect(str(DATA_DIR / "clinica.sqlite"))
    df_raw = pd.read_sql_query("SELECT * FROM turnos", sqlite_con)
    sqlite_con.close()

    con.register("df_raw", df_raw)
    con.execute(read_sql(filename="extract.sql"))
    print("Valores extraidos: ", count(con, "raw_turnos"))


def validate(con):
    print("############## Validacion ################")
    con.execute(read_sql(filename="validations.sql"))
    print("Valores rechazados: ", count(con, "rechazados"))
    print("Valores validos: ", count(con, "validos"))


def transform(con):
    print("########### Transformaciones ##############")
    con.execute(read_sql(filename="transforms.sql"))
    print("Rechazados limpios: ", count(con, "rechazados_limpios"))
    print("Tabla final: ", count(con, "tabla_final"))


def consultas(con):
    print("########### Consultas de Negocio ##############")
    sql_text = read_sql(filename="consultas.sql")
    sentencias = [s.strip() for s in sql_text.split(";") if s.strip()]
    for i, query in enumerate(sentencias, start=1):
        print(f"\n--- Consulta {i} ---")
        df = con.execute(query).df()
        print(df.to_string(index=False))


def main():
    try:
        con = duckdb.connect(str(DB_PATH))
        extract(con)
        validate(con)
        transform(con)
        consultas(con)
        con.close()
        print("\n######## Proceso ETL finalizado correctamente! #######")
    except Exception as e:
        print("Error al procesar los datos ", e)


if __name__ == "__main__":
    main()
