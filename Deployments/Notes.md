# Kubernetes Deployment
A Deployment in Kubernetes is a higher-level object used to manage Pods and ReplicaSets.

* **It ensures:**

  i. Desired number of Pods are running  
ii. Updates are rolled out safely  
iii. Rollbacks are possible  

* **With Deployment:**

  Self-healing ✔️  
Rolling updates ✔️  
Rollback support ✔️  
Scaling ✔️  

* **Architecture:**  
 Deployment  
   ↓  
ReplicaSet  
   ↓  
Pods

* **Deployment manages ReplicaSet
👉 ReplicaSet manages Pods**
---
### Basic YAML Structure
```
apiVersion: apps/v1
kind: Deployment

metadata:
  name: my-app

spec:
  replicas: 3

  selector:
    matchLabels:
      app: my-app

  template:
    metadata:
      labels:
        app: my-app

    spec:
      containers:
      - name: my-container
        image: nginx:latest
        ports:
        - containerPort: 80
```
* **Key Fields Explained**  
🔹 **replicas**  
     i.  Number of Pods to run  
Example:  
replicas: 3  

   🔹 **selector**  
     i. Matches Pods using labels  
    ii.  Must match template labels    

    🔹  **template**  
     i. Defines Pod configuration  
    ii. Contains:  
       metadata (labels)  
       spec (containers)  

  🔹 **containers**  
i. Defines container image, ports, env, etc.  
---

###  Deployment Strategies
**1. Rolling Update (Default):**  
    👉 Updates Pods gradually  
    👉 No downtime  
```
strategy:  
  type: RollingUpdate
```
**2. Recreate**  
  👉 Deletes all Pods first, then creates new ones  
👉 Causes downtime ❌
```
strategy:
  type: Recreate
```
---
### Rolling Update Config 

```
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxUnavailable: 1
    maxSurge: 1
```
👉maxUnavailable → Pods that can be down   
👉  maxSurge → Extra Pods during update  


---
### Scaling Deployment
**1. Manual Scaling:**   ```kubectl scale deployment my-app --replicas=5```  

**2. Auto Scaling**  
Based on CPU/Memory :  ```kubectl autoscale deployment my-app --cpu-percent=50 --min=2 --max=10```

---
### Rolling Update Commands
1. ```kubectl apply -f deployment.yaml```

2. Update image:
```kubectl set image deployment/my-app my-container=nginx:1.25```  

---
### Rollback

1. Check history: ```kubectl rollout history deployment my-app```

2. Undo: ```kubectl rollout undo deployment my-app```

---
### Useful Commands
```kubectl get deployments ```  
```kubectl describe deployment my-app  ```   
```kubectl get rs  ```   
```kubectl get pods  ```  
