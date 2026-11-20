from pathlib import Path
from datetime import datetime
import sqlite3

from airflow.sdk import task, dag
import duckdb
import pandas as pd

# Rutas
BASE_DIR = Path(__file__).resolve().parent.parent
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


@dag(
    dag_id="clinica_santa_lucia",
    start_date=datetime(2026, 11, 20),
    schedule="0 2 * * *",
)
def pipeline():
    @task
    def extract():
        con = duckdb.connect(str(DB_PATH))
        print("######### Extraccion #############")
        sqlite_con = sqlite3.connect(str(DATA_DIR / "clinica.sqlite"))
        df_raw = pd.read_sql_query("SELECT * FROM turnos", sqlite_con)
        sqlite_con.close()

        con.register("df_raw", df_raw)
        con.execute(read_sql(filename="extract.sql"))
        print("Valores extraidos: ", count(con, "raw_turnos"))
        con.close()

    @task
    def validate():
        con = duckdb.connect(str(DB_PATH))
        print("############## Validacion ################")
        con.execute(read_sql(filename="validations.sql"))
        print("Valores rechazados: ", count(con, "rechazados"))
        print("Valores validos: ", count(con, "validos"))
        con.close()

    @task
    def transform():
        con = duckdb.connect(str(DB_PATH))
        print("########### Transformaciones ##############")
        con.execute(read_sql(filename="transforms.sql"))
        print("Rechazados limpios: ", count(con, "rechazados_limpios"))
        print("Tabla final: ", count(con, "tabla_final"))
        con.close()

    @task
    def consultas():
        con = duckdb.connect(str(DB_PATH))
        print("########### Consultas de Negocio ##############")
        sql_text = read_sql(filename="consultas.sql")
        sentencias = [s.strip() for s in sql_text.split(";") if s.strip()]
        for i, query in enumerate(sentencias, start=1):
            print(f"\n--- Consulta {i} ---")
            df = con.execute(query).df()
            print(df.to_string(index=False))
        con.close()

    extraction = extract()
    validation = validate()
    transformation = transform()
    business_queries = consultas()

    extraction >> validation >> transformation >> business_queries


pipeline()
