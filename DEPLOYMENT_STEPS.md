# Deployment Steps for Load Balancer Path-Based Routing

## Overview
Updated the infrastructure to route traffic directly from the load balancer to the appropriate Cloud Run services based on URL paths, eliminating the need for the UI service to proxy vehicle API requests.

## Architecture Changes

### Before
```
Load Balancer → UI Service (proxies /api/vehicles/* → Vehicle API Service)
```

### After
```
Load Balancer:
  - /api/auth/* → UI Service (OAuth handling)
  - /api/vehicles/* → Vehicle API Service (direct)
  - /api/v1/vehicles/* → Vehicle API Service (direct)
  - /* → UI Service (static files, SPA routing)
```

## Files Modified

### Infrastructure (rmm-infra)
1. **variables.tf** - Added vehicle API service variables
2. **load-balancer.tf** - Added path-based routing with separate backends
3. **cloud-run-ingress.tf** - Added vehicle API service configuration

### Application (rmm-ui)
1. **src/utils/vehicle-api.ts** - Updated to call `/api/v1/vehicles/*` directly
2. **server/index.ts** - Removed vehicle API proxy code

## Deployment Instructions

### Step 1: Import Existing Cloud Run Services (if needed)

If the vehicle API service isn't already in Terraform state:

```bash
cd ~/code/rmm-infra

# Import UI service (if not already imported)
terraform import google_cloud_run_v2_service.ui_service \
  projects/rustymaintenance/locations/us-central1/services/rmm-ui-service

# Import vehicle API service
terraform import google_cloud_run_v2_service.ui_service \
  projects/rustymaintenance/locations/us-central1/services/rmm-ui-service

```

### Step 2: Apply Infrastructure Changes

```bash
cd ~/code/rmm-infra

# Review changes
terraform plan

# Apply changes
terraform apply
```

Expected changes:
- Create NEG for vehicle API service
- Create backend service for vehicle API
- Update URL map with path-based routing
- Update both Cloud Run services for load balancer ingress

### Step 3: Deploy Updated UI Application

```bash
cd ~/code/rmm-ui

# Build the application
npm run build

# Deploy to Cloud Run (your CI/CD process)
gcloud run deploy rmm-ui-service \
  --source . \
  --region us-central1 \
  --project rustymaintenance
```

### Step 4: Verify Deployment

Test the following endpoints:

```bash
# Health check
curl https://rustymaintenanceman.com/health

# Auth endpoints (should route to UI service)
curl https://rustymaintenanceman.com/api/auth/verify

# Vehicle API endpoints (should route to vehicle API service)
curl -H "Cookie: jwt_token=YOUR_TOKEN" \
  https://rustymaintenanceman.com/api/v1/vehicles

# Legacy path support (should also work)
curl -H "Cookie: jwt_token=YOUR_TOKEN" \
  https://rustymaintenanceman.com/api/vehicles
```

## Rollback Plan

If issues occur:

1. Revert infrastructure changes:
```bash
cd ~/code/rmm-infra
git revert HEAD
terraform apply
```

2. Revert application changes:
```bash
cd ~/code/rmm-ui
git revert HEAD
npm run build
# Redeploy
```

## Benefits

1. **Performance**: Eliminates proxy hop through UI service
2. **Scalability**: Each service scales independently based on traffic
3. **Maintainability**: Clear separation of concerns
4. **Security**: Direct routing reduces attack surface
5. **Monitoring**: Easier to track metrics per service

## Notes

- Both `/api/vehicles/*` and `/api/v1/vehicles/*` paths are supported for backward compatibility
- The UI service no longer needs to know the vehicle API service URL
- JWT tokens are still in httpOnly cookies, forwarded by the browser
- Rate limiting is now handled at the load balancer level

