import pyodbc
import pandas as pd
import os
from secrets import database_connectionstring

def run_query(sql: str) -> pd.DataFrame:
    sql = sql.replace("```sql", "").replace("```", "").strip()
    cnxn = pyodbc.connect(database_connectionstring)
    return pd.read_sql(sql, cnxn)
