# Kubernetes ReplicaSet 
* A ReplicaSet ensures that a specified number of identical Pods are running at all times.

* If a Pod crashes or is deleted → ReplicaSet creates a new one automatically
*  If extra Pods exist → it terminates them

### Why ReplicaSet
* Maintains high availability  
* Ensures desired state = actual state  
* Provides self-healing capability  
* Used by Deployments internally (you rarely use it directly in real projects)  


### Example YAML
```
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: nginx-replicaset
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx
```
### How it Works
i. You create ReplicaSet with replicas: 3  
ii. Kubernetes creates 3 Pods  
iii. If 1 Pod dies → ReplicaSet creates new one  
iv. If you manually create extra Pod with same label → ReplicaSet deletes it  

### Commands
* Create ReplicaSet - ```kubectl apply -f replicaset.yaml```
* Check ReplicaSet - ```kubectl get rs```
* Check Pods - ```kubectl get pods```
* Describe ReplicaSet - ```kubectl describe rs nginx-replicaset```
* Delete ReplicaSet - ```kubectl delete rs nginx-replicaset```
* Scaling ReplicaSet - ```kubectl scale rs nginx-replicaset --replicas=5```

### Important Points 🔥

✔ ReplicaSet replaces ReplicationController (older version)  
✔ Supports set-based selectors (more flexible)  
✔ Does NOT support rolling updates (Deployment does)  
✔ Works at Pod level, not application level  
✔ Rarely used directly in production  
