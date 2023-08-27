RESOURCE_GROUP=<resource_group_name>
LOCATION=<location>
# must be gloablly unique and between 3 and 24 characters.
# must begin with letter and end with letter or digit and not contain consecutive hyphens
KEYVAULT_NAME=<keyvault_name>
# must be gloablly unique and between 3 and 24 characters. Only lowercase letters and numbers
STORAGE_ACCOUNT_NAME=<storage_account_name>
CONTAINER_NAME=<contianer_name>
DATABRICKS_WORKSPACE=<dbricks_workspace_name>
SQL_SERVER_NAME=<sql_server_name>
SQL_DB_NAME=<sql_db_name>
SQL_ADMIN_USER=<sql_admin_user>
SQL_ADMIN_PASSWORD=<sql_admin_password>

# resource group creation
az group create --name $RESOURCE_GROUP --location $LOCATION
az config set defaults.group=$RESOURCE_GROUP

# storage account and container
az storage account create \
  --name $STORAGE_ACCOUNT_NAME \
  --location $LOCATION \
  --sku Standard_LRS \
  --kind StorageV2 \
  --allow-blob-public-access false \
  --enable-hierarchical-namespace true

az storage container create \
  --name $CONTAINER_NAME \
  --account-name $STORAGE_ACCOUNT_NAME \
  --auth-mode login

az sql server create \
  --name $SQL_SERVER_NAME \
  --location $LOCATION \
  --admin-user $SQL_ADMIN_USER \
  --admin-password $SQL_ADMIN_PASSWORD

az sql server firewall-rule create \
  --name "AllowAllAzureIps" \
  --server $SQL_SERVER_NAME \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 0.0.0.0

az sql db create \
  --name $SQL_DB_NAME \
  --server $SQL_SERVER_NAME \
  --edition GeneralPurpose \
  --family Gen5 \
  --capacity 1 \
  --tier GeneralPurpose \
  --compute-model Serverless \
  --zone-redundant false \
  --backup-storage-redundancy Local \
  --auto-pause-delay 60

STORAGE_ACCOUNT_ID=$(az resource list -n $STORAGE_ACCOUNT_NAME --query [].id --output tsv)

SERVICE_PRINCIPLE_CREDS=$(az ad sp create-for-rbac \
  --name svp_databricks_connector \
  --json-auth \
  --role "Storage Blob Data Contributor" \
  --scope $STORAGE_ACCOUNT_ID \
  --output tsv)

az keyvault create \
  --name $KEYVAULT_NAME \
  --location $LOCATION

CLIENT_ID=$(echo $SERVICE_PRINCIPLE_CREDS | jq -r '.clientId')
CLIENT_SECRET=$(echo $SERVICE_PRINCIPLE_CREDS | jq -r '.clientSecret')
TENANT_ID=$(echo $SERVICE_PRINCIPLE_CREDS | jq -r '.tenantId')

secrets=(
    service-principal-client-id:$CLIENT_ID
    service-principal-client-secret:$CLIENT_SECRET
    service-principal-tenant-id:$TENANT_ID
    sqldb-host:"$SQL_SERVER_NAME.database.windows.net"
    sqldb-user:$SQL_ADMIN_USER
    sqldb-password:$SQL_ADMIN_PASSWORD
    dls-name:$STORAGE_ACCOUNT_NAME
)

for secret_info in "${secrets[@]}"; do
    key=${secret_info%%:*}
    value=${secret_info##*:}

    az keyvault secret set \
      --vault-name $KEYVAULT_NAME \
      --name $key \
      --value $value
done

az databricks workspace create \
  --name $DATABRICKS_WORKSPACE \
  --location $LOCATION \
  --sku standard

az resource list --output table
az keyvault secret list --vault-name $KEYVAULT_NAME --query [].name --output tsv
