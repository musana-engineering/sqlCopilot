from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient

# Load Key Vault details from env
key_vault_name = "kv-0fe8b4" 
kv_uri = f"https://{key_vault_name}.vault.azure.net/"

# Secret name should contain the full SQL connection string
db_connection_string_secret = "sql-server-admin-password" 
open_api_key_secret = "openai-api-key"

# Authenticate and fetch secret
credential = DefaultAzureCredential()
key_vault_client = SecretClient(vault_url=kv_uri, credential=credential)
db_connection_string = key_vault_client.get_secret(db_connection_string_secret).value
open_api_key = key_vault_client.get_secret(open_api_key_secret).value