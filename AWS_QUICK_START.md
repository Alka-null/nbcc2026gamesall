# AWS Quick Start Deployment Guide

Quick commands to deploy NBCC Strategy Games to AWS.

## Prerequisites Setup (One-time)

```powershell
# 1. Install AWS CLI
winget install Amazon.AWSCLI

# 2. Install EB CLI
pip install awsebcli

# 3. Configure AWS credentials
aws configure
# Enter: Access Key ID, Secret Access Key, Region (us-east-1), Output format (json)

# 4. Verify setup
aws sts get-caller-identity
eb --version
```

---

## Backend Deployment (Elastic Beanstalk)

### Option 1: Quick Deploy (Recommended)

```powershell
cd backend

# Initialize and create (first time only)
eb init -p python-3.11 nbcc-games-backend --region us-east-1
eb create nbcc-games-prod --instance-type t3.micro

# Set environment variables (first time only)
$SECRET_KEY = python -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())"
eb setenv DJANGO_SECRET_KEY="$SECRET_KEY"
eb setenv DJANGO_DEBUG="False"
eb setenv DJANGO_ALLOWED_HOSTS=".elasticbeanstalk.com"

# Deploy application
eb deploy

# Check status and get URL
eb status
eb open
```

### Option 2: With Database (PostgreSQL RDS)

```powershell
cd backend

# Initialize and create with database
eb init -p python-3.11 nbcc-games-backend --region us-east-1
eb create nbcc-games-prod `
  --instance-type t3.micro `
  --database.engine postgres `
  --database.username nbccadmin

# Set environment variables
$SECRET_KEY = python -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())"
eb setenv DJANGO_SECRET_KEY="$SECRET_KEY"
eb setenv DJANGO_DEBUG="False"
eb setenv DJANGO_ALLOWED_HOSTS=".elasticbeanstalk.com"

# Deploy
eb deploy
eb open
```

### Subsequent Deployments

```powershell
cd backend
eb deploy
```

---

## Admin Portal Deployment (AWS Amplify)

### Via AWS Console (Easiest for first time)

1. **Login to AWS Console** → Navigate to **AWS Amplify**
2. Click **"New app"** → **"Host web app"**
3. Select **GitHub** → Authorize → Choose repository
4. **Important**: Set **App root** to `admin_portal`
5. The `amplify.yml` file will be auto-detected
6. Add environment variables:
   - `NEXT_PUBLIC_API_URL`: Your backend URL from above
   - `NODE_ENV`: `production`
7. Click **"Save and deploy"**
8. Wait 5-10 minutes for build

### Via AWS CLI

```powershell
# Note: Replace YOUR_GITHUB_TOKEN with your personal access token
# Create at: https://github.com/settings/tokens

# Create Amplify app (first time only)
$GITHUB_TOKEN = "your_github_personal_access_token"
$REPO_URL = "https://github.com/yourusername/NBCCStrategyGames"

aws amplify create-app `
  --name nbcc-games-admin `
  --repository $REPO_URL `
  --access-token $GITHUB_TOKEN `
  --enable-branch-auto-build `
  --region us-east-1

# Get App ID
$APP_ID = aws amplify list-apps --query "apps[?name=='nbcc-games-admin'].appId" --output text

# Connect branch
aws amplify create-branch `
  --app-id $APP_ID `
  --branch-name main `
  --enable-auto-build

# Set environment variables (use your backend URL)
$BACKEND_URL = "http://nbcc-games-prod.us-east-1.elasticbeanstalk.com"
aws amplify update-app `
  --app-id $APP_ID `
  --environment-variables NEXT_PUBLIC_API_URL=$BACKEND_URL,NODE_ENV=production

# Trigger deployment
aws amplify start-job `
  --app-id $APP_ID `
  --branch-name main `
  --job-type RELEASE

# Get URL
aws amplify get-app --app-id $APP_ID --query 'app.defaultDomain' --output text
```

---

## GitHub Actions CI/CD Setup

### 1. Create IAM User for GitHub Actions

```powershell
# Create user
aws iam create-user --user-name github-actions-nbcc

# Create and attach policy
$POLICY_DOCUMENT = @"
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "elasticbeanstalk:*",
        "s3:*",
        "cloudformation:*",
        "ec2:*",
        "elasticloadbalancing:*",
        "autoscaling:*",
        "cloudwatch:*",
        "rds:*",
        "amplify:*"
      ],
      "Resource": "*"
    }
  ]
}
"@

$POLICY_DOCUMENT | Out-File -FilePath policy.json -Encoding utf8

aws iam put-user-policy `
  --user-name github-actions-nbcc `
  --policy-name GitHubActionsPolicy `
  --policy-document file://policy.json

# Create access key
aws iam create-access-key --user-name github-actions-nbcc
# SAVE the Access Key ID and Secret Access Key!
```

### 2. Add Secrets to GitHub

1. Go to your GitHub repository
2. **Settings** → **Secrets and variables** → **Actions**
3. Click **"New repository secret"** and add:

```
AWS_ACCESS_KEY_ID: [from above]
AWS_SECRET_ACCESS_KEY: [from above]
AWS_REGION: us-east-1
AWS_ACCOUNT_ID: [your AWS account ID]
EB_APPLICATION_NAME: nbcc-games-backend
EB_ENVIRONMENT_NAME: nbcc-games-prod
BACKEND_URL: [your backend URL]
DJANGO_SECRET_KEY: [your Django secret key]
```

### 3. Enable Workflows

The workflows are already configured in `.github/workflows/`:
- `backend-deploy-aws.yml` - Auto-deploys backend on push to main
- `admin-deploy-aws.yml` - Auto-deploys admin on push to main

Just push to main branch and they'll run automatically!

```powershell
git add .
git commit -m "Configure AWS deployment"
git push origin main
```

---

## Common Commands

### Backend

```powershell
# View logs
eb logs

# Stream logs in real-time
eb logs --stream

# SSH into instance
eb ssh

# Update environment variables
eb setenv KEY=VALUE

# Scale instances
eb scale 2

# Terminate environment
eb terminate nbcc-games-prod
```

### Admin Portal

```powershell
# Get app info
aws amplify get-app --app-id $APP_ID

# List deployments
aws amplify list-jobs --app-id $APP_ID --branch-name main

# Trigger new deployment
aws amplify start-job --app-id $APP_ID --branch-name main --job-type RELEASE

# Update environment variables
aws amplify update-app --app-id $APP_ID --environment-variables KEY=VALUE

# Delete app
aws amplify delete-app --app-id $APP_ID
```

---

## Monitoring

### View Backend Metrics

```powershell
# Get environment health
eb health

# View CloudWatch metrics
aws cloudwatch get-metric-statistics `
  --namespace AWS/ElasticBeanstalk `
  --metric-name EnvironmentHealth `
  --dimensions Name=EnvironmentName,Value=nbcc-games-prod `
  --start-time (Get-Date).AddHours(-1) `
  --end-time (Get-Date) `
  --period 300 `
  --statistics Average
```

### View Admin Portal Metrics

```powershell
# Check build status
aws amplify list-jobs --app-id $APP_ID --branch-name main --max-items 5

# Get most recent deployment
aws amplify get-job `
  --app-id $APP_ID `
  --branch-name main `
  --job-id [JOB_ID]
```

---

## Cost Estimate

### Free Tier (First 12 months)
- **Total**: ~$0/month

### After Free Tier
- **Backend** (t3.micro): ~$8/month
- **Database** (optional, db.t3.micro): ~$15/month
- **S3 + Data Transfer**: ~$5/month
- **Amplify**: ~$0/month (within free tier)
- **Total**: ~$13-28/month

---

## Troubleshooting

### Backend won't deploy
```powershell
# Check logs
eb logs

# SSH and investigate
eb ssh
sudo tail -f /var/log/eb-engine.log
```

### Admin portal build fails
- Check build logs in AWS Amplify Console
- Verify `amplify.yml` is in repository root
- Ensure environment variables are set

### Database connection issues
```powershell
# Check environment variables
eb printenv

# Verify security groups allow connection
aws ec2 describe-security-groups
```

---

## Quick Links

- **AWS Console**: https://console.aws.amazon.com
- **Elastic Beanstalk**: https://console.aws.amazon.com/elasticbeanstalk
- **Amplify Console**: https://console.aws.amazon.com/amplify
- **CloudWatch Logs**: https://console.aws.amazon.com/cloudwatch
- **Full Documentation**: See `AWS_DEPLOYMENT_GUIDE.md`

---

## Next Steps

✅ Deploy backend to Elastic Beanstalk  
✅ Deploy admin portal to Amplify  
✅ Set up GitHub Actions for CI/CD  
⬜ Configure custom domain (optional)  
⬜ Set up monitoring and alerts  
⬜ Enable backup automation  

For detailed instructions, see [AWS_DEPLOYMENT_GUIDE.md](AWS_DEPLOYMENT_GUIDE.md)
