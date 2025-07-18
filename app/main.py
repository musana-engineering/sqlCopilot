from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from db import run_query
from assistant import ask_sql_gpt, explain_sql
from dotenv import load_dotenv
import os
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient

load_dotenv()

sqlCopilot = FastAPI()

class AskRequest(BaseModel):
    question: str

class AskResponse(BaseModel):
    sql: str
    explanation: str
    results: list

@sqlCopilot.get("/healthz")
def health_check():
    return {"status": "ok"}

@sqlCopilot.post("/chat", response_model=AskResponse)
def ask(request: AskRequest):
    try:
        sql = ask_sql_gpt(request.question)
        explanation = explain_sql(sql)
        result_df = run_query(sql)
        return AskResponse(
            sql=sql,
            explanation=explanation,
            results=result_df.to_dict(orient="records")
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
