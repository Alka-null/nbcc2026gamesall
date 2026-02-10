# Azure Deployment Quick Start

## Prerequisites
- Azure account ([Get free account](https://azure.microsoft.com/free/))
- Azure CLI installed ([Install guide](https://docs.microsoft.com/cli/azure/install-azure-cli))

## Quick Deploy Commands

### 1. Login to Azure
```bash
az login
```

### 2. Create All Resources (One Command)
```bash
# Set variables
RESOURCE_GROUP="nbcc-games-rg"
LOCATION="eastus"
PLAN_NAME="nbcc-games-plan"
BACKEND_NAME="nbcc-games-backend"
ADMIN_NAME="nbcc-games-admin"

# Create resource group
az group create --name $RESOURCE_GROUP --location $LOCATION

# Create App Service plan
az appservice plan create \
  --name $PLAN_NAME \
  --resource-group $RESOURCE_GROUP \
  --sku B1 \
  --is-linux

# Create backend app
az webapp create \
  --resource-group $RESOURCE_GROUP \
  --plan $PLAN_NAME \
  --name $BACKEND_NAME \
  --runtime "PYTHON:3.11"

# Create admin app  
az webapp create \
  --resource-group $RESOURCE_GROUP \
  --plan $PLAN_NAME \
  --name $ADMIN_NAME \
  --runtime "NODE:20-lts"
```

### 3. Deploy Backend
```bash
cd backend

# Configure settings
az webapp config appsettings set \
  --resource-group $RESOURCE_GROUP \
  --name $BACKEND_NAME \
  --settings \
    DJANGO_SECRET_KEY="$(python -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())')" \
    DJANGO_DEBUG="False" \
    DJANGO_ALLOWED_HOSTS="$BACKEND_NAME.azurewebsites.net,*.azurewebsites.net" \
    WEBSITES_PORT="8000"

# Set startup command
az webapp config set \
  --resource-group $RESOURCE_GROUP \
  --name $BACKEND_NAME \
  --startup-file "startup.sh"

# Deploy using zip
az webapp deploy \
  --resource-group $RESOURCE_GROUP \
  --name $BACKEND_NAME \
  --src-path . \
  --type zip
```

### 4. Deploy Admin Portal
```bash
cd ../admin_portal

# Configure settings
az webapp config appsettings set \
  --resource-group $RESOURCE_GROUP \
  --name $ADMIN_NAME \
  --settings \
    NEXT_PUBLIC_API_URL="https://$BACKEND_NAME.azurewebsites.net"

# Deploy using zip
npm run build
az webapp deploy \
  --resource-group $RESOURCE_GROUP \
  --name $ADMIN_NAME \
  --src-path . \
  --type zip
```

### 5. Enable CORS
```bash
az webapp cors add \
  --resource-group $RESOURCE_GROUP \
  --name $BACKEND_NAME \
  --allowed-origins "https://$ADMIN_NAME.azurewebsites.net"
```

## Access Your Apps
- Backend: `https://nbcc-games-backend.azurewebsites.net`
- Admin: `https://nbcc-games-admin.azurewebsites.net`

## View Logs
```bash
# Backend logs
az webapp log tail -n $BACKEND_NAME -g $RESOURCE_GROUP

# Admin logs
az webapp log tail -n $ADMIN_NAME -g $RESOURCE_GROUP
```

## Clean Up (Delete Everything)
```bash
az group delete --name $RESOURCE_GROUP --yes
```

## Using Free Tier (No Cost)
Replace `--sku B1` with `--sku F1` in the App Service plan creation for free tier (with limitations).

For full details, see [AZURE_DEPLOYMENT_GUIDE.md](AZURE_DEPLOYMENT_GUIDE.md)
