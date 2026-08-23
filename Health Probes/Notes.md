# Health Probes

Health Probes are Kubernetes mechanisms used to check the health and availability of containers.

Kubernetes mainly provides **3 types of probes**:

1. **Liveness Probe**
2. **Readiness Probe**
3. **Startup Probe**


## Why Do We Need Health Probes?

Kubernetes needs to know:

* Is the application running?
* Is the application ready to receive traffic?
* Has the application successfully started?
* Should the container be restarted?
* Should traffic be sent to the Pod?

Without probes, Kubernetes may consider a container healthy even when the application inside it is not functioning correctly.

---

# 1. Liveness Probe

A **Liveness Probe** checks whether the application inside the container is still running properly.

If the liveness probe fails repeatedly, Kubernetes **restarts the container**.

### Example

```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 8080
  initialDelaySeconds: 10
  periodSeconds: 10
```

### Common Use Case

Suppose an application becomes stuck or deadlocked.

```text
Container Running
       ↓
Application Hung
       ↓
Liveness Probe Fails
       ↓
Kubernetes Restarts Container
```

### Important Point

**Liveness = Should Kubernetes restart the container?**

---

# 2. Readiness Probe

### 

A **Readiness Probe** checks whether the application is ready to receive traffic.

If the readiness probe fails:

* Pod is **not restarted**
* Pod is removed from the Service's traffic endpoints
* Traffic is not sent to that Pod

### Example

```yaml
readinessProbe:
  httpGet:
    path: /ready
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 10
```

### Example Scenario

Suppose an application is running but still connecting to a database.

```
Pod Running
    ↓
Application Starting
    ↓
Database Connection Not Ready
    ↓
Readiness Probe Fails
    ↓
Pod does NOT receive traffic
```

Once the application becomes ready:

```text
Readiness Probe Successful
        ↓
Pod added to Service endpoints
        ↓
Traffic starts
```

### Important Point

**Readiness = Should Kubernetes send traffic to the Pod?**

---

# 3. Startup Probe

A **Startup Probe** is used for applications that take a long time to start.

It allows Kubernetes to wait for the application to start before applying the liveness and readiness checks.

### Example

```yaml
startupProbe:
  httpGet:
    path: /health
    port: 8080
  failureThreshold: 30
  periodSeconds: 10
```

This gives the application up to:

```text
30 × 10 = 300 seconds
```

to successfully start.

### Why Use Startup Probe?

Without a startup probe:

```text
Slow Application
      ↓
Liveness Probe starts too early
      ↓
Probe fails
      ↓
Container restarted
      ↓
Application starts again
      ↓
Probe fails again
      ↓
Restart loop
```

Startup probe prevents this problem.

---

## Difference Between Probes

| Probe     | Purpose    | Container Restarted?    | Traffic         |  
| --------- | -----------| ----------------------- | --------------- |  
| Liveness  | Checks if application is alive | Yes, if repeatedly failed | Not directly  |  
| Readiness | Checks if application can receive traffic | No      | Traffic removed |  
| Startup | Checks if application has started | Yes, if startup ultimately fails | Not directly    |  

---

## Probe Mechanisms

Kubernetes supports different ways to perform health checks.

### HTTP GET

Checks an HTTP endpoint.
```yaml
httpGet:
  path: /health
  port: 8080
```

Useful for web applications and APIs.

### TCP Socket

Checks whether a TCP connection can be established.

```yaml
tcpSocket:
  port: 8080
```

Useful when the application exposes a TCP service.

### Exec

Runs a command inside the container.

```yaml
exec:
  command:
    - cat
    - /tmp/healthy
```

If the command returns exit code `0`, the probe succeeds.

### gRPC

Can be used for applications exposing gRPC health checks.

```yaml
grpc:
  port: 50051
```

---

## Important Probe Parameters

### initialDelaySeconds

How long Kubernetes waits before starting the probe.

```yaml
initialDelaySeconds: 10
```

### periodSeconds

How frequently Kubernetes performs the probe.

```yaml
periodSeconds: 10
```
Means the probe runs approximately every 10 seconds.

### timeoutSeconds

How long Kubernetes waits for a probe response.

```yaml
timeoutSeconds: 5
```

### failureThreshold

Number of consecutive failures required before the probe is considered failed.

```yaml
failureThreshold: 3
```

### successThreshold

Number of consecutive successes required for the probe to be considered successful.

```yaml
successThreshold: 1
```

---

## Complete Example

```yaml
apiVersion: apps/v1
kind: Deployment

metadata:
  name: web-app

spec:
  replicas: 3

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
          image: nginx:latest

          ports:
            - containerPort: 80

          startupProbe:
            httpGet:
              path: /
              port: 80
            failureThreshold: 30
            periodSeconds: 10

          readinessProbe:
            httpGet:
              path: /
              port: 80
            initialDelaySeconds: 5
            periodSeconds: 10

          livenessProbe:
            httpGet:
              path: /
              port: 80
            initialDelaySeconds: 10
            periodSeconds: 10
```


## Probe Failure Behavior

### Liveness Failure

```text
Liveness Probe
      ↓
Failure
      ↓
Container Restart
```

### Readiness Failure

```text
Readiness Probe
      ↓
Failure
      ↓
Pod removed from Service endpoints
      ↓
No new traffic
```

### Startup Failure

```text
Startup Probe
      ↓
Repeated Failure
      ↓
Container Restart
```

---
## Troubleshooting Health Probes

Check Pod status: ```kubectl get pods```

Check detailed Pod events: ```kubectl describe pod <pod-name>```

Check container logs: ```kubectl logs <pod-name>```

Check previous container logs after a restart:```kubectl logs <pod-name> --previous```

Check Pod YAML: ```kubectl get pod <pod-name> -o yaml```

Check Service endpoints: ```kubectl get endpoints```       or: ```kubectl get endpointslices```
