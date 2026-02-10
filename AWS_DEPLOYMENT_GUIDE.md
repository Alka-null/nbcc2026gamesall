# AWS Deployment Guide for NBCC Strategy Games

This guide covers deploying the Python Django backend and Next.js admin portal to AWS with CI/CD pipelines.

## Architecture Overview

### Backend (Django)
- **Service**: AWS Elastic Beanstalk
- **Runtime**: Python 3.11
- **Database**: RDS PostgreSQL (Production) or SQLite (Development)
- **Storage**: S3 for static files
- **Load Balancer**: Application Load Balancer (auto-configured)

### Admin Portal (Next.js)
- **Service**: AWS Amplify
- **Runtime**: Node.js 20
- **CDN**: CloudFront (auto-configured)
- **SSL**: Auto-provisioned certificates

### CI/CD
- **Tool**: GitHub Actions
- **Triggers**: Push to main branch
- **Deployment**: Automated via AWS CLI and EB CLI

---

## Prerequisites

### 1. AWS Account Setup
```bash
# Create AWS account at https://aws.amazon.com
# Enable billing alerts in AWS Console
```

### 2. Install AWS CLI
```powershell
# Download and install from: https://aws.amazon.com/cli/
# Or using winget:
winget install Amazon.AWSCLI

# Verify installation
aws --version
```

### 3. Install EB CLI (Elastic Beanstalk)
```powershell
# Using pip
pip install awsebcli

# Verify installation
eb --version
```

### 4. Configure AWS Credentials
```powershell
# Configure AWS CLI with your credentials
aws configure

# Enter when prompted:
# AWS Access Key ID: [Your access key]
# AWS Secret Access Key: [Your secret key]
# Default region: us-east-1
# Default output format: json
```

---

## Backend Deployment (Elastic Beanstalk)

### Option 1: Manual Deployment

#### Step 1: Initialize Elastic Beanstalk
```powershell
cd backend

# Initialize EB application
eb init -p python-3.11 nbcc-games-backend --region us-east-1

# Create environment
eb create nbcc-games-prod `
  --instance-type t3.micro `
  --database.engine postgres `
  --database.username nbccadmin `
  --envvars DJANGO_SETTINGS_MODULE=nbcc_backend.settings
```

#### Step 2: Configure Environment Variables
```powershell
# Set Django secret key
eb setenv DJANGO_SECRET_KEY="your-secret-key-here"

# Set allowed hosts
eb setenv DJANGO_ALLOWED_HOSTS="nbcc-games-prod.us-east-1.elasticbeanstalk.com,yourdomain.com"

# Set debug mode
eb setenv DJANGO_DEBUG="False"

# Database configuration (if using RDS)
eb setenv DATABASE_URL="postgresql://user:pass@host:5432/dbname"

# CORS settings
eb setenv CORS_ALLOWED_ORIGINS="https://youradminportal.com,https://www.youradminportal.com"
```

#### Step 3: Deploy Application
```powershell
# Deploy to Elastic Beanstalk
eb deploy

# Open application in browser
eb open

# Check status
eb status

# View logs
eb logs
```

### Option 2: Using Deployment Script

```powershell
# Make script executable and run
.\backend\deploy-aws.sh
```

---

## Admin Portal Deployment (AWS Amplify)

### Option 1: Via AWS Console (Recommended for First Time)

1. **Login to AWS Console**
   - Navigate to AWS Amplify
   - Click "New app" > "Host web app"

2. **Connect Repository**
   - Select "GitHub"
   - Authorize AWS Amplify
   - Select repository: `NBCCStrategyGames`
   - Select branch: `main`
   - **Monorepo settings**: Set app root to `admin_portal`

3. **Configure Build Settings**
   - The `amplify.yml` file will be auto-detected
   - Verify build settings:
     ```yaml
     version: 1
     applications:
       - appRoot: admin_portal
         frontend:
           phases:
             preBuild:
               commands:
                 - npm ci
             build:
               commands:
                 - npm run build
           artifacts:
             baseDirectory: .next
             files:
               - '**/*'
           cache:
             paths:
               - node_modules/**/*
               - .next/cache/**/*
     ```

4. **Environment Variables**
   - Add in Amplify Console:
     - `NEXT_PUBLIC_API_URL`: Your backend URL
     - `NODE_ENV`: `production`

5. **Deploy**
   - Click "Save and deploy"
   - Wait for build to complete (5-10 minutes)

### Option 2: Using AWS CLI

```powershell
# Create Amplify app
aws amplify create-app `
  --name nbcc-games-admin `
  --repository https://github.com/yourusername/NBCCStrategyGames `
  --access-token YOUR_GITHUB_TOKEN `
  --enable-branch-auto-build

# Set environment variables
aws amplify update-app --app-id YOUR_APP_ID `
  --environment-variables `
  NEXT_PUBLIC_API_URL=https://your-backend-url.elasticbeanstalk.com

# Trigger build
aws amplify start-job `
  --app-id YOUR_APP_ID `
  --branch-name main `
  --job-type RELEASE
```

---

## Database Setup (Optional - RDS PostgreSQL)

### Create RDS Instance

```powershell
# Create PostgreSQL database
aws rds create-db-instance `
  --db-instance-identifier nbcc-games-db `
  --db-instance-class db.t3.micro `
  --engine postgres `
  --engine-version 15.4 `
  --master-username nbccadmin `
  --master-user-password "YourSecurePassword123!" `
  --allocated-storage 20 `
  --vpc-security-group-ids sg-xxxxx `
  --backup-retention-period 7 `
  --preferred-backup-window "03:00-04:00" `
  --publicly-accessible

# Wait for instance to be available
aws rds wait db-instance-available `
  --db-instance-identifier nbcc-games-db

# Get endpoint
aws rds describe-db-instances `
  --db-instance-identifier nbcc-games-db `
  --query 'DBInstances[0].Endpoint.Address'
```

### Update Django Settings

```python
# In settings.py, add:
import dj_database_url

DATABASES = {
    'default': dj_database_url.config(
        default=os.environ.get('DATABASE_URL', 'sqlite:///db.sqlite3'),
        conn_max_age=600
    )
}
```

### Install Required Packages

```powershell
# Add to requirements.txt
echo "dj-database-url==2.1.0" >> backend\requirements.txt
echo "psycopg2-binary==2.9.9" >> backend\requirements.txt
```

---

## GitHub Actions CI/CD Setup

### 1. Create AWS IAM User for GitHub Actions

```powershell
# Create IAM user
aws iam create-user --user-name github-actions-nbcc

# Attach policies
aws iam attach-user-policy `
  --user-name github-actions-nbcc `
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess-AWSElasticBeanstalk

aws iam attach-user-policy `
  --user-name github-actions-nbcc `
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess-Amplify

# Create access key
aws iam create-access-key --user-name github-actions-nbcc
```

### 2. Add Secrets to GitHub Repository

1. Go to your GitHub repository
2. Navigate to Settings > Secrets and variables > Actions
3. Add the following secrets:
   - `AWS_ACCESS_KEY_ID`: From IAM user creation
   - `AWS_SECRET_ACCESS_KEY`: From IAM user creation
   - `AWS_REGION`: `us-east-1`
   - `EB_APPLICATION_NAME`: `nbcc-games-backend`
   - `EB_ENVIRONMENT_NAME`: `nbcc-games-prod`
   - `AMPLIFY_APP_ID`: Your Amplify app ID
   - `DJANGO_SECRET_KEY`: Your Django secret key

### 3. Workflows Are Auto-Configured

The workflows in `.github/workflows/` will automatically deploy on push to main:
- `backend-deploy-aws.yml`: Deploys Django backend to Elastic Beanstalk
- `admin-deploy-aws.yml`: Deploys Next.js admin to Amplify

---

## S3 Static Files Setup (Optional)

### Create S3 Bucket for Static Files

```powershell
# Create bucket
aws s3 mb s3://nbcc-games-static --region us-east-1

# Enable public access for static files
aws s3api put-bucket-policy `
  --bucket nbcc-games-static `
  --policy '{
    "Version": "2012-10-17",
    "Statement": [{
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::nbcc-games-static/*"
    }]
  }'

# Configure CORS
aws s3api put-bucket-cors `
  --bucket nbcc-games-static `
  --cors-configuration '{
    "CORSRules": [{
      "AllowedOrigins": ["*"],
      "AllowedMethods": ["GET", "HEAD"],
      "AllowedHeaders": ["*"],
      "MaxAgeSeconds": 3000
    }]
  }'
```

### Update Django Settings for S3

```python
# Add to requirements.txt
# boto3==1.34.0
# django-storages==1.14.2

# In settings.py:
if os.environ.get('USE_S3') == 'True':
    AWS_STORAGE_BUCKET_NAME = os.environ.get('AWS_STORAGE_BUCKET_NAME')
    AWS_S3_REGION_NAME = os.environ.get('AWS_S3_REGION_NAME', 'us-east-1')
    AWS_S3_CUSTOM_DOMAIN = f'{AWS_STORAGE_BUCKET_NAME}.s3.amazonaws.com'
    
    STATICFILES_STORAGE = 'storages.backends.s3boto3.S3Boto3Storage'
    STATIC_URL = f'https://{AWS_S3_CUSTOM_DOMAIN}/static/'
```

---

## Cost Estimation

### Free Tier (First 12 Months)
- **Elastic Beanstalk**: Free (pay only for EC2)
- **EC2 t3.micro**: 750 hours/month free
- **RDS db.t3.micro**: 750 hours/month free
- **S3**: 5GB storage, 20,000 GET, 2,000 PUT free
- **Amplify**: 1000 build minutes free, 15GB served/month
- **Total**: **$0/month** (within free tier limits)

### After Free Tier (Production)
- **EC2 t3.micro**: ~$8/month
- **RDS db.t3.micro**: ~$15/month (with storage)
- **Elastic Beanstalk**: Free (pay for resources)
- **S3**: ~$1/month (for 10GB + transfers)
- **Amplify**: Free for first 1000 build minutes, then $0.01/minute
- **Data Transfer**: ~$5/month
- **Total**: **~$29/month**

### Production Scale (Medium Traffic)
- **EC2 t3.small** (2x instances): ~$32/month
- **RDS db.t3.small**: ~$30/month
- **Application Load Balancer**: ~$20/month
- **S3 + CloudFront**: ~$10/month
- **Amplify**: ~$5/month
- **Total**: **~$97/month**

---

## Environment Configuration

### Backend Environment Variables

Set via `eb setenv` or AWS Console:

```bash
DJANGO_SECRET_KEY=your-secret-key-here
DJANGO_DEBUG=False
DJANGO_ALLOWED_HOSTS=.elasticbeanstalk.com,yourdomain.com
DATABASE_URL=postgresql://user:pass@host:5432/dbname
CORS_ALLOWED_ORIGINS=https://yourdomain.com
USE_S3=True
AWS_STORAGE_BUCKET_NAME=nbcc-games-static
AWS_S3_REGION_NAME=us-east-1
```

### Admin Portal Environment Variables

Set in Amplify Console:

```bash
NEXT_PUBLIC_API_URL=https://your-backend.elasticbeanstalk.com
NODE_ENV=production
```

---

## Monitoring and Logging

### CloudWatch Logs

```powershell
# View backend logs
eb logs

# Tail logs in real-time
eb logs --stream

# View specific log file
aws logs tail /aws/elasticbeanstalk/nbcc-games-prod/var/log/eb-engine.log --follow
```

### Application Performance Monitoring

```powershell
# Enable X-Ray tracing
eb config

# In the editor, add:
# aws:elasticbeanstalk:xray:
#   XRayEnabled: true
```

### Set Up CloudWatch Alarms

```powershell
# CPU alarm
aws cloudwatch put-metric-alarm `
  --alarm-name nbcc-backend-high-cpu `
  --alarm-description "Alert when CPU exceeds 80%" `
  --metric-name CPUUtilization `
  --namespace AWS/EC2 `
  --statistic Average `
  --period 300 `
  --threshold 80 `
  --comparison-operator GreaterThanThreshold `
  --evaluation-periods 2
```

---

## Troubleshooting

### Backend Issues

**Problem**: Deployment fails
```powershell
# Check logs
eb logs

# SSH into instance
eb ssh

# Check application status
sudo systemctl status web
```

**Problem**: Database connection errors
```powershell
# Verify DATABASE_URL
eb printenv

# Test database connection
eb ssh
python manage.py dbshell
```

**Problem**: Static files not loading
```powershell
# Collect static files
eb ssh
cd /var/app/current
python manage.py collectstatic --noinput

# Or enable S3 storage (see S3 section)
```

### Admin Portal Issues

**Problem**: Build fails
- Check build logs in Amplify Console
- Verify `amplify.yml` configuration
- Ensure all dependencies in `package.json`

**Problem**: Environment variables not working
- Verify variables in Amplify Console > App settings > Environment variables
- Restart deployment after adding variables

**Problem**: API calls failing
- Verify `NEXT_PUBLIC_API_URL` is correct
- Check CORS settings in backend
- Verify backend is running and accessible

---

## Custom Domain Setup

### Backend Custom Domain

```powershell
# Option 1: Using Route 53
aws route53 create-hosted-zone --name api.yourdomain.com

# Get EB environment CNAME
eb status

# Create CNAME record
aws route53 change-resource-record-sets `
  --hosted-zone-id YOUR_ZONE_ID `
  --change-batch '{
    "Changes": [{
      "Action": "CREATE",
      "ResourceRecordSet": {
        "Name": "api.yourdomain.com",
        "Type": "CNAME",
        "TTL": 300,
        "ResourceRecords": [{"Value": "your-env.elasticbeanstalk.com"}]
      }
    }]
  }'

# Option 2: Using EB Console
# Go to EB Console > Configuration > Load balancer > Add listener
# Upload SSL certificate or use ACM
```

### Admin Portal Custom Domain

1. **Get Domain in Amplify Console**
   - Go to App settings > Domain management
   - Click "Add domain"
   - Enter your domain
   - Follow DNS configuration instructions

2. **Or via CLI**:
```powershell
aws amplify create-domain-association `
  --app-id YOUR_APP_ID `
  --domain-name yourdomain.com `
  --sub-domain-settings prefix=www,branchName=main
```

---

## Scaling Configuration

### Auto Scaling (Elastic Beanstalk)

```powershell
# Configure auto scaling
eb config

# Add/modify in editor:
aws:autoscaling:asg:
  MinSize: 1
  MaxSize: 4
aws:autoscaling:trigger:
  MeasureName: CPUUtilization
  Statistic: Average
  Unit: Percent
  UpperThreshold: 80
  LowerThreshold: 20
```

### Database Scaling (RDS)

```powershell
# Increase storage
aws rds modify-db-instance `
  --db-instance-identifier nbcc-games-db `
  --allocated-storage 50 `
  --apply-immediately

# Change instance class
aws rds modify-db-instance `
  --db-instance-identifier nbcc-games-db `
  --db-instance-class db.t3.small `
  --apply-immediately
```

---

## Backup and Disaster Recovery

### Database Backups

```powershell
# Create manual snapshot
aws rds create-db-snapshot `
  --db-instance-identifier nbcc-games-db `
  --db-snapshot-identifier nbcc-games-backup-$(Get-Date -Format "yyyy-MM-dd")

# List snapshots
aws rds describe-db-snapshots `
  --db-instance-identifier nbcc-games-db

# Restore from snapshot
aws rds restore-db-instance-from-db-snapshot `
  --db-instance-identifier nbcc-games-db-restored `
  --db-snapshot-identifier nbcc-games-backup-2026-02-09
```

### Application Backups

```powershell
# Export application version
eb appversion

# Create application archive
eb deploy --staged

# Save environment configuration
eb config save nbcc-games-prod --cfg production-config
```

---

## Security Best Practices

### 1. IAM Roles
- Use IAM roles instead of access keys when possible
- Apply principle of least privilege
- Rotate access keys regularly

### 2. Security Groups
```powershell
# Restrict database access to backend only
aws ec2 authorize-security-group-ingress `
  --group-id sg-database `
  --protocol tcp `
  --port 5432 `
  --source-group sg-backend
```

### 3. Environment Variables
- Never commit secrets to Git
- Use AWS Secrets Manager for sensitive data
- Rotate secrets regularly

### 4. SSL/TLS
- Enable HTTPS only in production
- Use AWS Certificate Manager for free SSL certificates
- Enable HTTP to HTTPS redirect

### 5. WAF (Web Application Firewall)
```powershell
# Create WAF web ACL
aws wafv2 create-web-acl `
  --scope REGIONAL `
  --name nbcc-games-waf `
  --default-action Block={} `
  --rules file://waf-rules.json
```

---

## Next Steps

1. **Review this guide** and deployment scripts
2. **Set up AWS account** and install CLI tools
3. **Deploy backend** to Elastic Beanstalk
4. **Deploy admin portal** to Amplify
5. **Configure CI/CD** with GitHub Actions
6. **Set up monitoring** with CloudWatch
7. **Configure custom domains** (optional)
8. **Enable backups** and disaster recovery

For quick deployment, see `AWS_QUICK_START.md`.

For support, check AWS documentation:
- Elastic Beanstalk: https://docs.aws.amazon.com/elasticbeanstalk/
- Amplify: https://docs.aws.amazon.com/amplify/
- RDS: https://docs.aws.amazon.com/rds/
