# Canary Deployment

**Canary Deployment** is a deployment strategy where a new application version is released to a **small percentage of users or traffic first**.

The new version is monitored for errors, latency, performance, and other issues. If everything looks good, traffic is gradually increased until the new version receives **100% of the traffic**.

### Basic Flow
```
Users
  |
  v
Service / Ingress
  |
  +--------------------+
  |                    |
  v                    v
Version 1           Version 2
Stable              Canary
90% Traffic         10% Traffic
  |                    |
  +---------+----------+
            |
         Monitor
            |
     +------+------+
     |             |
   Success       Failure
     |             |
 Increase       Rollback
 Traffic
```
---
## Why Use Canary Deployment?

Canary deployment reduces the risk of releasing a new application version.

Instead of:
``` 
Old Version → 100%
New Version → 100%
```
we use:
```
Old Version → 90%
New Version → 10%
```
If the new version has problems, only a small portion of users are affected.

### Benefits

* Reduces deployment risk
* Enables gradual releases
* Detects production issues early
* Allows real-user testing
* Easy rollback
* Helps validate application performance
* Minimizes downtime
---
## Canary Deployment Example

Suppose the current application is:
```
Version: v1
Traffic: 100%
```
We release:
```
Version: v2
```

Initially:
```
v1 → 90%
v2 → 10%
```

After monitoring:
```
v1 → 70%
v2 → 30%
```

Then:
```
v1 → 50%
v2 → 50%
```

Finally:
```
v1 → 0%
v2 → 100%
```
---

## Canary Deployment in Kubernetes

Kubernetes does not provide a built-in traffic-percentage mechanism directly through a normal Deployment.

A common approach is to run **two Deployments**:

* Stable Deployment
* Canary Deployment

Both are exposed through a Service.

### Architecture

```
                 Users
                   |
                   v
              Load Balancer
                   |
                   v
                Service
              /         \
             /           \
            v             v
      Stable Pods      Canary Pods
         v1                v2
```



## Stable Deployment

Example:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-stable
spec:
  replicas: 9
  selector:
    matchLabels:
      app: myapp
      version: stable
  template:
    metadata:
      labels:
        app: myapp
        version: stable
    spec:
      containers:
        - name: myapp
          image: myapp:v1
          ports:
            - containerPort: 80
```

This deployment runs the stable version.

## Canary Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-canary
spec:
  replicas: 1
  selector:
    matchLabels:
      app: myapp
      version: canary
  template:
    metadata:
      labels:
        app: myapp
        version: canary
    spec:
      containers:
        - name: myapp
          image: myapp:v2
          ports:
            - containerPort: 80
```

Initially:
```
Stable Pods = 9
Canary Pods = 1
```

This gives approximately:
```
Stable = 90%
Canary = 10%
```

**Important:** this is only an approximate traffic split. Kubernetes Service load balancing is not a precise percentage-based traffic router.


## Kubernetes Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: myapp-service
spec:
  selector:
    app: myapp
  ports:
    - port: 80
      targetPort: 80
```

The Service selects both:
```
app: myapp
```

Therefore, traffic can reach:
```
Stable Pods
    +
Canary Pods
```
---

## Canary Release Process

**Step 1 — Deploy Stable Version:**

```
v1 → 100%
```

**Step 2 — Deploy Canary:**

Deploy v2 with a small number of replicas.

```
v1 → 90%
v2 → 10%
```

**Step 3 — Monitor:**

Check:

* Error rate
* HTTP 4xx/5xx
* Response time
* CPU
* Memory
* Application logs
* Pod restarts
* Availability
* Business metrics

Useful commands:

```bash
kubectl get pods
kubectl get deployments
kubectl get svc
kubectl logs <pod-name>
kubectl describe pod <pod-name>
kubectl top pods
```

**Step 4 — Increase Canary Traffic:** If v2 is healthy
```
10% → 25% → 50% → 75% → 100%
```

**Step 5 — Complete Deployment:** Once v2 is stable

```text
v1 → 0%
v2 → 100%
```

The old deployment can then be removed.

---

## Rollback

If problems are detected:

```text
v1 → 90%
v2 → 10%
```

Immediately stop or scale down the canary.

```bash
kubectl scale deployment app-canary --replicas=0
```

Traffic returns to the stable version.

```text
v1 → 100%
v2 → 0%
```

This is one of the major advantages of Canary Deployment.

---

## Canary Deployment with Ingress

For more accurate traffic control, an Ingress controller or service-mesh solution can route a specific percentage of traffic to the canary.

Example concept:

```text
                Ingress
                   |
          +--------+--------+
          |                 |
        90%               10%
          |                 |
          v                 v
       Stable            Canary
         v1                 v2
```

This is better than relying only on replica counts when you need exact traffic percentages.

---

## Canary with Header-Based Routing

Canary traffic can also be targeted using headers.

Example:

```text
Normal Users
     |
     v
   v1 Stable
```

Users with:

```text
X-Canary: true
```

can be routed to:

```text
v2 Canary
```

This is useful for:

* Internal testing
* QA testing
* Selected customers
* Developers
* Beta users

---

## Monitoring During Canary

A canary should never be increased blindly.

Monitor:

### Application Metrics

```text
Request Rate
Error Rate
Latency
Throughput
```

### Kubernetes Metrics

```text
CPU Usage
Memory Usage
Pod Restarts
Pod Health
Replica Availability
```

### Example Decision

```text
Canary = 10%

Error Rate:
Stable  = 0.5%
Canary  = 0.6%

Latency:
Stable  = 200ms
Canary  = 210ms

Result:
Healthy
```

Increase traffic.

But:

```text
Canary Error Rate = 8%
```

Result:

```text
STOP RELEASE
       |
       v
Rollback Canary
       |
       v
Stable = 100%
```

---

## Automated Canary Deployment

In production, Canary deployments are often automated using tools such as:

* Argo Rollouts
* Flagger
* Istio
* NGINX Ingress
* Service Mesh solutions

A typical automated flow:

```text
Git Push
   |
   v
CI Pipeline
   |
   v
Build Image
   |
   v
Deploy Canary
   |
   v
10% Traffic
   |
   v
Automated Metrics
   |
   +------ Failure ------> Rollback
   |
   +------ Success ------> Increase Traffic
                              |
                              v
                           25%
                              |
                              v
                           50%
                              |
                              v
                          100%
```
