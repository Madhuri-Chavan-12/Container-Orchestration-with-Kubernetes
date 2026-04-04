# Kubernetes ResourceQuota

ResourceQuota is used to limit resource consumption within a namespace.

**It ensures:**

* No team/app can overuse cluster resources  
* Fair resource sharing across namespaces
* Prevents accidental resource exhaustion   

**Why ResourceQuota is Important?**    

1. Without it:

   * One namespace can consume all CPU / Memory  
   * Cluster becomes unstable

2. With it:

   * Control usage of:  
  -- Pods  
  -- CPU / Memory  
 -- Storage  
  -- Services, ConfigMaps, Secrets  


**What Can Be Limited?**    
**1. Compute Resources:** CPU (requests.cpu, limits.cpu)  , Memory (requests.memory, limits.memory)   
**2. Object Count:**   Pods, Services,  Secrets,  ConfigMaps, PVCs  
**3. Storage:** Persistent Volume Claims, Storage size  

---
### ResourceQuota YAML Example
```
apiVersion: v1
kind: ResourceQuota
metadata:
  name: dev-quota
  namespace: dev
spec:
  hard:
    pods: "10"
    requests.cpu: "2"
    requests.memory: "4Gi"
    limits.cpu: "4"
    limits.memory: "8Gi"
    persistentvolumeclaims: "5"
    requests.storage: "20Gi"
```
**Explanation**  
| Field	| Meaning  |   
| ------| ---------|   
| pods	| Max 10 pods allowed  |   
| requests.cpu	| Total CPU request ≤ 2 cores |    
| limits.cpu	| Max CPU limit ≤ 4 cores  |   
| requests.memory	| Total memory request ≤ 4GB |    
| limits.memory	| Max memory limit ≤ 8GB  |   
| PVC	| Max 5 storage claims  |   
| storage	| Total storage ≤ 20GB  |   

---
### Example Pod (Required with Quota)  
```
apiVersion: v1
kind: Pod
metadata:
  name: nginx
  namespace: dev
spec:
  containers:
  - name: nginx
    image: nginx
    resources:
      requests:
        cpu: "200m"
        memory: "200Mi"
      limits:
        cpu: "500m"
        memory: "500Mi"
```

---
### Commands:

1. Create ResourceQuota: ```kubectl apply -f quota.yaml```
2. View quotas: ```kubectl get resourcequota -n dev```
3. Describe quota (IMPORTANT): ```kubectl describe resourcequota dev-quota -n dev```
4. Delete quota:```kubectl delete resourcequota dev-quota -n dev```
5. Check Usage: ```kubectl describe resourcequota -n dev```

---
### Types of ResourceQuota  

**1. Compute Quota:** Limits CPU & Memory

**2. Object Count Quota:** Limits number of objects (pods, services)

**3. Storage Quota:** Limits PVC count & storage size
