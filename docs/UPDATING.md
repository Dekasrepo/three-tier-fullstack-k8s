Update Configuration
# Edit ConfigMap
kubectl edit configmap user-app-config -n user-app

# Restart pods to pick up changes
kubectl rollout restart deployment backend-deployment -n user-app


Update Application Code
# Rebuild images
docker build -t your-username/user-app-backend:v2 ./backend
docker push your-username/user-app-backend:v2

# Update deployment
kubectl set image deployment/backend-deployment \
  backend=your-username/user-app-backend:v2 \
  -n user-app

# Check rollout status
kubectl rollout status deployment/backend-deployment -n user-app