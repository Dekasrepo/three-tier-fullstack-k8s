# ============================================
# FILE: scripts/deploy.sh
# ============================================
# Deploy the full-stack application to Kubernetes
# Usage: ./deploy.sh [options]
# Save this as: scripts/deploy.sh
# Make executable: chmod +x scripts/deploy.sh
# ============================================

deploy_app() {
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

K8S_DIR="./k8s"
NAMESPACE="user-app"
SKIP_MINIKUBE=false
WATCH_PODS=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--skip-minikube)
            SKIP_MINIKUBE=true
            shift
            ;;
        -w|--watch)
            WATCH_PODS=true
            shift
            ;;
        -h|--help)
            echo "Usage: ./deploy.sh [options]"
            echo ""
            echo "Options:"
            echo "  -s, --skip-minikube    Skip Minikube checks"
            echo "  -w, --watch            Watch pod status after deployment"
            echo "  -h, --help             Show this help message"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            exit 1
            ;;
    esac
done

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Kubernetes Deployment Script${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}Error: kubectl is not installed${NC}"
    exit 1
fi

if [ ! -d "$K8S_DIR" ]; then
    echo -e "${RED}Error: $K8S_DIR directory not found${NC}"
    exit 1
fi

if [ "$SKIP_MINIKUBE" = false ]; then
    echo -e "${YELLOW}Checking Minikube status...${NC}"
    
    if ! command -v minikube &> /dev/null; then
        echo -e "${RED}Error: minikube is not installed${NC}"
        exit 1
    fi
    
    if ! minikube status &> /dev/null; then
        echo -e "${YELLOW}Minikube is not running. Starting...${NC}"
        minikube start --cpus=4 --memory=4096
    else
        echo -e "${GREEN}✓ Minikube is running${NC}"
    fi
    
    if ! minikube addons list | grep -q "ingress.*enabled"; then
        echo -e "${YELLOW}Enabling ingress addon...${NC}"
        minikube addons enable ingress
    else
        echo -e "${GREEN}✓ Ingress addon enabled${NC}"
    fi
    
    echo ""
fi

if [ "$SKIP_MINIKUBE" = false ]; then
    MINIKUBE_IP=$(minikube ip)
    echo -e "${BLUE}Minikube IP:${NC} $MINIKUBE_IP"
    echo -e "${YELLOW}Make sure /etc/hosts has:${NC} $MINIKUBE_IP jideka.com.ng"
    echo ""
fi

echo -e "${YELLOW}Step 1/12:${NC} Creating namespace..."
kubectl apply -f "$K8S_DIR/01-namespace.yaml"
echo -e "${GREEN}✓ Namespace created/updated${NC}"
echo ""

echo -e "${YELLOW}Step 2/12:${NC} Deploying ConfigMap..."
kubectl apply -f "$K8S_DIR/02-configmap.yaml"
echo -e "${GREEN}✓ ConfigMap deployed${NC}"
echo ""

echo -e "${YELLOW}Step 3/12:${NC} Deploying Secret..."
kubectl apply -f "$K8S_DIR/03-secret.yaml"
echo -e "${GREEN}✓ Secret deployed${NC}"
echo ""

echo -e "${YELLOW}Step 4/12:${NC} Deploying TLS Secret..."
if [ -f "$K8S_DIR/04-tls-secret.yaml" ]; then
    kubectl apply -f "$K8S_DIR/04-tls-secret.yaml"
    echo -e "${GREEN}✓ TLS Secret deployed${NC}"
else
    echo -e "${YELLOW}⚠ TLS Secret not found. Run ./setup-tls.sh first${NC}"
    echo "  Continuing without TLS..."
fi
echo ""

echo -e "${YELLOW}Step 5/12:${NC} Creating PersistentVolumeClaim for MongoDB..."
kubectl apply -f "$K8S_DIR/05-mongodb-pvc.yaml"
echo -e "${GREEN}✓ PVC created${NC}"
echo ""

echo -e "${YELLOW}Step 6/12:${NC} Deploying MongoDB..."
kubectl apply -f "$K8S_DIR/06-mongodb-deployment.yaml"
echo -e "${GREEN}✓ MongoDB Deployment created${NC}"
echo ""

echo -e "${YELLOW}Step 7/12:${NC} Creating MongoDB Service..."
kubectl apply -f "$K8S_DIR/07-mongodb-service.yaml"
echo -e "${GREEN}✓ MongoDB Service created${NC}"
echo ""

echo -e "${YELLOW}Waiting for MongoDB to be ready...${NC}"
kubectl wait --for=condition=ready pod -l app=mongodb -n "$NAMESPACE" --timeout=120s
echo -e "${GREEN}✓ MongoDB is ready${NC}"
echo ""

echo -e "${YELLOW}Step 8/12:${NC} Deploying Backend API..."
kubectl apply -f "$K8S_DIR/08-backend-deployment.yaml"
echo -e "${GREEN}✓ Backend Deployment created${NC}"
echo ""

echo -e "${YELLOW}Step 9/12:${NC} Creating Backend Service..."
kubectl apply -f "$K8S_DIR/09-backend-service.yaml"
echo -e "${GREEN}✓ Backend Service created${NC}"
echo ""

echo -e "${YELLOW}Waiting for Backend to be ready...${NC}"
kubectl wait --for=condition=ready pod -l app=backend -n "$NAMESPACE" --timeout=120s
echo -e "${GREEN}✓ Backend is ready${NC}"
echo ""

echo -e "${YELLOW}Step 10/12:${NC} Deploying Frontend..."
kubectl apply -f "$K8S_DIR/10-frontend-deployment.yaml"
echo -e "${GREEN}✓ Frontend Deployment created${NC}"
echo ""

echo -e "${YELLOW}Step 11/12:${NC} Creating Frontend Service..."
kubectl apply -f "$K8S_DIR/11-frontend-service.yaml"
echo -e "${GREEN}✓ Frontend Service created${NC}"
echo ""

echo -e "${YELLOW}Waiting for Frontend to be ready...${NC}"
kubectl wait --for=condition=ready pod -l app=frontend -n "$NAMESPACE" --timeout=120s
echo -e "${GREEN}✓ Frontend is ready${NC}"
echo ""

echo -e "${YELLOW}Step 12/12:${NC} Deploying Ingress..."
kubectl apply -f "$K8S_DIR/12-ingress.yaml"
echo -e "${GREEN}✓ Ingress created${NC}"
echo ""

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Deployment Summary${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

echo -e "${BLUE}Deployments:${NC}"
kubectl get deployments -n "$NAMESPACE"
echo ""

echo -e "${BLUE}Services:${NC}"
kubectl get services -n "$NAMESPACE"
echo ""

echo -e "${BLUE}Ingress:${NC}"
kubectl get ingress -n "$NAMESPACE"
echo ""

echo -e "${BLUE}Pods:${NC}"
kubectl get pods -n "$NAMESPACE"
echo ""

INGRESS_HOST=$(kubectl get ingress user-app-ingress -n "$NAMESPACE" -o jsonpath='{.spec.rules[0].host}')
TLS_ENABLED=$(kubectl get ingress user-app-ingress -n "$NAMESPACE" -o jsonpath='{.spec.tls}')

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Access Your Application${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

if [ -n "$TLS_ENABLED" ]; then
    echo -e "${BLUE}Application URL:${NC} https://$INGRESS_HOST"
else
    echo -e "${BLUE}Application URL:${NC} http://$INGRESS_HOST"
fi

echo ""
echo -e "${BLUE}Useful Commands:${NC}"
echo -e "  View pods:    ${YELLOW}kubectl get pods -n $NAMESPACE${NC}"
echo -e "  View logs:    ${YELLOW}kubectl logs -n $NAMESPACE -l app=backend${NC}"
echo ""

if [ "$WATCH_PODS" = true ]; then
    echo -e "${BLUE}Watching pod status (Ctrl+C to exit)...${NC}"
    echo ""
    kubectl get pods -n "$NAMESPACE" -w
fi

echo -e "${GREEN}Deployment completed successfully!${NC}"
}
