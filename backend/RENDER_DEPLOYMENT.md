# SmartCanteen Backend - Render Deployment Guide

This guide walks you through deploying the SmartCanteen backend to Render.com (free tier available).

## ✅ Pre-Deployment Checklist

- [ ] All files committed to git
- [ ] `.env` file is in `.gitignore` (verified ✅)
- [ ] `Dockerfile` is present and tested
- [ ] `server.js` has graceful shutdown handlers (updated ✅)
- [ ] `render.yaml` configuration file exists (created ✅)
- [ ] MongoDB Atlas account with connection string
- [ ] Render.com account

---

## 📋 Step-by-Step Deployment

### Step 1: Prepare Your Repository

Make sure all changes are committed:

```bash
cd d:\SmartCanteen
git add backend/
git commit -m "Prepare backend for Render deployment"
git push origin main
```

### Step 2: Create Render Account & Project

1. Go to [render.com](https://dashboard.render.com)
2. Sign up / Log in
3. Click **"New +"** → **"Web Service"**

### Step 3: Connect GitHub Repository

1. Select **"Build and deploy from a Git repository"**
2. Click **"Connect account"** and authorize GitHub
3. Search for and select your **SmartCanteen** repository
4. Click **"Connect"**

### Step 4: Configure Deployment Settings

Fill in the deployment form:

| Setting | Value |
|---------|-------|
| **Name** | `smartcanteen-backend` |
| **Environment** | `Node` |
| **Region** | Choose closest to your users |
| **Branch** | `main` |
| **Build Command** | `npm install` |
| **Start Command** | `npm start` |
| **Instance Type** | `Free` (or `Standard` for better performance) |

### Step 5: Add Environment Variables

Click **"Advanced"** → **"Add Environment Variable"** for each:

#### Required Variables:

1. **MONGODB_URI** (Secret ⚠️)
   - Value: Your MongoDB Atlas connection string
   - Example: `mongodb+srv://username:password@cluster.mongodb.net/smartcanteen?retryWrites=true&w=majority`
   - ⚠️ Check **"Secret"** checkbox to protect this

2. **JWT_SECRET** (Secret ⚠️)
   - Value: Your JWT secret key (generate a strong one!)
   - Example: `your-super-secret-jwt-key-generate-new-one`
   - ⚠️ Check **"Secret"** checkbox to protect this

3. **NODE_ENV**
   - Value: `production`

4. **PORT**
   - Value: `3000`

#### How to Generate a Secure JWT Secret:

```bash
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

### Step 6: Deploy

1. Review all settings
2. Click **"Deploy"**
3. Wait for build to complete (2-5 minutes)
4. View logs in the **"Logs"** section

### Step 7: Verify Deployment

Once deployment is complete:

1. Click the generated URL (e.g., `https://smartcanteen-backend.onrender.com`)
2. Test the health endpoint: 
   ```
   https://smartcanteen-backend.onrender.com/health
   ```
   Should return: `{"status":"Server is running"}`

---

## 🔗 Update Frontend Configuration

Once your backend is deployed on Render, update your Flutter app's API base URL:

### In `lib/services/api_service.dart`:

```dart
// Change from localhost to Render URL
final String baseUrl = 'https://smartcanteen-backend.onrender.com/api';
```

---

## 📊 Monitoring & Logs

### View Logs:
1. Go to your Render dashboard
2. Select **"smartcanteen-backend"**
3. Click **"Logs"** tab
4. View real-time server logs

### Health Check:
The server includes a health check endpoint at `/health`

```bash
curl https://smartcanteen-backend.onrender.com/health
```

---

## 🚀 Scaling & Performance Tips

### Free Tier Limitations:
- Server spins down after 15 minutes of inactivity
- First request after spin-down takes longer (~30 seconds)
- Limited to 1 instance

### Upgrade to Standard for Production:
- Always-on instances
- Better performance
- Higher uptime SLA
- In Render dashboard: **"Settings"** → **"Instance Type"** → Select **"Standard"**

---

## 🐛 Common Issues & Solutions

### Issue: Build fails with "npm not found"
**Solution:** Ensure `Dockerfile` uses correct Node.js version (18-alpine)

### Issue: "Cannot find module" error
**Solution:** 
```bash
# Ensure all dependencies are in package.json
npm install your-missing-package
git push
# Redeploy in Render dashboard
```

### Issue: MongoDB connection timeout
**Solution:** 
1. Check MongoDB Atlas IP whitelist includes Render servers (0.0.0.0/0)
2. Verify MONGODB_URI is correct
3. Check database credentials

### Issue: Server boots but no requests work
**Solution:** Check that all environment variables are set in Render dashboard

### Issue: "Address already in use"
**Solution:** Server is already running. Render handles this automatically - just redeploy.

---

## 📝 Environment Variables Summary

| Variable | Type | Required | Example |
|----------|------|----------|---------|
| `MONGODB_URI` | Secret | ✅ Yes | `mongodb+srv://user:pass@cluster.mongodb.net/db` |
| `JWT_SECRET` | Secret | ✅ Yes | `your-secure-random-key` |
| `NODE_ENV` | Standard | ✅ Yes | `production` |
| `PORT` | Standard | ❌ No | `3000` |

---

## 🔒 Security Checklist

- [ ] `.env` file is local only (not in git)
- [ ] MongoDB credentials are in Render secrets (not public)
- [ ] JWT_SECRET is strong and unique
- [ ] CORS is configured appropriately
- [ ] MongoDB Atlas has IP whitelist configured
- [ ] All sensitive data is marked as "Secret" in Render

---

## 📱 Testing API from Flutter

After deployment, test your API from the Flutter app:

```dart
final response = await http.get(
  Uri.parse('https://smartcanteen-backend.onrender.com/api/health'),
);

print(response.statusCode); // Should be 200
print(response.body); // Should show status message
```

---

## 🆘 Getting Help

- Check [Render Docs](https://render.com/docs)
- View server logs in Render dashboard
- Check [MongoDB Atlas Help](https://www.mongodb.com/docs/atlas/)
- Verify Docker configuration with: `docker build -t smartcanteen-backend .`

---

## 📞 Post-Deployment Actions

1. **Update Flutter app** with Render URL
2. **Test all API endpoints** from the app
3. **Monitor logs** for first 24 hours
4. **Set up error tracking** (optional: Sentry, LogRocket)
5. **Configure custom domain** (optional: in Render settings)

---

**Deployed on:** [Date]  
**Backend URL:** `https://smartcanteen-backend.onrender.com`  
**MongoDB:** Atlas  
**Status:** ✅ Ready for production
