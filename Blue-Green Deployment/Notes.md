# Blue-Green Deployment 

**Blue-Green Deployment** is a deployment strategy where two identical production environments are maintained:

* **Blue Environment** → Currently serving production traffic
* **Green Environment** → New application version being deployed and tested

Traffic is switched from Blue to Green only after the new version is verified successfully.

In Kubernetes, Blue-Green Deployment can be implemented using:

* Deployments
* Services
* Labels
* Selectors
* Ingress
* Load Balancers

The important concept is that the **Service selector controls which version receives traffic**.

### Simple Flow

```
                        Users
                           |
                           v
                    Load Balancer
                           |
                           v
                    Kubernetes Service
                           |
                +----------+----------+
                |                     |
                v                     v
          Blue Deployment       Green Deployment
             v1.0                   v2.0
                |                     |
             Pods x3                Pods x3
```

After testing:

```
Users
  |
  v
Load Balancer
  |
  v
Green v2
(Production)
```

Blue can then be kept temporarily for quick rollback.

---

## Advantages

Blue-Green Deployment helps achieve:


**1. Fast Rollback:** If the new version fails traffic can be switched back quickly.

```
Green → Blue
```
**2. Low Downtime:**
 The new version is already running before traffic is switched.

**3. Safer Releases:**
 The Green environment can be tested before production traffic is moved.

**4. Easy Version Comparison:**
 Blue and Green can run simultaneously.

**5. Simple Traffic Control:**
 Kubernetes Service selectors can control which environment receives traffic.

---

## Blue vs Green

| Environment  | Purpose                    |    
| ------------ | -------------------------- |  
| Blue         | Current production version |  
| Green        | New version                |  
| Blue → Green | Traffic switch             |  
| Green → Blue | Rollback                   |  

Example:

```
Blue  = Application v1.0
Green = Application v2.0
```

Initially:

```
Users
  |
  v
Service
  |
  v
Blue v1.0
```

After successful testing:

```
Users
  |
  v
Service
  |
  v
Green v2.0
```

---

## How Blue-Green Deployment Works

**Step 1 — Deploy Blue:**
 Blue is the current production environment.

```
Blue → v1.0
```
Users are accessing Blue.

**Step 2 — Deploy Green:**
Deploy the new application version separately.

```
Green → v2.0
```

At this point, Green does not receive normal production traffic.


**Step 3 — Test Green:**

Perform:

* Health checks
* Smoke tests
* Functional testing
* API testing
* Performance testing
* Database compatibility testing

Example:

```
kubectl get pods
kubectl get svc
kubectl describe deployment green
```

**Step 4 — Switch Traffic:**

Once Green is verified, change the Service selector so that traffic goes to Green.

```
Before:

Service
   |
   v
Blue v1.0


After:

Service
   |
   v
Green v2.0
```

**Step 5 — Monitor:**

* Application logs
* CPU and memory
* Error rate
* HTTP 4xx/5xx
* Response time
* Application health
* User traffic


**Step 6 — Rollback if Required:**

If Green has problems, switch traffic back to Blue.

```text
Green v2.0
    X
    |
    v
Blue v1.0
```

Rollback is fast because the previous environment is still available.


---

## Blue Deployment

Example:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-blue
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
      version: blue
  template:
    metadata:
      labels:
        app: myapp
        version: blue
    spec:
      containers:
        - name: myapp
          image: myapp:v1
          ports:
            - containerPort: 8080
```

Blue Pods have:

```text
app=myapp
version=blue
```

---

## Green Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-green
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
      version: green
  template:
    metadata:
      labels:
        app: myapp
        version: green
    spec:
      containers:
        - name: myapp
          image: myapp:v2
          ports:
            - containerPort: 8080
```

Green Pods have:

```text
app=myapp
version=green
```

---

## Kubernetes Service

The Service initially points to Blue.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: myapp-service
spec:
  selector:
    app: myapp
    version: blue
  ports:
    - port: 80
      targetPort: 8080
```

Traffic flow:

```text
Users
  |
  v
myapp-service
  |
  v
Blue Pods
```

---

## Switching Traffic to Green

Change: ``` version: blue```

to: ```version: green ```

The Service becomes:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: myapp-service
spec:
  selector:
    app: myapp
    version: green
  ports:
    - port: 80
      targetPort: 8080
```

Now:

```text
Users
  |
  v
myapp-service
  |
  v
Green Pods
```

---

## Commands

Apply Blue: ``` kubectl apply -f blue-deployment.yaml ```

Apply Green:``` kubectl apply -f green-deployment.yaml ```

Check Deployments:```kubectl get deployments ```

Check Pods: ``` kubectl get pods --show-labels ```

Check Service:``` kubectl get svc ```

Check Service details:``` kubectl describe svc myapp-service ```

Switch traffic to Green:``` kubectl patch service myapp-service \
  -p '{"spec":{"selector":{"app":"myapp","version":"green"}}}' ```

Switch traffic back to Blue:``` kubectl patch service myapp-service \
  -p '{"spec":{"selector":{"app":"myapp","version":"blue"}}}' ```

---

## Disadvantages

**1. Higher Infrastructure Cost:**
Two environments may need to run simultaneously.

```text
Blue  → 3 Pods
Green → 3 Pods
```

This increases resource usage.

**2. Database Migration Risk:**
 Application rollback does not automatically mean database rollback.

For example: ``` Green v2 → Database Schema v2 ```

If you switch back to: ``` Blue v1 ```

but the database is incompatible with v1, rollback can fail.

**3. Stateful Applications:** Blue-Green is more complicated when applications maintain local state.

**4. Double Resource Usage:** During deployment, CPU and memory requirements can temporarily increase.

---

## Blue-Green vs Canary vs Rolling Update

| Feature          | Blue-Green         | Canary           | Rolling Update          |  
| -----------------| -------------------| --------------- | ----------------------- |  
| **Environments** | Two environments | Usually one environment | Usually one environment |    
| **Old Version**  | Kept running     | Kept running        | Gradually replaced      |    
| **New Version Traffic** | 0% → 100%   | Small % → 100%     | Gradually increases     |    
| **Traffic Switching**   | Almost instant  | Gradual and controlled  | Gradual  |  
| **Testing** | Before traffic switch | With real production traffic | During rollout  |  
| **Rollback**   | Very fast     | Fast and controlled     | Usually slower       |    
| **Resource Usage**   | High  | Medium / Depends on implementation | Low     |    
| **Risk Isolation**   | High    | Very High     | Moderate     |  
| **Deployment Complexity** | Moderate   | Moderate to High        | Low        |  
| **Downtime**       | Usually zero      | Usually zero      | Usually zero       |  
| **Main Goal**  | Safe and fast version switch | Risk-controlled gradual release  | Gradual replacement   |  
| **Best For**   | Critical releases   | High-risk releases   | Regular releases  |

---
 **Blue-Green Deployment is a release strategy where two production-like environments run simultaneously, and traffic is switched from the old Blue version to the new Green version after successful testing, enabling fast rollback.**
