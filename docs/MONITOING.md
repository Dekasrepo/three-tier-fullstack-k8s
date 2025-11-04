📊 Monitoring

# Watch pods
kubectl get pods -n user-app -w

# Stream logs
kubectl logs -f -n user-app -l app=backend

# Port forward for direct access
kubectl port-forward -n user-app service/backend-service 3000:3000
