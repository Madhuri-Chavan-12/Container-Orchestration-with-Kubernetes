# Headless Service

> A Headless Service is a Kubernetes Service that does not have a ClusterIP. We configure it using `clusterIP: None`. Instead of providing a single virtual IP and load balancing traffic, Kubernetes DNS returns the IP addresses of the individual Pods. Headless Services are commonly used with StatefulSets and distributed applications such as databases, Kafka, and Cassandra where applications need to discover and communicate with specific Pods.

---

## Normal Service vs Headless Service

| Feature              | Normal Service         | Headless Service      |  
| -------------------- | ---------------------- | --------------------- |  
| ClusterIP            | Yes                    | No                    |  
| `clusterIP`          | Automatically assigned | `None`                |  
| Load Balancing       | Yes                    | No                    |  
| DNS returns          | Service IP             | Pod IPs               |  
| Direct Pod discovery | No                     | Yes                   |  
| Common use           | Stateless applications | Stateful applications |  

---

## Why Do We Use Headless Service?

Headless Services are mainly used when applications need **direct communication with individual Pods**.

Common use cases:

* StatefulSets
* Databases
* Kafka
* Cassandra
* MongoDB
* Elasticsearch
* Distributed applications
* Service discovery
* Applications where each Pod has its own identity

---

## Headless Service YAML

Example:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: mysql-headless
spec:
  clusterIP: None
  selector:
    app: mysql
  ports:
    - port: 3306
      targetPort: 3306
```

The important configuration is:

```yaml
clusterIP: None
```

This tells Kubernetes to create a Headless Service.

---

## How Headless Service Works

Suppose we have three Pods:

```text
mysql-0 → 10.0.1.10
mysql-1 → 10.0.1.11
mysql-2 → 10.0.1.12
```

Headless Service:

```text
mysql-headless
```

When DNS is queried:

```text
mysql-headless.default.svc.cluster.local
```

DNS can return:

```text
10.0.1.10
10.0.1.11
10.0.1.12
```

So the client can discover the individual Pods.

---

## Headless Service with StatefulSet

Headless Services are commonly used with StatefulSets.

Example:

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mysql
spec:
  serviceName: mysql-headless
  replicas: 3

  selector:
    matchLabels:
      app: mysql

  template:
    metadata:
      labels:
        app: mysql

    spec:
      containers:
        - name: mysql
          image: mysql:8
          ports:
            - containerPort: 3306
```

Headless Service:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: mysql-headless
spec:
  clusterIP: None

  selector:
    app: mysql

  ports:
    - port: 3306
      targetPort: 3306
```
---

## Stable DNS Names with StatefulSet

One major advantage of combining **StatefulSet + Headless Service** is stable Pod DNS.

For:

```text
StatefulSet: mysql
Service: mysql-headless
Namespace: default
```

Pods get predictable DNS names:

```text
mysql-0.mysql-headless.default.svc.cluster.local
mysql-1.mysql-headless.default.svc.cluster.local
mysql-2.mysql-headless.default.svc.cluster.local
```

The format is:

```text
<pod-name>.<service-name>.<namespace>.svc.cluster.local
```

Example:

```text
mysql-0.mysql-headless.default.svc.cluster.local
```

This is extremely useful for distributed systems and databases.

---

## Check Headless Service

List Services: ```kubectl get svc```

Example:
```
NAME             TYPE        CLUSTER-IP   PORT(S)
mysql-headless   ClusterIP   None         3306/TCP
```
Notice:
```
CLUSTER-IP = None
```
That means it is a Headless Service.

---
## Check Service Details
```
kubectl describe svc mysql-headless
```

Check the endpoints:
```
kubectl get endpoints mysql-headless
```

You can also use:
```
kubectl get endpointslices
```
---
## Test DNS Resolution

Run a temporary Pod:
```
kubectl run dns-test \
  --image=busybox:1.36 \
  -it \
  --rm \
  -- sh
```

Inside the Pod:
```
nslookup mysql-headless
```
You should get the IP addresses of the backend Pods instead of a single ClusterIP.

---

## Headless Service Does Not Mean No Service Discovery

A common misconception is:

> "Headless means Kubernetes Service is not used."

That is incorrect.

The Service still provides:

* DNS-based service discovery
* Pod selection using labels
* Stable DNS integration
* Endpoint management

The main difference is that Kubernetes does not assign a virtual ClusterIP.

---

## Advantages

**1. Direct Pod Discovery:**  Clients can discover individual Pod IPs.

**2. Stateful Applications:** Very useful for databases and distributed systems.

**3. Stable DNS:** StatefulSet Pods can have predictable DNS names.

**4. No Virtual IP:** Traffic does not go through a Service ClusterIP.

**5. Service Discovery:** Applications can discover backend instances through DNS.

---

## Disadvantages

**1. No Built-in Load Balancing:** Kubernetes does not load balance traffic through a ClusterIP.

**2. Client Responsibility:** The application may need to decide which Pod to communicate with.

**3. Pod IPs Can Change:** Although StatefulSet Pod names are stable, Pod IPs can change after recreation.

Therefore, applications should use DNS names instead of hardcoding Pod IPs.

---

## Headless Service Architecture

```
Client
   |
   v
DNS Query
   |
   v
Headless Service
   |
   +----> Pod 1 IP
   |
   +----> Pod 2 IP
   |
   +----> Pod 3 IP
```

There is no virtual ClusterIP in between.

---

## Important Commands

**List Services:** ```kubectl get svc```

**Describe Service:** ```kubectl describe svc <service-name>```

**Check Endpoints:** ```kubectl get endpoints <service-name>```

**Check EndpointSlices:** ```kubectl get endpointslices```

**Check Pods:** ```kubectl get pods -o wide```

**Test DNS:** ```nslookup <service-name>```
