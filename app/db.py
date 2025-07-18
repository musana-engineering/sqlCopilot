import pyodbc
import pandas as pd
import os
from secrets import db_connection_string

def run_query(sql: str) -> pd.DataFrame:
    sql = sql.replace("```sql", "").replace("```", "").strip()
    cnxn = pyodbc.connect(db_connection_string)
    return pd.read_sql(sql, cnxn)
