#!/bin/bash

# Fix Istio Sidecar Injection Issue
# This script helps resolve "Pod does not have an injected istio sidecar" error

set -e

echo "=== Istio Sidecar Injection Fix ==="
echo ""

# Get namespace (default to 'default')
NAMESPACE="${1:-default}"
APP_LABEL="app=service-binding-preview"

echo "📋 Checking namespace: $NAMESPACE"
echo ""

# Step 1: Check if Istio injection is enabled
echo "1️⃣ Checking Istio injection label..."
INJECTION_ENABLED=$(kubectl get namespace $NAMESPACE -o jsonpath='{.metadata.labels.istio-injection}' 2>/dev/null || echo "not-set")

if [ "$INJECTION_ENABLED" != "enabled" ]; then
    echo "   ⚠️  Istio injection is NOT enabled for namespace $NAMESPACE"
    echo "   🔧 Enabling Istio injection..."
    kubectl label namespace $NAMESPACE istio-injection=enabled --overwrite
    echo "   ✅ Istio injection enabled"
else
    echo "   ✅ Istio injection is already enabled"
fi

echo ""

# Step 2: Check if Istio is running
echo "2️⃣ Checking Istio components..."
ISTIO_PODS=$(kubectl get pods -n istio-system --no-headers 2>/dev/null | wc -l)

if [ "$ISTIO_PODS" -eq 0 ]; then
    echo "   ❌ No Istio pods found in istio-system namespace"
    echo "   Please ensure Istio/Kyma is properly installed"
    exit 1
else
    echo "   ✅ Found $ISTIO_PODS Istio component(s)"
fi

echo ""

# Step 3: Check current pod status
echo "3️⃣ Checking current pod status..."
POD_COUNT=$(kubectl get pods -n $NAMESPACE -l $APP_LABEL --no-headers 2>/dev/null | wc -l)

if [ "$POD_COUNT" -eq 0 ]; then
    echo "   ⚠️  No pods found with label $APP_LABEL"
    echo "   Please deploy the application first"
    exit 0
fi

kubectl get pods -n $NAMESPACE -l $APP_LABEL
CONTAINERS=$(kubectl get pods -n $NAMESPACE -l $APP_LABEL -o jsonpath='{.items[0].spec.containers[*].name}' 2>/dev/null)

echo ""
echo "   Containers: $CONTAINERS"

if [[ "$CONTAINERS" == *"istio-proxy"* ]]; then
    echo "   ✅ Istio sidecar is already injected"
    echo ""
    echo "🎉 All good! No action needed."
    exit 0
else
    echo "   ⚠️  Istio sidecar is NOT injected"
fi

echo ""

# Step 4: Recreate pods to trigger injection
echo "4️⃣ Recreating pods to trigger sidecar injection..."
echo "   This will delete and recreate the pod(s)"
read -p "   Continue? (y/N) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "   🔄 Deleting pod(s)..."
    kubectl delete pod -n $NAMESPACE -l $APP_LABEL

    echo "   ⏳ Waiting for new pod(s) to be ready..."
    kubectl wait --for=condition=ready pod -n $NAMESPACE -l $APP_LABEL --timeout=120s

    echo ""
    echo "5️⃣ Verifying sidecar injection..."
    kubectl get pods -n $NAMESPACE -l $APP_LABEL

    NEW_CONTAINERS=$(kubectl get pods -n $NAMESPACE -l $APP_LABEL -o jsonpath='{.items[0].spec.containers[*].name}')
    echo "   Containers: $NEW_CONTAINERS"

    if [[ "$NEW_CONTAINERS" == *"istio-proxy"* ]]; then
        echo ""
        echo "🎉 Success! Istio sidecar is now injected"
        echo ""
        echo "   Pod should show 2/2 READY"
        echo "   Containers: app, istio-proxy"
    else
        echo ""
        echo "❌ Failed to inject sidecar"
        echo ""
        echo "Debug steps:"
        echo "1. Check webhook configuration:"
        echo "   kubectl get mutatingwebhookconfigurations | grep istio"
        echo ""
        echo "2. Check pod events:"
        echo "   kubectl describe pod -n $NAMESPACE -l $APP_LABEL"
        echo ""
        echo "3. Check if annotation is set in deployment:"
        echo "   kubectl get deployment -n $NAMESPACE service-binding-preview -o yaml | grep 'sidecar.istio.io/inject'"
    fi
else
    echo "   ⏭️  Skipped pod recreation"
fi

echo ""
echo "=== Done ==="
