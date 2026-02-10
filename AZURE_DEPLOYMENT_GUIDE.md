# Azure Deployment Guide for NBCC Strategy Games

This guide covers deploying both the Python Django backend and Next.js admin portal to Azure App Service.

## Prerequisites

1. **Azure Account** - [Sign up for free](https://azure.microsoft.com/free/)
2. **Azure CLI** - Install from [here](https://docs.microsoft.com/cli/azure/install-azure-cli)
3. **Git** - Ensure Git is installed

## Architecture

```
┌─────────────────────────────────────────────┐
│            Azure Resource Group              │
│                                              │
│  ┌────────────────┐    ┌─────────────────┐ │
│  │  App Service   │    │   App Service   │ │
│  │  (Python/      │    │   (Next.js      │ │
│  │   Django)      │    │    Admin)       │ │
│  │                │    │                 │ │
│  │ Backend API    │◄───┤  Admin Portal   │ │
│  └────────────────┘    └─────────────────┘ │
│          │                                  │
│          ▼                                  │
│  ┌────────────────┐                        │
│  │   PostgreSQL   │  (Optional - can use  │
│  │   Database     │   SQLite for testing) │
│  └────────────────┘                        │
└─────────────────────────────────────────────┘
```

## Step-by-Step Deployment

### 1. Login to Azure

```bash
# Login to your Azure account
az login

# Set your subscription (if you have multiple)
az account list --output table
az account set --subscription "<your-subscription-id>"
```

### 2. Create Resource Group

```bash
# Create a resource group for all your resources
az group create \
  --name nbcc-games-rg \
  --location eastus
```

### 3. Deploy Python Django Backend

#### 3.1 Create App Service Plan

```bash
# Create a Linux App Service Plan (B1 tier for production, F1 for free tier)
az appservice plan create \
  --name nbcc-games-plan \
  --resource-group nbcc-games-rg \
  --sku B1 \
  --is-linux
```

#### 3.2 Create Web App for Backend

```bash
# Create the web app with Python 3.11 runtime
az webapp create \
  --resource-group nbcc-games-rg \
  --plan nbcc-games-plan \
  --name nbcc-games-backend \
  --runtime "PYTHON:3.11" \
  --deployment-local-git
```

#### 3.3 Configure Backend Environment Variables

```bash
cd backend

# Set application settings (environment variables)
az webapp config appsettings set \
  --resource-group nbcc-games-rg \
  --name nbcc-games-backend \
  --settings \
    DJANGO_SECRET_KEY="your-secret-key-here-generate-new-one" \
    DJANGO_DEBUG="False" \
    DJANGO_ALLOWED_HOSTS="nbcc-games-backend.azurewebsites.net,*.azurewebsites.net" \
    SCM_DO_BUILD_DURING_DEPLOYMENT="true" \
    WEBSITES_PORT="8000"

# Configure startup command
az webapp config set \
  --resource-group nbcc-games-rg \
  --name nbcc-games-backend \
  --startup-file "startup.sh"
```

#### 3.4 Add Gunicorn to Requirements

Add to `backend/requirements.txt`:
```
gunicorn==21.2.0
```

#### 3.5 Deploy Backend

```bash
# Initialize git if not already done
git init
git add .
git commit -m "Initial commit for Azure deployment"

# Get the deployment URL
az webapp deployment source config-local-git \
  --name nbcc-games-backend \
  --resource-group nbcc-games-rg \
  --query url \
  --output tsv

# Add Azure as a remote (use the URL from above)
git remote add azure <deployment-url-from-above>

# Deploy
git push azure main:master
```

**Note**: If you get authentication errors, set up deployment credentials:

```bash
az webapp deployment user set \
  --user-name <username> \
  --password <password>
```

#### 3.6 (Optional) Set up PostgreSQL Database

```bash
# Create PostgreSQL server
az postgres flexible-server create \
  --resource-group nbcc-games-rg \
  --name nbcc-games-db \
  --location eastus \
  --admin-user dbadmin \
  --admin-password "YourStrongPassword123!" \
  --sku-name Standard_B1ms \
  --tier Burstable \
  --version 14

# Create database
az postgres flexible-server db create \
  --resource-group nbcc-games-rg \
  --server-name nbcc-games-db \
  --database-name nbccgames

# Update backend settings with database connection
az webapp config appsettings set \
  --resource-group nbcc-games-rg \
  --name nbcc-games-backend \
  --settings \
    DATABASE_URL="postgresql://dbadmin:YourStrongPassword123!@nbcc-games-db.postgres.database.azure.com/nbccgames"
```

### 4. Deploy Next.js Admin Portal

#### 4.1 Create Web App for Admin Portal

```bash
cd ../admin_portal

# Create the web app with Node.js 20 runtime
az webapp create \
  --resource-group nbcc-games-rg \
  --plan nbcc-games-plan \
  --name nbcc-games-admin \
  --runtime "NODE:20-lts" \
  --deployment-local-git
```

#### 4.2 Configure Admin Portal Settings

```bash
# Set application settings
az webapp config appsettings set \
  --resource-group nbcc-games-rg \
  --name nbcc-games-admin \
  --settings \
    NEXT_PUBLIC_API_URL="https://nbcc-games-backend.azurewebsites.net" \
    SCM_DO_BUILD_DURING_DEPLOYMENT="true" \
    WEBSITE_NODE_DEFAULT_VERSION="~20"

# Set startup command
az webapp config set \
  --resource-group nbcc-games-rg \
  --name nbcc-games-admin \
  --startup-file "npm start"
```

#### 4.3 Deploy Admin Portal

```bash
# Initialize git if not already done
git init
git add .
git commit -m "Initial commit for Azure deployment"

# Get deployment URL
az webapp deployment source config-local-git \
  --name nbcc-games-admin \
  --resource-group nbcc-games-rg \
  --query url \
  --output tsv

# Add Azure as remote
git remote add azure <deployment-url-from-above>

# Deploy
git push azure main:master
```

### 5. Enable CORS on Backend

```bash
# Update backend CORS settings to allow admin portal
az webapp cors add \
  --resource-group nbcc-games-rg \
  --name nbcc-games-backend \
  --allowed-origins "https://nbcc-games-admin.azurewebsites.net"
```

### 6. View Your Deployed Applications

- **Backend API**: https://nbcc-games-backend.azurewebsites.net
- **Admin Portal**: https://nbcc-games-admin.azurewebsites.net
- **API Docs**: https://nbcc-games-backend.azurewebsites.net/swagger/

### 7. Monitor and Logs

```bash
# View backend logs
az webapp log tail \
  --resource-group nbcc-games-rg \
  --name nbcc-games-backend

# View admin portal logs
az webapp log tail \
  --resource-group nbcc-games-rg \
  --name nbcc-games-admin

# Enable application logging
az webapp log config \
  --resource-group nbcc-games-rg \
  --name nbcc-games-backend \
  --application-logging filesystem \
  --level information
```

## Alternative: GitHub Actions Deployment

For automated deployments on every push:

### Backend GitHub Action

Create `.github/workflows/backend-deploy.yml`:

```yaml
name: Deploy Backend to Azure

on:
  push:
    branches:
      - main
    paths:
      - 'backend/**'

jobs:
  deploy:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v2
    
    - name: Set up Python
      uses: actions/setup-python@v2
      with:
        python-version: '3.11'
    
    - name: Install dependencies
      run: |
        cd backend
        pip install -r requirements.txt
    
    - name: Deploy to Azure Web App
      uses: azure/webapps-deploy@v2
      with:
        app-name: 'nbcc-games-backend'
        publish-profile: ${{ secrets.AZURE_BACKEND_PUBLISH_PROFILE }}
        package: ./backend
```

### Admin Portal GitHub Action

Create `.github/workflows/admin-deploy.yml`:

```yaml
name: Deploy Admin to Azure

on:
  push:
    branches:
      - main
    paths:
      - 'admin_portal/**'

jobs:
  deploy:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v2
    
    - name: Set up Node.js
      uses: actions/setup-node@v2
      with:
        node-version: '20'
    
    - name: Install dependencies and build
      run: |
        cd admin_portal
        npm ci
        npm run build
    
    - name: Deploy to Azure Web App
      uses: azure/webapps-deploy@v2
      with:
        app-name: 'nbcc-games-admin'
        publish-profile: ${{ secrets.AZURE_ADMIN_PUBLISH_PROFILE }}
        package: ./admin_portal
```

To get publish profiles:

```bash
# Backend
az webapp deployment list-publishing-profiles \
  --resource-group nbcc-games-rg \
  --name nbcc-games-backend \
  --xml

# Admin Portal
az webapp deployment list-publishing-profiles \
  --resource-group nbcc-games-rg \
  --name nbcc-games-admin \
  --xml
```

Add these as secrets in GitHub: `AZURE_BACKEND_PUBLISH_PROFILE` and `AZURE_ADMIN_PUBLISH_PROFILE`

## Cost Estimation

- **App Service Plan B1**: ~$13/month
- **PostgreSQL Flexible Server (Burstable B1ms)**: ~$12/month
- **Total**: ~$25/month

**Free Tier Alternative** (for testing):
- Use F1 free tier for App Service Plan
- Use SQLite database (included)
- **Total**: $0/month (with limitations)

## Troubleshooting

### Backend Issues

1. **App not starting**:
   ```bash
   az webapp log tail -n nbcc-games-backend -g nbcc-games-rg
   ```

2. **Static files not loading**:
   - Ensure `whitenoise` is in `requirements.txt`
   - Check `collectstatic` runs in `deploy.sh`

3. **Database migration errors**:
   - Run migrations manually via SSH:
   ```bash
   az webapp ssh --resource-group nbcc-games-rg --name nbcc-games-backend
   python manage.py migrate
   ```

### Admin Portal Issues

1. **Build failures**:
   - Check Node.js version matches
   - Verify all dependencies are in `package.json`

2. **Cannot connect to backend**:
   - Check CORS settings
   - Verify `NEXT_PUBLIC_API_URL` is set correctly

## Next Steps

1. **Custom Domain**: Add your own domain name
2. **SSL Certificate**: Azure provides free SSL with custom domains
3. **Scaling**: Configure auto-scaling rules
4. **Backup**: Set up automated backups
5. **CDN**: Add Azure CDN for static assets
6. **Application Insights**: Enable monitoring and analytics

## Support

For Azure-specific issues, check:
- [Azure App Service Docs](https://docs.microsoft.com/azure/app-service/)
- [Azure CLI Reference](https://docs.microsoft.com/cli/azure/)
- [Azure Portal](https://portal.azure.com)
