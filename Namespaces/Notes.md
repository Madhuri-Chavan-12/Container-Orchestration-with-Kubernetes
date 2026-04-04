# Kubernetes Namespaces 
A Namespace in Kubernetes is a way to logically divide a cluster into multiple virtual clusters.

**It helps in:**

* Organizing resources   
* Isolating environments (dev, test, prod)  
* Managing access control  
* Avoiding naming conflicts  

**Why Namespaces?**

1. Without namespaces:

* All resources live in default namespace  
* Naming conflicts happen  
* No separation between teams/apps  

2. With namespaces:

* Same resource name can exist in different namespaces  
* Better resource management  

---
 **Create Namespace (YAML)**
```  
apiVersion: v1
kind: Namespace
metadata:
  name: dev-environment
```
**Apply it:**   ```kubectl apply -f namespace.yaml```  

**Create Resource in Specific Namespace**   
```
apiVersion: v1
kind: Pod
metadata:
  name: my-app
  namespace: dev-environment
spec:
  containers:
  - name: nginx-container
    image: nginx
```
---
**Commands for Namespace**  
1. List all namespaces: ```kubectl get namespaces```   
2. Create namespace (CLI): ```kubectl create namespace dev```   
3. Delete namespace:  ```kubectl delete namespace dev```   
4. Get resources in a namespace: ```kubectl get pods -n dev```   
5. Apply resource in namespace:```kubectl apply -f pod.yaml -n dev```   
6. Describe namespace:```kubectl describe namespace dev```  
7. Set Default Namespace (Context): ```kubectl config set-context --current --namespace=dev```  
👉 Now you don’t need -n dev every time
