# Kyma Deployment Guide

This guide explains how to deploy the Service Binding Preview application to Kyma with API Gateway integration.

## Prerequisites

- Kyma cluster (v2.0+)
- kubectl configured to access your Kyma cluster
- Docker image pushed to GHCR (automated via GitHub Actions)

## Architecture

```
[User] → [Kyma API Gateway] → [Service] → [Deployment] → [Pod]
                                              ↓
                                      [ServiceBinding]
                                              ↓
                                      [Service Instance]
```

## Quick Deploy

1. **Update the image reference** in `k8s/deployment.yaml`:
   ```yaml
   image: ghcr.io/YOUR_USERNAME/service-binding-preview:latest
   ```

2. **Enable Istio sidecar injection** (choose one method):

   **Option A: Enable at namespace level** (Recommended)
   ```bash
   kubectl label namespace default istio-injection=enabled
   ```

   **Option B: Use the provided namespace manifest**
   ```bash
   kubectl apply -f k8s/namespace.yaml
   ```

   **Option C: Already configured in deployment**
   The deployment already has the annotation:
   ```yaml
   annotations:
     sidecar.istio.io/inject: "true"
   ```

3. **Deploy to Kyma**:
   ```bash
   kubectl apply -f k8s/deployment.yaml
   kubectl apply -f k8s/apirule.yaml
   ```

4. **Verify deployment**:
   ```bash
   kubectl get pods -l app=service-binding-preview
   kubectl get svc service-binding-preview
   kubectl get apirule service-binding-preview

   # Check if Istio sidecar is injected (should show 2/2 containers)
   kubectl get pods -l app=service-binding-preview -o wide
   ```

5. **Get the URL**:
   ```bash
   kubectl get apirule service-binding-preview -o jsonpath='{.spec.host}'
   ```

## APIRule Configuration

The `apirule.yaml` exposes your application through Kyma API Gateway with:

- **Handler**: `noop` (no authentication) - change to `oauth2_introspection` or `jwt` for production
- **Methods**: All HTTP methods allowed
- **Path**: `(/.*` matches all routes

### Secure APIRule (Production)

For production, update the access strategy:

```yaml
accessStrategies:
  - handler: jwt
    config:
      jwks_urls:
        - "https://your-issuer.com/.well-known/jwks.json"
      trusted_issuers:
        - "https://your-issuer.com"
```

Or use OAuth2:

```yaml
accessStrategies:
  - handler: oauth2_introspection
    config:
      required_scope: ["read", "write"]
```

## Environment Variables

The application reads environment variables from:

1. **ConfigMap** (non-sensitive config)
2. **Secret** (sensitive data like API keys)
3. **ServiceBinding** (injected by Kyma)

Example ConfigMap:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: service-binding-preview-config
data:
  APP_NAME: "Service Binding Preview"
  ENVIRONMENT: "production"
  VERSION: "1.0.0"
```

Then reference in deployment:

```yaml
envFrom:
- configMapRef:
    name: service-binding-preview-config
- secretRef:
    name: service-binding-preview-secrets
```

## Health Checks

The application provides three health endpoints:

- `/health` - Detailed health status (custom)
- `/healthz` - Kubernetes liveness probe
- `/readyz` - Kubernetes readiness probe

These are configured in the deployment:

```yaml
livenessProbe:
  httpGet:
    path: /healthz
    port: 3000
  initialDelaySeconds: 10
  periodSeconds: 10

readinessProbe:
  httpGet:
    path: /readyz
    port: 3000
  initialDelaySeconds: 5
  periodSeconds: 5
```

## Monitoring with Kyma

Enable monitoring by adding Prometheus annotations:

```yaml
metadata:
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "3000"
    prometheus.io/path: "/metrics"
```

## Troubleshooting

### 1. Pod does not have an injected Istio sidecar

**Symptoms**:
- Pod shows `1/1` containers instead of `2/2`
- APIRule doesn't route traffic correctly
- Error: "Pod does not have an injected istio sidecar"

**Root Cause**: Istio sidecar injection is not enabled for the namespace or pod

**Solutions**:

**Option A: Enable at namespace level** (Recommended - affects all pods)
```bash
# Check current namespace labels
kubectl get namespace default --show-labels

# Enable Istio injection for the namespace
kubectl label namespace default istio-injection=enabled --overwrite

# Delete existing pods to trigger re-creation with sidecar
kubectl delete pod -l app=service-binding-preview

# Wait for pod to be recreated
kubectl wait --for=condition=ready pod -l app=service-binding-preview --timeout=60s

# Verify sidecar is injected (should show 2/2 READY)
kubectl get pods -l app=service-binding-preview
```

**Option B: Use pod annotation** (Already configured in deployment.yaml)
```yaml
template:
  metadata:
    annotations:
      sidecar.istio.io/inject: "true"
```

**Option C: Apply namespace manifest**
```bash
kubectl apply -f k8s/namespace.yaml
kubectl delete pod -l app=service-binding-preview
```

**Verification Steps**:

1. Check if Istio injection is enabled:
```bash
# Check namespace label
kubectl get namespace default --show-labels | grep istio-injection

# Check pod annotation
kubectl get deployment service-binding-preview -o yaml | grep "sidecar.istio.io/inject"
```

2. Verify Istio components are running:
```bash
kubectl get pods -n istio-system
# Should see istiod pod running
```

3. Check mutating webhook:
```bash
kubectl get mutatingwebhookconfigurations | grep istio-sidecar-injector
```

4. Inspect pod containers:
```bash
kubectl get pods -l app=service-binding-preview -o jsonpath='{.items[0].spec.containers[*].name}'
# Should output: app istio-proxy
```

5. Check pod events for injection issues:
```bash
kubectl describe pod -l app=service-binding-preview | grep -A 10 Events
```

### 2. ImagePullBackOff
