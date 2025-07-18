import os
from openai import AzureOpenAI
from dotenv import load_dotenv
import openai
from openai import AzureOpenAI
from secrets import open_api_key

load_dotenv()
OPENAI_DEPLOYMENT_ENDPOINT = "https://sqlcopilot.openai.azure.com/"
OPENAI_DEPLOYMENT_NAME = "gpt-4.1" 
OPENAI_DEPLOYMENT_VERSION = "2024-12-01-preview"
load_dotenv()

# Initialize OpenAI client for Azure
client = AzureOpenAI(
    api_version=OPENAI_DEPLOYMENT_VERSION,
    azure_endpoint=OPENAI_DEPLOYMENT_ENDPOINT,
    api_key=open_api_key,
)

SCHEMA_PROMPT = """
You are a helpful assistant that converts natural language questions into valid T-SQL queries for SQL Server.

### Tables:
1. SalesLT.Customer
   - CustomerID (PK)
   - FirstName
   - LastName
   - EmailAddress
   - ModifiedDate

2. SalesLT.CustomerAddress
   - CustomerID (FK)
   - AddressID (FK)
   - AddressType

3. SalesLT.Address
   - AddressID (PK)
   - City
   - StateProvince
   - CountryRegion
   - PostalCode
   - ModifiedDate

### Relationships:
- CustomerID joins Customer → CustomerAddress
- AddressID joins CustomerAddress → Address

### Instructions:
- Use full U.S. state names in `StateProvince` (e.g., 'California').
- Generate **clean T-SQL only** — no markdown, no explanations.
- Include necessary joins and relevant WHERE conditions.
- Use column names exactly as defined.

Respond with the raw SQL query only.
"""

def ask_sql_gpt(question: str) -> str:
    response = client.chat.completions.create(
        model=OPENAI_DEPLOYMENT_NAME,
        messages=[
            {"role": "system", "content": SCHEMA_PROMPT},
            {"role": "user", "content": question}
        ],
        temperature=0.2
    )
    return response.choices[0].message.content.strip()

def explain_sql(sql: str) -> str:
    prompt = f"Explain the following SQL query in simple terms:\n\n{sql}"
    response = client.chat.completions.create(
        model=OPENAI_DEPLOYMENT_NAME,
        messages=[
            {"role": "system", "content": "You explain SQL queries in plain English."},
            {"role": "user", "content": prompt}
        ],
        temperature=0.4
    )
    return response.choices[0].message.content.strip()
