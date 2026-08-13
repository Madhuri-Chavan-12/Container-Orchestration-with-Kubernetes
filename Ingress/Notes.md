# Kubernetes Ingress


**Ingress** is a Kubernetes API object used to manage external HTTP/HTTPS access to services inside a Kubernetes cluster.

It provides **routing rules** that forward incoming client requests to different Kubernetes Services based on:

* Hostname
* URL path
* TLS/HTTPS configuration

Instead of exposing every application using a separate `LoadBalancer` or `NodePort` Service, Ingress can provide a single entry point for multiple applications.

---

##  Why Do We Use Ingress?

Without Ingress:

```text
Internet
   |
   +---- LoadBalancer ---- Service A ---- Pod A
   |
   +---- LoadBalancer ---- Service B ---- Pod B
   |
   +---- LoadBalancer ---- Service C ---- Pod C
```

This can become expensive and difficult to manage.

With Ingress:

```text
                    Internet
                       |
                Load Balancer
                       |
                Ingress Controller
                  /     |      \
                 /      |       \
              Service A Service B Service C
                 |        |        |
               Pods     Pods      Pods
```

A single external entry point can route traffic to multiple applications.

---

# Ingress Architecture

```text
                  Client / Browser
                         |
                         | HTTP / HTTPS
                         v
                  External Load Balancer
                         |
                         v
                +-------------------+
                | Ingress Controller |
                +-------------------+
                   /      |       \
                  /       |        \
                 v        v         v
             Service-A Service-B Service-C
                 |        |         |
                Pods     Pods      Pods
```

## Components

**Client:** The browser or API client sends an HTTP/HTTPS request.

**Load Balancer:**
 Receives traffic from outside the Kubernetes cluster and forwards it to the Ingress Controller.

**Ingress Controller:**
 The controller watches Ingress resources and implements the routing rules.

Examples:

* NGINX Ingress Controller
* AWS Load Balancer Controller
* Traefik
* HAProxy
* Kong

**Ingress Resource:**
 Defines the routing rules.

**Kubernetes Service:**
Provides stable networking and load balancing to Pods.

---

# Ingress vs Ingress Controller



### Ingress

Ingress is a **Kubernetes API resource** containing routing rules.

Example:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
```

### Ingress Controller

Ingress Controller is the actual software that processes those rules and routes traffic.

Example:

```text
Ingress Resource
       |
       v
Ingress Controller
       |
       v
Kubernetes Services
```

**Important:** Creating an Ingress resource alone does not automatically route traffic. A compatible Ingress Controller must be installed and running.

---

# Basic Ingress YAML

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress

metadata:
  name: my-ingress

spec:
  ingressClassName: nginx

  rules:
    - host: example.com

      http:
        paths:
          - path: /
            pathType: Prefix

            backend:
              service:
                name: web-service
                port:
                  number: 80
```

### Explanation

| Field              | Purpose                          |  
| ------------------ | -------------------------------- |  
| `apiVersion`       | Kubernetes API version           |  
| `kind`             | Defines the resource as Ingress  |    
| `metadata.name`    | Ingress resource name            |    
| `ingressClassName` | Specifies the Ingress Controller |  
| `host`             | Domain name                      |  
| `path`             | URL path                         |  
| `pathType`         | Defines path matching behavior   |  
| `service.name`     | Backend Kubernetes Service       |  
| `service.port`     | Service port                     |  

---

# Host-Based Routing

Host-based routing sends traffic to different Services based on the hostname.

Example:

```text
app.example.com  ---> frontend-service

api.example.com  ---> backend-service

admin.example.com ---> admin-service
```

### YAML

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress

metadata:
  name: host-based-ingress

spec:
  ingressClassName: nginx

  rules:

    - host: app.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: frontend-service
                port:
                  number: 80

    - host: api.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: backend-service
                port:
                  number: 80
```

---

# Path-Based Routing

Path-based routing uses the URL path to determine the backend Service.

Example:

```text
example.com/
        |
        ---> frontend-service

example.com/api
        |
        ---> backend-service

example.com/admin
        |
        ---> admin-service
```

### YAML

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress

metadata:
  name: path-based-ingress

spec:
  ingressClassName: nginx

  rules:
    - host: example.com

      http:
        paths:

          - path: /
            pathType: Prefix
            backend:
              service:
                name: frontend-service
                port:
                  number: 80

          - path: /api
            pathType: Prefix
            backend:
              service:
                name: backend-service
                port:
                  number: 80

          - path: /admin
            pathType: Prefix
            backend:
              service:
                name: admin-service
                port:
                  number: 80
```

---

# Path Types



### Prefix

Matches based on URL path prefix.

```yaml
path: /api
pathType: Prefix
```

Can match:

```text
/api
/api/users
/api/products
```

### Exact

Matches the exact path.

```yaml
path: /login
pathType: Exact
```

Matches:

```text
/login
```

But does not match:

```text
/login/user
```

### ImplementationSpecific

The matching behavior depends on the Ingress Controller.

```yaml
pathType: ImplementationSpecific
```

For portable Kubernetes configurations, `Prefix` and `Exact` are generally preferable.

---

# TLS / HTTPS with Ingress

Ingress can terminate HTTPS traffic.

Traffic flow:

```text
Client
  |
  | HTTPS
  v
Ingress Controller
  |
  | HTTP
  v
Service
  |
  v
Pod
```

The TLS certificate is commonly configured through a Kubernetes Secret.

### TLS Secret

```yaml
apiVersion: v1
kind: Secret

metadata:
  name: tls-secret

type: kubernetes.io/tls

data:
  tls.crt: <base64-certificate>
  tls.key: <base64-private-key>
```

### Ingress TLS Configuration

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress

metadata:
  name: secure-ingress

spec:
  ingressClassName: nginx

  tls:
    - hosts:
        - example.com
      secretName: tls-secret

  rules:
    - host: example.com

      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: web-service
                port:
                  number: 80
```

---

# Ingress Request Flow

Example request:

```text
https://example.com/api/users
```

Request flow:

```text
Browser
   |
   | HTTPS
   v
Load Balancer
   |
   v
Ingress Controller
   |
   | Host = example.com
   | Path = /api
   v
backend-service
   |
   v
Pod
   |
   v
Application
```

### Step-by-step

1. Client sends an HTTPS request.
2. External Load Balancer receives the request.
3. Traffic reaches the Ingress Controller.
4. Controller checks the Ingress rules.
5. Host and path are matched.
6. Request is forwarded to the appropriate Service.
7. Service selects a healthy Pod.
8. Application processes the request.
9. Response returns to the client.

---

# IngressClass

`IngressClass` identifies which Ingress Controller should handle an Ingress resource.

Example:

```yaml
spec:
  ingressClassName: nginx
```

Check available IngressClasses:

```bash
kubectl get ingressclass
```

Example output:

```text
NAME    CONTROLLER
nginx   k8s.io/ingress-nginx
```

---

# Common Ingress Troubleshooting

### Problem 1: Ingress has no ADDRESS

Check: ``` kubectl get ingress ```

If ADDRESS is empty: ```kubectl describe ingress <ingress-name>```

Then check the Ingress Controller:```kubectl get pods -n ingress-nginx ```

Check controller logs:```kubectl logs -n ingress-nginx <controller-pod>```

### Problem 2: 404 Not Found

Possible causes:

* Incorrect host
* Incorrect path
* Wrong `pathType`
* Wrong IngressClass
* Backend Service mismatch
* Application itself returns 404

Check: ```kubectl describe ingress <ingress-name> ```

Verify the Service:```kubectl get svc ```

Verify Pods:```kubectl get pods ```

### Problem 3: 502 Bad Gateway

Possible causes:

* Service has no healthy endpoints
* Wrong Service port
* Pod application is not listening on expected port
* Backend connection failure

Check: ```kubectl get endpoints <service-name> ```

Then:```kubectl describe svc <service-name>```

Check Pod:```kubectl get pods ```

Check application logs:```kubectl logs <pod-name> ```



## Problem 4: Ingress works but application is unreachable

Check the complete chain:

```
Ingress
   |
   v
Service
   |
   v
Endpoints
   |
   v
Pod
   |
   v
Application
```

Commands:

```
kubectl get ingress
kubectl get svc
kubectl get endpoints
kubectl get pods
kubectl logs <pod-name>
```

Also verify the Service selector:``` kubectl describe svc <service-name> ```

---

# Ingress vs Service

| Feature            | Service                 | Ingress                    |  
| ------------------ | ----------------------- | -------------------------- |  
| Purpose            | Exposes Pods            | Routes HTTP/HTTPS traffic  |  
| Layer              | Networking service      | HTTP/HTTPS routing         |  
| Host-based routing | No                      | Yes                        |  
| Path-based routing | No                      | Yes                        |  
| TLS termination    | Not normally            | Yes                        |  
| Load balancing     | Yes, to Pods            | Routes to Services         |  
| External access    | NodePort / LoadBalancer | Through Ingress Controller |  

---

# Ingress vs LoadBalancer

### LoadBalancer Service

```text
Internet
   |
Load Balancer
   |
Service
   |
Pods
```

Usually each externally exposed application can require its own Load Balancer.

### Ingress

```text
Internet
   |
Load Balancer
   |
Ingress Controller
   |
+---------+---------+
|         |         |
Service A Service B Service C
```

Ingress is useful when multiple HTTP/HTTPS applications need to share an external entry point.

---

# Ingress Security Best Practices

* Use HTTPS/TLS in production.
* Store TLS certificates in Kubernetes Secrets or use a certificate-management solution.
* Restrict unnecessary external access.
* Use authentication/authorization where required.
* Apply NetworkPolicies where appropriate.
* Keep the Ingress Controller updated.
* Monitor Ingress Controller logs and metrics.
* Configure appropriate request and connection timeouts.
* Protect sensitive endpoints such as `/admin`.
* Avoid exposing internal services unnecessarily.

---

# Production Architecture Example

```
                         Internet
                            |
                            v
                    Route 53 / DNS
                            |
                            v
                    AWS Load Balancer
                            |
                            v
                  Ingress Controller
                            |
              +-------------+-------------+
              |             |             |
              v             v             v
        Frontend Service API Service Admin Service
              |             |             |
              v             v             v
          Frontend Pods  API Pods     Admin Pods
```

Example routing:

```text
app.example.com
        |
        ---> frontend-service

app.example.com/api
        |
        ---> api-service

app.example.com/admin
        |
        ---> admin-service
```

---


### Remember

> **Ingress = Routing Rules**

> **Ingress Controller = Implements the Routing**

> **Service = Provides stable access to Pods**

> **Pod = Runs the Application**

---

# Useful Commands Cheat Sheet

 List Ingress: ``` kubectl get ingress```

Detailed information: ``` kubectl describe ingress <name> ```

List IngressClass: ``` kubectl get ingressclass ```

Check Ingress Controller: ``` kubectl get pods -n ingress-nginx ```

Controller logs: ``` kubectl logs -n ingress-nginx <pod-name> ```

List Services: ```kubectl get svc ```

Check endpoints: ``` kubectl get endpoints ```

Check EndpointSlices: ``` kubectl get endpointslices ```

Check Pods: ``` kubectl get pods ```

Check Pod logs: ``` kubectl logs <pod-name> ```

## Key Takeaway

Kubernetes **Ingress provides a centralized HTTP/HTTPS routing layer** for applications running inside a Kubernetes cluster. It can route traffic using **hostnames and URL paths**, terminate **TLS**, and forward requests to the appropriate Kubernetes Services through an **Ingress Controller**.
