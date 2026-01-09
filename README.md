## 🚀 Full-Stack User Management App on Kubernetes
A complete full-stack application demonstrating all major Kubernetes components, deployed with TLS/HTTPS support using mkcert.


### 📋 Table of Contents
- Overview
- Architecture
- Technologies Used
- Prerequisites
- Quick Start
- Detailed Setup
- Kubernetes Components
- TLS/HTTPS Setup
- Troubleshooting
- Contributing
- License

### 🎯 Overview
This project demonstrates how to deploy a full-stack application on Kubernetes with:

- Frontend: HTML/JavaScript user interface
- Backend: Node.js REST API
- Database: MongoDB with persistent storage
- Secure Access: HTTPS with TLS certificates using mkcert
- All K8s Components: ConfigMap, Secret, PVC, Deployments, Services, Ingress

Live Demo: https://jideka.com.ng (when deployed, use your own host name)

### 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         User Browser                         │
│                    https://jideka.com.ng                     │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                    Kubernetes Cluster                        │
│  ┌────────────────────────────────────────────────────────┐ │
│  │                 Ingress Controller                      │ │
│  │              (TLS Termination + Routing)                │ │
│  └─────────────┬──────────────────────┬───────────────────┘ │
│                │                      │                      │
│       /api/*   │                      │  /*                 │
│                ▼                      ▼                      │
│  ┌──────────────────────┐  ┌──────────────────────┐        │
│  │  Backend Service      │  │  Frontend Service     │        │
│  │  (ClusterIP:3000)     │  │  (ClusterIP:80)       │        │
│  └──────────┬────────────┘  └──────────┬───────────┘        │
│             │                           │                     │
│             ▼                           ▼                     │
│  ┌──────────────────────┐  ┌──────────────────────┐        │
│  │ Backend Pods (×2)     │  │ Frontend Pods (×2)    │        │
│  │ - Node.js API         │  │ - Nginx + HTML        │        │
│  │ - Port 3000           │  │ - Port 80             │        │
│  └──────────┬────────────┘  └───────────────────────┘        │
│             │                                                 │
│             │ reads config                                    │
│             ├──────────┐                                      │
│             │          │                                      │
│             ▼          ▼                                      │
│  ┌──────────────┐ ┌────────────┐                            │
│  │  ConfigMap    │ │  Secret    │                            │
│  │  - MAX_USERS  │ │  - API_KEY │                            │
│  │  - APP_NAME   │ │  - DB_PASS │                            │
│  └───────────────┘ └────────────┘                            │
│             │                                                 │
│             │ connects to                                     │
│             ▼                                                 │
│  ┌──────────────────────┐                                    │
│  │  MongoDB Service      │                                    │
│  │  (ClusterIP:27017)    │                                    │
│  └──────────┬────────────┘                                    │
│             │                                                 │
│             ▼                                                 │
│  ┌──────────────────────┐                                    │
│  │  MongoDB Pod          │                                    │
│  │  - Port 27017         │                                    │
│  └──────────┬────────────┘                                    │
│             │                                                 │
│             ▼                                                 │
│  ┌──────────────────────┐                                    │
│  │  Persistent Volume    │                                    │
│  │  (1Gi Storage)        │                                    │
│  └───────────────────────┘                                    │
└─────────────────────────────────────────────────────────────┘

```

### 🛠️ Technologies Used
**Frontend**
- HTML5, CSS3, JavaScript
- Nginx (web server)

**Backend**
- Node.js 18
- Express.js
- Mongoose (MongoDB ODM)
- CORS

**Database**
- MongoDB 7.0

**Infrastructure***
- Kubernetes (Minikube for local development)
- Docker & Docker Compose
- mkcert (for local TLS certificates)

### 📦 Prerequisites
- Minikube (v1.30+)
- kubectl (v1.27+)
- Docker (v20.10+)
- Node.js (v18+) - for local testing
- mkcert - for TLS certificates
- Docker Hub account - for hosting images

***Install Prerequisites (Mac)***

**Install Minikube** 
```
brew install minikube
```

**Install kubectl**
```
brew install kubectl
```

**Install mkcert**
```
brew install mkcert
```

**Install mkcert CA**
```
mkcert -install
```

### 🚀 Quick Start
**1. Clone the Repository**
```
git clone https://github.com/your-username/user-management-k8s.git
cd user-management-k8s
```

**2. Build Docker Images**

Build frontend (replace njidekadocker with your own docker username) 
```
cd frontend
docker build -t njidekadocker/userapp.frontend:latest . 
docker push njidekadocker/userapp.frontend:latest
```
Build backend (replace njidekadocker with your own docker username) 
```
cd ../backend
npm install
docker build -t njidekadocker/userapp.backend:latest .
docker push njidekadocker/userapp.backend:latest .
```

**3. Update Kubernetes Manifests** 

(update with your own images from your docker repository)

- Edit k8s/08-backend-deployment.yaml and k8s/10-frontend-deployment.yaml:
- Replace your-dockerhub-username with your Docker Hub username

**4. Start Minikube**
```
minikube start --cpus=4 --memory=4096
minikube addons enable ingress
```

**5. Generate TLS Certificates**

Generate certificates for your domain
```
mkcert jideka.com.ng #replace with your domain name
```
This creates:
- jideka.com.ng.pem (certificate)
- jideka.com.ng-key.pem (private key)

**6. Create TLS Secret**

Base64 encode the certificate and key
```
cat jideka.com.ng.pem | base64 > tls.crt.base64
cat jideka.com.ng-key.pem | base64 > tls.key.base64
```
Update k8s/04-tls-secret.yaml with the values gotten from the cat command above.

Then deploy
```
kubectl apply -f k8s/04-tls-secret.yaml
```

**7. Deploy to Kubernetes**

Deploy all manifests
```
kubectl apply -f k8s/
```
Or use the deployment script
```
chmod +x scripts/deploy.sh
./scripts/deploy.sh
```

**8. Configure DNS**

Get Minikube IP
```
minikube ip
```

Add to /etc/hosts
```
sudo nano /etc/hosts
```

Add this line (replace <MINIKUBE-IP>):
```
<MINIKUBE-IP> jideka.com.ng
```

**9. Access the Application**

Open your browser: https://jideka.com.ng  (replace with your own host name)



### 📚 Detailed Setup

**1. Backend Setup**
```
cd backend
```

Install dependencies
```
npm install
```

Test locally
```
export MONGO_URI=mongodb://localhost:27017/userdb
export API_KEY=my-secret-api-key-12345
node server.js
```

Build Docker image
```
docker build -t your-username/user-app-backend:latest .
```


**2. Frontend Setup**
```
cd frontend
```

No build needed (static HTML)
Just build Docker image
```
docker build -t your-username/user-app-frontend:latest .
```


**3. Local Testing with Docker Compose**

Update frontend/index.html API_URL to:
const API_URL = 'http://localhost:3000/api';

Start all services
```
docker-compose up --build
```

***Access:***

 - Frontend: http://localhost:8080
 - Backend: http://localhost:3000
 - MongoDB: localhost:27017



### ☸️ Kubernetes Components

1. **Namespace (01-namespace.yml)**:
Isolates all resources in the user-app namespace.

2. **ConfigMap (02-configmap.yml)**:
Stores non-sensitive configuration:

   - APP_NAME: Application name
   - MAX_USERS: Maximum allowed users
   - ENVIRONMENT: production/development
   - DEFAULT_ROLE: Default user role

3. **Secret (03-secret.yml)**: 
Stores sensitive data (base64 encoded):

   - DB_PASSWORD: MongoDB password
   - API_KEY: Backend API authentication key
   - MONGO_URI: MongoDB connection string

4. **TLS Secret (04-tls-secret.yml)**:
Stores TLS certificates for HTTPS:

   - tls.crt: SSL certificate
   - tls.key: Private key

5.**PersistentVolumeClaim (05-mongodb-pvc.yml)**:
 Requests 1Gi storage for MongoDB data persistence.
   
6-7. **MongoDB (06-mongodb-deployment.yml, 07-mongodb-service.yml)**: 
   
   - Deployment: Runs MongoDB container
   - Service: Exposes MongoDB on port 27017 internally

8-9. **Backend (08-backend-deployment.yml, 09-backend-service.yml)**
    
  - Deployment: Runs 2 replicas of Node.js API
  - Service: Exposes backend on port 3000 internally

10-11. **Frontend (10-frontend-deployment.yml, 11-frontend-service.yml)**
 
  - Deployment: Runs 2 replicas of Nginx with HTML
  - Service: Exposes frontend on port 80 internally

12. **Ingress (12-ingress.yml)**:
    Routes external HTTPS traffic:
    - https://jideka.com.ng/api/* → Backend Service
    - https://jideka.com.ng/* → Frontend Service
    - TLS termination using mkcert certificates



### 🔒 TLS/HTTPS Setup
Why mkcert?
mkcert creates locally-trusted development certificates without security warnings. Perfect for local Kubernetes development!

**Step-by-Step TLS Setup**

**1. Install mkcert**

***Mac***
```
brew install mkcert
mkcert -install
```

***Linux***
```
sudo apt install libnss3-tools

curl -s https://api.github.com/repos/FiloSottile/mkcert/releases/latest \
  | grep browser_download_url \
  | grep linux-amd64 \
  | cut -d '"' -f 4 \
  | wget -qi -

chmod +x mkcert-v*-linux-amd64
sudo mv mkcert-v*-linux-amd64 /usr/local/bin/mkcert
mkcert -install
```

**2. Generate Certificates**

Generate cert for your domain
```
mkcert jideka.com.ng #(replace jideka.com.ng with your own domain name)
```

***Output:***

Created a new certificate valid for the following names:
- "jideka.com.ng"
The certificate is at "./jideka.com.ng.pem"
The key is at "./jideka.com.ng-key.pem"


**3. Create Base64 Encoded Values**

- Encode certificate (keep as single line)
```
cat jideka.com.ng.pem | base64 | tr -d '\n' > tls.crt.base64
```

- Encode key (keep as single line)
```
cat jideka.com.ng-key.pem | base64 | tr -d '\n' > tls.key.base64
```

**4. Create TLS Secret YAML**

k8s/04-tls-secret.yaml


**5. Update Ingress with TLS**

k8s/12-ingress.yaml


**6. Deploy and Verify**

- Deploy TLS secret
```
kubectl apply -f k8s/04-tls-secret.yaml
```

- Verify secret
```
kubectl get secret user-app-tls-secret -n user-app
kubectl describe secret user-app-tls-secret -n user-app
```

- Deploy ingress
```
kubectl apply -f k8s/12-ingress.yaml
```

- Check ingress
```
kubectl describe ingress user-app-ingress -n user-app
```

- Should show:
TLS:
user-app-tls-secret terminates jideka.com.ng


**7. Test HTTPS**

Test certificate
```
curl -v https://jideka.com.ng
```

- Should show:
SSL connection using TLSv1.3
Server certificate:
subject: O=mkcert development certificate
issuer: O=mkcert development CA


**8. API Endpoints**

- Get configuration
```
curl https://jideka.com.ng/api/config
```

- Get all users
```
curl https://jideka.com.ng/api/users
```

- Create user
```
curl -X POST https://jideka.com.ng/api/users \
  -H "Content-Type: application/json" \
  -H "X-API-Key: my-secret-api-key-12345" \
  -d '{"name":"Test User","email":"test@example.com","role":"admin"}'
```

- Get statistics
```
curl https://jideka.com.ng/api/stats
```


**9. Kubernetes Checks**

- Check all resources
```
kubectl get all -n user-app
```


- Check pods
```
kubectl get pods -n user-app
```


- Check logs
```
kubectl logs -n user-app -l app=backend --tail=50
```


- Check ConfigMap
```
kubectl describe configmap user-app-config -n user-app
```


- Check Secret
```
kubectl get secret user-app-secret -n user-app -o yaml
```


- Check TLS Secret

```
kubectl describe secret user-app-tls-secret -n user-app
```


### 🐛 Troubleshooting

**📖 Learning Resources**
 [for details see](docs/TROUBLESHOOTING.md) 



**📊 Monitoring**
[for details see](docs/MONITOING.md)


**🔄 Updating the Application**
[see for details](docs/UPDATING.md)



### 🧹 Cleanup

**Delete all resources**
```
kubectl delete namespace user-app
```

***Or use cleanup script***
```
chmod +x scripts/cleanup.sh
./scripts/cleanup.sh
```

***Stop Minikube***
```
minikube stop
```

***Delete Minikube cluster**
```
minikube delete
```


### 📖 Learning Resources
- Kubernetes Documentation: https://kubernetes.io/docs/home/ 
- Docker Documentation: https://docs.docker.com/
- mkcert GitHub: https://github.com/FiloSottile/mkcert
- Nginx Ingress Controller: https://docs.nginx.com/nginx-ingress-controller/ 


### 🤝 Contributing
Contributions are welcome! Please feel free to submit a Pull Request.

- Fork the repository
- Create your feature branch (git checkout -b feature/AmazingFeature)
- Commit your changes (git commit -m 'Add some AmazingFeature')
- Push to the branch (git push origin feature/AmazingFeature)
- Open a Pull Request


### 👤 Author
**JANE NJIDEKA OBIKWELU** 

- GitHub:[@Dekasrepo] https://github.com/Dekasrepo
- LinkedIn: https://www.linkedin.com/in/jane-obikwelu
- Medium: [@janeobikwelu ](https://medium.com/@janeobikwelu)

### 🙏 Acknowledgments
- Thanks to the Kubernetes community
- mkcert for making local TLS easy
- All contributors who helped improve this project

⭐ If you found this helpful, please give it a star!
