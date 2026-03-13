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

2. **Deploy to Kyma**:
   ```bash
   kubectl apply -f k8s/deployment.yaml
   kubectl apply -f k8s/apirule.yaml
   ```

3. **Verify deployment**:
   ```bash
   kubectl get pods -l app=service-binding-preview
   kubectl get svc service-binding-preview
   kubectl get apirule service-binding-preview
   ```

4. **Get the URL**:
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

## Service Binding

### Using Kyma Service Catalog

1. **Create a Service Instance**:
   ```bash
   kubectl apply -f - <<EOF
   apiVersion: servicecatalog.kyma-project.io/v1alpha1
   kind: ServiceInstance
   metadata:
     name: postgres-instance
   spec:
     serviceClassExternalName: postgresql
     servicePlanExternalName: small
   EOF
   ```

2. **Create a Service Binding**:
   ```bash
   kubectl apply -f - <<EOF
   apiVersion: servicecatalog.kyma-project.io/v1alpha1
   kind: ServiceBinding
   metadata:
     name: service-binding-preview-db
   spec:
     instanceRef:
       name: postgres-instance
     secretName: db-credentials
   EOF
   ```

3. **Update Deployment to use binding**:
   ```yaml
   env:
   - name: DATABASE_URL
     valueFrom:
       secretKeyRef:
         name: db-credentials
         key: uri
   ```

### Using Service Binding Specification

```yaml
apiVersion: servicebinding.io/v1alpha3
kind: ServiceBinding
metadata:
  name: app-db-binding
spec:
  service:
    apiVersion: v1
    kind: Secret
    name: database-credentials
  workload:
    apiVersion: apps/v1
    kind: Deployment
    name: service-binding-preview
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

### Check logs
```bash
kubectl logs -l app=service-binding-preview -f
```

### Check API Gateway status
```bash
kubectl get virtualservice -n kyma-system
kubectl describe apirule service-binding-preview
```

### Test connectivity
```bash
# Port-forward to test locally
kubectl port-forward svc/service-binding-preview 8080:80

# Test endpoints
curl http://localhost:8080/
curl http://localhost:8080/health
curl http://localhost:8080/healthz
curl http://localhost:8080/readyz
```

### Common Issues

1. **ImagePullBackOff**: Ensure GHCR image is accessible
   ```bash
   kubectl create secret docker-registry ghcr-secret \
     --docker-server=ghcr.io \
     --docker-username=YOUR_USERNAME \
     --docker-password=YOUR_PAT
   ```

2. **APIRule not working**: Check Istio/API Gateway status
   ```bash
   kubectl get pods -n kyma-system | grep gateway
   ```

3. **Service Binding not injecting**: Verify ServiceBinding status
   ```bash
   kubectl get servicebinding
   kubectl describe servicebinding service-binding-preview-db
   ```

## Scaling

Scale the deployment:

```bash
kubectl scale deployment service-binding-preview --replicas=3
```

Or use HorizontalPodAutoscaler:

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: service-binding-preview-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: service-binding-preview
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

## Cleanup

Remove all resources:

```bash
kubectl delete -f k8s/
```

## Next Steps

- Configure authentication in APIRule
- Set up service bindings for databases
- Add monitoring and alerting
- Configure rate limiting
- Set up CORS policies
