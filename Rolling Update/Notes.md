# Kubernetes Rolling Update

A **Rolling Update** is a Kubernetes deployment strategy where the new version of an application is gradually deployed while the old version is gradually removed.

The main goal is to **update an application with minimal or zero downtime**.

### Simple Flow

```text
Old Version
    ↓
Pod v1 + Pod v1 + Pod v1
    ↓
Create New Pod
    ↓
Pod v2 + Pod v1 + Pod v1
    ↓
Terminate Old Pod
    ↓
Pod v2 + Pod v2 + Pod v1
    ↓
Terminate Old Pod
    ↓
Pod v2 + Pod v2 + Pod v2
```
---

## Why Rolling Updates?

Rolling Updates are used because:

* Application can be updated without stopping all Pods.
* Reduces downtime.
* Provides controlled deployment.
* Supports gradual replacement of old Pods.
* If configured correctly, users continue to access the application during deployment.
* Easy to monitor during deployment.

---

## Rolling Update in Kubernetes

Kubernetes `Deployment` uses **RollingUpdate** as the default deployment strategy.

Example:

```yaml
apiVersion: apps/v1
kind: Deployment

metadata:
  name: web-app

spec:
  replicas: 3

  strategy:
    type: RollingUpdate

    rollingUpdate:
      maxUnavailable: 1
      maxSurge: 1

  selector:
    matchLabels:
      app: web-app

  template:
    metadata:
      labels:
        app: web-app

    spec:
      containers:
        - name: web-app
          image: nginx:1.25
          ports:
            - containerPort: 80
```
---

## Important Rolling Update Parameters

**1.maxUnavailable:** `maxUnavailable` defines the maximum number of Pods that can be unavailable during the update.

Example:
```
maxUnavailable: 1
```
For 3 replicas:
```
Desired Pods = 3
Maximum unavailable = 1
```
Kubernetes ensures that at least 2 Pods remain available during the update, subject to the Deployment's availability rules.

**2. maxSurge:** `maxSurge` defines how many additional Pods can be created above the desired replica count during the update.

Example:
```
replicas: 3
maxSurge: 1
```
During the update:
```
Desired = 3
Temporary maximum = 4
```
Kubernetes can temporarily run 4 Pods while replacing the old Pods.

---
## How Rolling Update Works

Suppose the current Deployment has:
```
replicas: 3
image: nginx:1.25
```
Current state:
```
Pod-1 → nginx:1.25
Pod-2 → nginx:1.25
Pod-3 → nginx:1.25
```
Now we update the image:
```
nginx:1.25 → nginx:1.26
```
Kubernetes creates a new ReplicaSet for the new version.
```
Old ReplicaSet
    ↓
nginx:1.25

New ReplicaSet
    ↓
nginx:1.26
```
Then Pods are gradually replaced.

```
Step 1:  v1   v1   v2

Step 2:  v1   v2   v2

Step 3:  v2   v2   v2
```

Finally:
```
100% Pods → v2
```
---

## Deployment and ReplicaSet Relationship

During a Rolling Update, Kubernetes creates a **new ReplicaSet**.

Example:

```text
Deployment
    |
    +---- ReplicaSet-v1
    |        |
    |        +-- Pod v1
    |        +-- Pod v1
    |        +-- Pod v1
    |
    +---- ReplicaSet-v2
             |
             +-- Pod v2
             +-- Pod v2
```

The old ReplicaSet is scaled down gradually while the new ReplicaSet is scaled up.

---

## Perform a Rolling Update

First check the Deployment: ```kubectl get deployment```

Check Pods: ```kubectl get pods```

Update the image: ```kubectl set image deployment/web-app web-app=nginx:1.26```

Check rollout status: ```kubectl rollout status deployment/web-app```

Expected: ```deployment "web-app" successfully rolled out```

---
## Monitor Rolling Update

Watch Pods: ```kubectl get pods -w```

Check Deployment: ```kubectl get deployment web-app```

Check ReplicaSets: ```kubectl get rs```

Check rollout history: ```kubectl rollout history deployment/web-app```

Describe Deployment: ```kubectl describe deployment web-app```

---

## Rollback a Failed Rolling Update

Suppose the new version has a bug.

Check rollout history: ```kubectl rollout history deployment/web-app```

Rollback: ```kubectl rollout undo deployment/web-app```

Check status: ```kubectl rollout status deployment/web-app```

Verify Pods: ```kubectl get pods```

Rollback to a specific revision:```kubectl rollout undo deployment/web-app --to-revision=2 ```

---
## Example of Failed Rolling Update

Suppose:
```
Current Version → v1
New Version     → v2
```

Deployment starts:
```t
v1 → v1 → v1
```
New version:
```
v2 → v1 → v1
```
But `v2` has a bad image or application error.

Pod may go into:
```
ImagePullBackOff
or
CrashLoopBackOff
```

The rollout can stop progressing.

Check:

```bash
kubectl get pods
kubectl describe pod <pod-name>
kubectl logs <pod-name>
kubectl rollout status deployment/web-app
```

If necessary:

```bash
kubectl rollout undo deployment/web-app
```
---

##  Rolling Update with Readiness Probe

A **Readiness Probe** is very important for safe Rolling Updates.

Example:

```yaml
readinessProbe:
  httpGet:
    path: /health
    port: 8080

  initialDelaySeconds: 10
  periodSeconds: 5
```

Kubernetes sends traffic to a Pod only after its readiness check succeeds.

Flow:

```text
Create New Pod
      ↓
Pod Starting
      ↓
Readiness Probe
      ↓
Failure
      ↓
No Traffic
      ↓
Probe Success
      ↓
Pod Ready
      ↓
Traffic Allowed
```

Without a proper readiness probe, Kubernetes may consider a newly started Pod available before the application is actually ready.

---

## Rolling Update with Service

A Service provides a stable endpoint while Pods are being replaced.

```text
                Client
                  |
                  ↓
               Service
                  |
        +---------+---------+
        |         |         |
        ↓         ↓         ↓
      Pod v2    Pod v1    Pod v1
        |
     New Pod
```

As the rollout continues:

```text
v2 + v1 + v1
      ↓
v2 + v2 + v1
      ↓
v2 + v2 + v2
```

The Service continues selecting Pods using labels.

---

## Rolling Update Strategy vs Recreate

## RollingUpdate

```yaml
strategy:
  type: RollingUpdate
```

Old Pods and new Pods temporarily coexist.

```text
v1 + v1 + v2
      ↓
v1 + v2 + v2
      ↓
v2 + v2 + v2
```

Advantages:

* Minimal downtime
* Gradual deployment
* Safer production updates
* Easy rollback

---

## Recreate

```yaml
strategy:
  type: Recreate
```

Kubernetes first terminates old Pods and then creates new Pods.

```text
v1 + v1 + v1
      ↓
No Pods
      ↓
v2 + v2 + v2
```

This can cause downtime.

---

## Rolling Update vs Recreate

| Feature                     | RollingUpdate        | Recreate               |  
| --------------------------- | -------------------- | ---------------------- |  
| Old and new Pods coexist    | Yes                  | No                     |  
| Downtime                    | Usually minimal/none | Usually yes            |  
| Production friendly         | Yes                  | Depends on application |  
| Rollback                    | Easier               | More disruptive        |  
| Default Deployment strategy | Yes                  | No                     |  

---

## Important Commands

List Deployments: ``` kubectl get deployments ```

List Pods: ```kubectl get pods```

Update Image: ```kubectl set image deployment/web-app web-app=nginx:1.26```

Watch Rollout: ```bkubectl rollout status deployment/web-app ```

Rollout History: ```kubectl rollout history deployment/web-app ```

Rollback: ```kubectl rollout undo deployment/web-app```

Pause Rollout: ```kubectl rollout pause deployment/web-app```

Resume Rollout: ```kubectl rollout resume deployment/web-app```

Restart Deployment: ```bkubectl rollout restart deployment/web-app```

---

## Common Reasons Rolling Update Gets Stuck

### 1. ImagePullBackOff
Wrong image name or inaccessible image registry.

```
ImagePullBackOff
```
Check:
```
kubectl describe pod <pod-name>
```

### 2. CrashLoopBackOff

Application starts and repeatedly crashes.

Check:
```
kubectl logs <pod-name>
```

### 3. Readiness Probe Failure

Application is running but health check is failing.

Check:
```
kubectl describe pod <pod-name>
```
Look for:
```
Readiness probe failed
```

### 4. Insufficient Resources

New Pod cannot be scheduled because the cluster does not have enough CPU or memory.

Check:
```
kubectl describe pod <pod-name>
```
Look for:
```
Insufficient cpu
```
or:
```
Insufficient memory
```

### 5. PodDisruptionBudget

A restrictive PodDisruptionBudget can affect how many Pods can be unavailable during certain disruptions.

Check:
```
kubectl get pdb
```

### 6. Application Startup Takes Too Long

The new Pod may require more startup time.

Use an appropriate:
```
startupProbe
```
and:
```
readinessProbe
```

---

## Production Best Practices

### 1. Always Use Readiness Probes

```yaml
readinessProbe:
  httpGet:
    path: /health
    port: 8080
```

### 2. Use Proper Resource Requests and Limits

```yaml
resources:
  requests:
    cpu: "250m"
    memory: "256Mi"

  limits:
    cpu: "500m"
    memory: "512Mi"
```

### 3. Use Multiple Replicas

Instead of:

```yaml
replicas: 1
```

prefer multiple replicas for production workloads where appropriate:

```yaml
replicas: 3
```

### 4. Use Stable Image Tags or Digests

Avoid relying on mutable tags such as:

```text
latest
```

Prefer an immutable version or image digest.

Example:

```text
myapp:1.4.2
```

### 5. Monitor the Rollout

```bash
kubectl rollout status deployment/web-app
```

### 6. Keep Rollback Available

```bash
kubectl rollout undo deployment/web-app
```
