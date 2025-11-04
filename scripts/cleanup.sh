# ============================================
# FILE: scripts/cleanup.sh
# ============================================
# Clean up Kubernetes deployment
# Usage: ./cleanup.sh [options]
# Save this as: scripts/cleanup.sh
# Make executable: chmod +x scripts/cleanup.sh
# ============================================

cleanup_app() {
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

K8S_DIR="./k8s"
NAMESPACE="user-app"
REMOVE_ALL=false
REMOVE_VOLUMES=false
KEEP_NAMESPACE=false
FORCE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -a|--all)
            REMOVE_ALL=true
            shift
            ;;
        -v|--volumes)
            REMOVE_VOLUMES=true
            shift
            ;;
        -k|--keep-namespace)
            KEEP_NAMESPACE=true
            shift
            ;;
        -f|--force)
            FORCE=true
            shift
            ;;
        -h|--help)
            echo "Usage: ./cleanup.sh [options]"
            echo ""
            echo "Options:"
            echo "  -a, --all              Remove everything including Minikube"
            echo "  -v, --volumes          Remove volumes (deletes database data)"
            echo "  -k, --keep-namespace   Keep namespace (only delete resources)"
            echo "  -f, --force            Skip confirmation prompts"
            echo "  -h, --help             Show this help message"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            exit 1
            ;;
    esac
done

echo -e "${RED}========================================${NC}"
echo -e "${RED}  Kubernetes Cleanup Script${NC}"
echo -e "${RED}========================================${NC}"
echo ""

echo -e "${YELLOW}This will delete:${NC}"
if [ "$KEEP_NAMESPACE" = false ]; then
    echo "  • Namespace: $NAMESPACE (and all resources inside)"
else
    echo "  • All resources in namespace: $NAMESPACE"
fi
if [ "$REMOVE_VOLUMES" = true ]; then
    echo -e "  • ${RED}Persistent volumes (DATABASE DATA WILL BE LOST)${NC}"
fi
if [ "$REMOVE_ALL" = true ]; then
    echo -e "  • ${RED}Minikube cluster${NC}"
fi
echo ""

if [ "$FORCE" = false ]; then
    read -p "Are you sure you want to continue? (yes/no): " -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        echo -e "${YELLOW}Cleanup cancelled${NC}"
        exit 0
    fi
fi

if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}Error: kubectl is not installed${NC}"
    exit 1
fi

if ! kubectl get namespace "$NAMESPACE" &> /dev/null; then
    echo -e "${YELLOW}Namespace $NAMESPACE does not exist. Nothing to clean up.${NC}"
    
    if [ "$REMOVE_ALL" = true ]; then
        echo ""
        echo -e "${YELLOW}Proceeding with Minikube cleanup...${NC}"
    else
        exit 0
    fi
fi

if kubectl get namespace "$NAMESPACE" &> /dev/null; then
    echo -e "${BLUE}Current Resources in $NAMESPACE:${NC}"
    echo ""
    kubectl get all -n "$NAMESPACE" 2>/dev/null || echo "  None"
    echo ""
fi

echo -e "${RED}Starting cleanup...${NC}"
echo ""

if [ "$KEEP_NAMESPACE" = true ]; then
    echo -e "${YELLOW}Deleting resources (keeping namespace)...${NC}"
    kubectl delete ingress --all -n "$NAMESPACE" 2>/dev/null || true
    kubectl delete service --all -n "$NAMESPACE" 2>/dev/null || true
    kubectl delete deployment --all -n "$NAMESPACE" 2>/dev/null || true
    
    if [ "$REMOVE_VOLUMES" = true ]; then
        kubectl delete pvc --all -n "$NAMESPACE" 2>/dev/null || true
    fi
    
    kubectl delete configmap --all -n "$NAMESPACE" 2>/dev/null || true
    kubectl delete secret --all -n "$NAMESPACE" 2>/dev/null || true
    
    echo -e "${GREEN}✓ Resources deleted (namespace preserved)${NC}"
else
    echo -e "${YELLOW}Deleting namespace $NAMESPACE...${NC}"
    kubectl delete namespace "$NAMESPACE" --timeout=60s 2>/dev/null || true
    echo -e "${GREEN}✓ Namespace deleted${NC}"
fi

if [ "$REMOVE_ALL" = true ]; then
    echo ""
    echo -e "${RED}Cleaning up Minikube...${NC}"
    
    if command -v minikube &> /dev/null; then
        minikube stop || true
        minikube delete
        echo -e "${GREEN}✓ Minikube deleted${NC}"
    fi
fi

echo ""
if [ -d "./tls" ]; then
    rm -rf ./tls
    echo -e "${GREEN}✓ TLS directory removed${NC}"
fi

echo ""
echo -e "${GREEN}Cleanup completed!${NC}"
}

